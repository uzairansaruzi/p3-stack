import { spawn, execFileSync } from 'node:child_process';
import { createWriteStream } from 'node:fs';
import { mkdir, readFile, writeFile, realpath, cp } from 'node:fs/promises';
import { resolve, join } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { createHash } from 'node:crypto';
import { isDeepStrictEqual } from 'node:util';

const root = fileURLToPath(new URL('../', import.meta.url));
const documents = [
	'AGENTS.md', 'README.md', 'skills/p3-mode/SKILL.md', 'skills/p3-help/SKILL.md',
	'skills/swarm/SKILL.md', 'skills/arena/SKILL.md', 'skills/figure-it-out/SKILL.md',
	...['orchestrate', 'multi-phase-plan', 'opening-a-pr', 'autopilot-full', 'autopilot-stack', 'hillclimb', 'visual-parity', 'worktree-cleanup'].map(name => `skills/p3-mode/playbooks/${name}.md`),
];

export function judge(id, calls, workspace) {
	const launches = calls.filter(call => ['t3_thread_launch', 'create_threads'].includes(call.name));
	if (id === 'independent') {
		return launches.length === 1 && launches[0].name === 't3_thread_launch'
			&& launches[0].arguments.workspaceStrategy?.type === 'existing_worktree'
			&& launches[0].arguments.workspaceStrategy.worktreePath === join(workspace, '../isolated')
			&& calls.every(call => call.name !== 'delegate_task');
	}
	if (launches.length) return false;
	if (id === 'directory') return calls.some(call => call.name === 'read_file' && resolve(workspace, call.arguments.path) === resolve(workspace, '../isolated/README.md'));
	return calls.some(call => call.name === 'delegate_task' && call.arguments.mode === 'async'
		&& call.arguments.task.includes(workspace) && call.arguments.task.includes('README.md')
		&& !('workspaceStrategy' in call.arguments) && !('workspace' in call.arguments));
}

async function run(output, model, effort) {
	await mkdir(output);
	output = await realpath(output);
	const sources = await Promise.all(documents.map(async path => ({ path, text: await readFile(join(root, path), 'utf8') })));
	const hashes = Object.fromEntries(sources.map(item => [item.path, createHash('sha256').update(item.text).digest('hex')]));
	const harnessHashes = Object.fromEntries(await Promise.all(['scripts/check-briefings.mjs', 'scripts/briefing-recorder.mjs'].map(async path => [path, createHash('sha256').update(await readFile(join(root, path))).digest('hex')])));
	const version = execFileSync('codex', ['--version'], { encoding: 'utf8' }).trim();
	const basis = execFileSync('git', ['rev-parse', 'HEAD'], { cwd: root, encoding: 'utf8' }).trim();
	const results = [];
	for (const id of ['research', 'directory', 'independent']) {
		const dir = join(output, id);
		const workspace = join(dir, 'workspace');
		const isolated = join(dir, 'isolated');
		await mkdir(workspace, { recursive: true });
		await mkdir(isolated);
		for (const path of ['AGENTS.md', 'README.md', 'agents', 'skills', 'scripts']) await cp(join(root, path), join(workspace, path), { recursive: true });
		await writeFile(join(isolated, 'README.md'), await readFile(join(root, 'README.md'), 'utf8'));
		const roles = `All roles: codex_p3/${model} (${effort})\n`;
		await writeFile(join(workspace, 'p3-models.md'), roles);
		const prompts = {
			research: 'Delegate a read-only researcher to read README.md in the background and return the installation command. Keep this as child work owned by this conversation.',
			directory: `In ${isolated}, read README.md and tell me how to install the package. Use that existing directory.`,
			independent: `Start an independent top-level conversation titled Package notes in the existing worktree ${isolated}. Ask its agent to read README.md and return the installation command.`,
		};
		const system = `Use the repository instructions below. Your current working directory and package root are ${workspace}. Your T3 thread remains bound to that workspace. Read package skills under ${workspace}/skills and model-role configuration at ${workspace}/p3-models.md. These package files are authoritative for this workspace; do not use another installation. The user selects codex_p3/${model} with reasoningEffort ${effort} for all roles, overriding model-family defaults.\n\n` + sources.map(item => `File ${item.path}\n${item.text}`).join('\n\n');
		await writeFile(join(dir, 'prompt.txt'), prompts[id]);
		await writeFile(join(dir, 'instructions.txt'), system);
		const recording = join(dir, 'calls.jsonl');
		await writeFile(recording, '');
		const disabled = ['shell_tool', 'unified_exec', 'apps', 'plugins', 'multi_agent', 'browser_use', 'computer_use', 'view_image', 'sleep_tool', 'skill_search', 'worktrees'];
		const args = ['exec', '--ephemeral', '--ignore-user-config', '--ignore-rules', '--skip-git-repo-check', '--sandbox', 'read-only',
			...disabled.flatMap(name => ['--disable', name]), '-m', model, '-c', `model_reasoning_effort=${JSON.stringify(effort)}`,
			'-c', 'project_doc_max_bytes=0', '-c', `developer_instructions=${JSON.stringify(system)}`,
			'-c', `mcp_servers.t3_code.command=${JSON.stringify(process.execPath)}`,
			'-c', `mcp_servers.t3_code.args=${JSON.stringify([join(root, 'scripts/briefing-recorder.mjs'), recording, workspace, model])}`,
			'--json', '--color', 'never', prompts[id]];
		const env = Object.fromEntries(Object.entries(process.env).filter(([key]) => !key.startsWith('T3_') && !key.startsWith('CLAUDE_CODE') && key !== 'CLAUDECODE'));
		await writeFile(join(dir, 'invocation.json'), JSON.stringify({ command: 'codex', args, cwd: workspace, removedEnvironmentPrefixes: ['T3_', 'CLAUDE_CODE', 'CLAUDECODE'], roles }, null, 2) + '\n');
		const startedAt = new Date().toISOString();
		const started = performance.now();
		const child = spawn('codex', args, { cwd: workspace, env, detached: true, stdio: ['ignore', 'pipe', 'pipe'] });
		const stdout = createWriteStream(join(dir, 'model.jsonl'));
		const stderr = createWriteStream(join(dir, 'stderr.txt'));
		let transcript = '';
		child.stdout.on('data', chunk => { transcript += chunk; stdout.write(chunk); });
		child.stderr.pipe(stderr);
		let timedOut = false;
		let killTimer;
		const deadline = setTimeout(() => {
			timedOut = true;
			process.kill(-child.pid, 'SIGTERM');
			killTimer = setTimeout(() => { if (child.exitCode === null) process.kill(-child.pid, 'SIGKILL'); }, 3000);
		}, 180_000);
		let exitCode;
		try { exitCode = await new Promise((accept, reject) => { child.on('close', accept); child.on('error', reject); }); }
		finally { clearTimeout(deadline); clearTimeout(killTimer); stdout.end(); }
		const wallMs = performance.now() - started;
		const events = transcript.trim().split('\n').filter(Boolean).map(line => JSON.parse(line));
		const threadId = events.find(event => event.type === 'thread.started')?.thread_id;
		const terminal = events.findLast(event => event.type === 'turn.completed' || event.type === 'turn.failed');
		const recorded = (await readFile(recording, 'utf8')).trim().split('\n').filter(Boolean).map(line => JSON.parse(line));
		const calls = recorded.filter(item => item.type === 'call');
		const metadata = calls[0]?.execution ?? null;
		const items = events.filter(event => event.type === 'item.completed').map(event => event.item);
		const toolUses = items.filter(item => item.type === 'mcp_tool_call');
		const catalog = recorded.find(item => item.type === 'catalog');
		const checks = {
			processSucceeded: exitCode === 0 && !timedOut && terminal?.type === 'turn.completed',
			recorderConnected: Boolean(catalog) && recorded.every(item => item.type !== 'error'),
			modelMatched: calls.length > 0 && calls.every(call => call.execution?.model === model && call.execution?.reasoning_effort === effort && call.execution?.thread_id === threadId),
			onlyRecorderCalls: items.every(item => ['agent_message', 'reasoning', 'mcp_tool_call'].includes(item.type)) && toolUses.every(item => item.server === 't3_code' && !item.error),
			interceptionMatched: toolUses.length === calls.length && calls.every((call, i) => toolUses[i].tool === call.name && isDeepStrictEqual(toolUses[i].arguments, call.arguments)),
		};
		const valid = Object.values(checks).every(Boolean);
		const receipt = { id, startedAt, finishedAt: new Date().toISOString(), basis, hashes, harnessHashes, cliVersion: version,
			requestedModel: model, actualModel: metadata?.model ?? null, options: { reasoningEffort: metadata?.reasoning_effort ?? null }, threadId,
			executionMetadata: metadata, cliIsolation: { ephemeral: true, ignoredUserConfig: true, ignoredRules: true, sandbox: 'read-only', disabled }, invocation: 'invocation.json', exitCode, timedOut,
			wallMs, activeAuthorMs: null, providerApiMs: null, usage: terminal?.usage ?? null, costUsd: null,
			recorderTools: catalog?.tools.map(tool => tool.name) ?? [], calls, checks, valid, verdict: !valid ? 'INVALID' : judge(id, calls, workspace) ? 'PASS' : 'FAIL' };
		await writeFile(join(dir, 'receipt.json'), JSON.stringify(receipt, null, 2) + '\n');
		results.push(receipt);
		console.log(`${id}: ${receipt.verdict} (${calls.map(call => call.name).join(', ')})`);
	}
	await writeFile(join(output, 'summary.json'), JSON.stringify(results, null, 2) + '\n');
	process.exitCode = results.every(result => result.verdict === 'PASS') ? 0 : 1;
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
	const [output, model, effort] = process.argv.slice(2);
	if (!output || !model || !['low', 'medium', 'high', 'xhigh', 'max'].includes(effort)) {
		console.error('Usage: node scripts/check-briefings.mjs <new-artifact-directory> <model> <effort>');
		process.exitCode = 1;
	} else await run(resolve(output), model, effort);
}
