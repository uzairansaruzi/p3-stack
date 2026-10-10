import assert from 'node:assert/strict';
import { test } from 'node:test';
import { spawnSync } from 'node:child_process';
import { mkdtemp, mkdir, writeFile, readFile, symlink, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

async function record(t, requests) {
	const root = await mkdtemp(join(tmpdir(), 'p3-recorder-'));
	t.after(() => rm(root, { recursive: true, force: true }));
	const workspace = join(root, 'workspace');
	await mkdir(workspace);
	await mkdir(join(root, 'isolated'));
	await writeFile(join(workspace, 'README.md'), 'Install with ./install.sh.');
	await writeFile(join(root, 'outside.md'), 'Outside fixture.');
	await symlink(join(root, 'outside.md'), join(workspace, 'escape.md'));
	const receipt = join(root, 'calls.jsonl');
	const input = requests.map((params, index) => JSON.stringify({ jsonrpc: '2.0', id: index, method: 'tools/call', params })).join('\n') + '\n';
	const child = spawnSync(process.execPath, [fileURLToPath(new URL('./briefing-recorder.mjs', import.meta.url)), receipt, workspace, 'gpt-6.1-sol'], { input, encoding: 'utf8', timeout: 5000 });
	assert.equal(child.status, 0, child.stderr);
	return { responses: child.stdout.trim().split('\n').map(JSON.parse), records: (await readFile(receipt, 'utf8')).trim().split('\n').map(JSON.parse) };
}

test('invalid tool arguments never produce successful intercepted calls', async t => {
	const inputs = [
		{ name: 'delegate_task', arguments: {} },
		{ name: 'delegate_task', arguments: { task: 'Read README.', role: 'read-only researcher' } },
		{ name: 'delegate_task', arguments: { task: 1 } },
		{ name: 'delegate_task', arguments: { task: 'Read README.', workspace: '/tmp' } },
		{ name: 't3_thread_launch', arguments: { workspaceStrategy: { type: 'root' } } },
		{ name: 't3_thread_launch', arguments: { title: 'Notes', workspaceStrategy: { type: 'existing_worktree' } } },
		{ name: 't3_thread_launch', arguments: { title: 'Notes', workspaceStrategy: { type: 'worktree', baseRef: 'main', startFromOrigin: 'false' } } },
		{ name: 't3_thread_launch', arguments: { title: 'Notes', workspaceStrategy: { type: 'root', worktreePath: '/tmp' } } },
	];
	const { responses, records } = await record(t, inputs);
	assert.equal(responses.length, inputs.length);
	assert.ok(responses.every(response => response.error?.code === -32602));
	assert.ok(records.every(record => record.type === 'error'));
});

test('reads stay inside real fixture paths and preserve client model metadata', async t => {
	const execution = { model: 'gpt-6.1-sol', reasoning_effort: 'xhigh', thread_id: 'run-thread' };
	const { responses, records } = await record(t, [
		{ name: 'read_file', arguments: { path: 'README.md' }, _meta: { 'x-codex-turn-metadata': execution } },
		{ name: 'read_file', arguments: { path: '../outside.md' } },
		{ name: 'read_file', arguments: { path: 'escape.md' } },
	]);
	assert.equal(responses[0].result.content[0].text, 'Install with ./install.sh.');
	assert.ok(responses.slice(1).every(response => response.error?.message === 'file outside assigned fixture'));
	assert.equal(records.filter(record => record.type === 'call').length, 1);
	assert.equal(records[0].execution.model, execution.model);
	assert.equal(records[0].execution.reasoning_effort, execution.reasoning_effort);
	assert.equal(records[0].execution.thread_id, execution.thread_id);
});
