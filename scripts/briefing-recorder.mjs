import { createInterface } from 'node:readline';
import { appendFile, readFile, realpath } from 'node:fs/promises';
import { resolve, relative, isAbsolute } from 'node:path';

const [receiptPath, workspace, model] = process.argv.slice(2);
if (!receiptPath || !workspace || !model) throw new Error('receipt path, workspace, and model are required');
const string = { type: 'string' };
const object = properties => ({ type: 'object', properties, additionalProperties: false });
const tools = [
	{ name: 'delegate_task', description: 'Delegate one task to a child agent of this thread with only the supplied brief. Provider/model/options inherit unless target overrides them. Prefer async for background work.', inputSchema: { ...object({ task: string, title: string, role: { enum: ['implementation', 'research', 'review', 'design', 'test', 'general'] }, mode: { enum: ['async', 'wait'] }, clientRequestId: string, target: { type: 'object' } }), required: ['task'] } },
	{ name: 't3_thread_launch', description: 'Create an ordinary TOP-LEVEL conversation with a workspace binding before its agent starts. Use for independent conversations. Use delegate_task for child subagents. Omitted workspaceStrategy selects the project root, not the caller worktree.', inputSchema: { ...object({ title: string, message: string, workspaceStrategy: { oneOf: [
		{ ...object({ type: { const: 'root' }, branch: string }), required: ['type'] },
		{ ...object({ type: { const: 'existing_worktree' }, worktreePath: string, branch: string }), required: ['type', 'worktreePath'] },
		{ ...object({ type: { const: 'worktree' }, baseRef: string, branch: string, startFromOrigin: { type: 'boolean' } }), required: ['type', 'baseRef'] },
	] } }), required: ['title'] } },
	{ name: 'create_threads', description: 'Create ordinary TOP-LEVEL conversations. This is not child delegation.', inputSchema: object({ threads: { type: 'array', items: { type: 'object' } } }) },
	{ name: 'orchestrator_capabilities', description: 'Read current providers and models available for delegation.', inputSchema: object({}) },
	{ name: 't3_thread_configuration', description: 'Read this thread model and modes.', inputSchema: object({}) },
	{ name: 'task_status', description: 'Read a delegated task result.', inputSchema: { ...object({ taskId: string }), required: ['taskId'] } },
	{ name: 'read_file', description: 'Read a file by absolute path or relative to the current working directory.', inputSchema: { ...object({ path: string }), required: ['path'] } },
];
for (const tool of tools) tool.annotations = { readOnlyHint: true, destructiveHint: false, openWorldHint: false };

function validate(schema, value, path = 'arguments') {
	if (schema.oneOf) {
		const matches = schema.oneOf.filter(option => { try { validate(option, value, path); return true; } catch { return false; } });
		if (matches.length !== 1) throw new Error(`${path}: expected exactly one schema variant`);
	}
	if ('const' in schema && value !== schema.const) throw new Error(`${path}: invalid constant`);
	if (schema.enum && !schema.enum.includes(value)) throw new Error(`${path}: invalid enum value`);
	if (schema.type === 'object') {
		if (value === null || typeof value !== 'object' || Array.isArray(value)) throw new Error(`${path}: expected object`);
		for (const key of schema.required ?? []) if (!(key in value)) throw new Error(`${path}.${key}: required`);
		for (const [key, item] of Object.entries(value)) {
			if (schema.properties?.[key]) validate(schema.properties[key], item, `${path}.${key}`);
			else if (schema.additionalProperties === false) throw new Error(`${path}.${key}: unsupported argument`);
		}
	} else if (schema.type === 'array') {
		if (!Array.isArray(value)) throw new Error(`${path}: expected array`);
		value.forEach((item, index) => validate(schema.items, item, `${path}[${index}]`));
	} else if (schema.type && typeof value !== schema.type) throw new Error(`${path}: expected ${schema.type}`);
}

const roots = await Promise.all([workspace, resolve(workspace, '../isolated')].map(path => realpath(path)));
let calls = 0;
const input = createInterface({ input: process.stdin });
for await (const line of input) {
	const request = JSON.parse(line);
	if (request.id === undefined) continue;
	let result;
	try {
		if (request.method === 'initialize') {
			result = { protocolVersion: request.params.protocolVersion, capabilities: { tools: {} }, serverInfo: { name: 'p3-recorder', version: '1.0.0' } };
		} else if (request.method === 'tools/list') {
			result = { tools };
			await appendFile(receiptPath, JSON.stringify({ type: 'catalog', tools }) + '\n');
		} else if (request.method === 'ping') result = {};
		else if (request.method === 'tools/call') {
			const { name, arguments: args = {} } = request.params;
			if (++calls > 12) throw new Error('tool call budget exceeded');
			const tool = tools.find(item => item.name === name);
			if (!tool) throw new Error(`unknown tool ${name}`);
			validate(tool.inputSchema, args);
			const telemetry = request.params._meta?.['x-codex-turn-metadata'];
			const execution = telemetry ? Object.fromEntries(['model', 'reasoning_effort', 'session_id', 'thread_id', 'turn_id', 'codex_version', 'turn_started_at_unix_ms', 'sandbox_mode'].map(key => [key, telemetry[key] ?? null])) : null;
			let value;
			if (name === 'read_file') {
				const path = await realpath(resolve(workspace, args.path));
				if (!roots.some(root => { const child = relative(root, path); return child === '' || (child !== '..' && !child.startsWith('../') && !isAbsolute(child)); })) throw new Error('file outside assigned fixture');
				value = await readFile(path, 'utf8');
			} else if (name === 'orchestrator_capabilities') {
				value = { inheritedProviderInstanceId: 'codex_p3', inheritedModel: model, parentThreadId: 'current', providers: [{ providerInstanceId: 'codex_p3', canRunChildTask: true, models: [{ id: model }] }] };
			} else if (name === 't3_thread_configuration') {
				value = { threadId: 'current', modelSelection: { instanceId: 'codex_p3', model }, runtimeMode: 'full-access', interactionMode: 'default' };
			} else if (name === 't3_thread_launch') {
				value = { threadId: 'independent', status: 'running', modelSelection: { instanceId: 'codex_p3', model } };
			} else if (name === 'create_threads') value = { threads: [{ threadId: 'independent', status: 'running' }] };
			else value = { taskId: 'research', childThreadId: 'research-child', status: 'completed', workState: 'result_available', summary: 'Install with ./install.sh.' };
			result = { content: [{ type: 'text', text: typeof value === 'string' ? value : JSON.stringify(value) }] };
			await appendFile(receiptPath, JSON.stringify({ type: 'call', at: new Date().toISOString(), name, arguments: args, execution, result: value }) + '\n');
		} else {
			await appendFile(receiptPath, JSON.stringify({ type: 'protocol', method: request.method, response: 'method not found' }) + '\n');
			process.stdout.write(JSON.stringify({ jsonrpc: '2.0', id: request.id, error: { code: -32601, message: 'Method not found' } }) + '\n');
			continue;
		}
		process.stdout.write(JSON.stringify({ jsonrpc: '2.0', id: request.id, result }) + '\n');
	} catch (error) {
		await appendFile(receiptPath, JSON.stringify({ type: 'error', at: new Date().toISOString(), request, message: error.message }) + '\n');
		process.stdout.write(JSON.stringify({ jsonrpc: '2.0', id: request.id, error: { code: -32602, message: error.message } }) + '\n');
	}
}
