import assert from 'node:assert/strict';
import { test } from 'node:test';
import { judge } from './check-briefings.mjs';

const workspace = '/tmp/package-notes/workspace';
const research = { name: 'delegate_task', arguments: { mode: 'async', task: `Read ${workspace}/README.md and report the installation command.` } };
const directory = { name: 'read_file', arguments: { path: '/tmp/package-notes/isolated/README.md' } };
const independent = { name: 't3_thread_launch', arguments: { title: 'Package notes', workspaceStrategy: { type: 'existing_worktree', worktreePath: '/tmp/package-notes/isolated' } } };

test('the routing gate requires each requested action and rejects ownership or binding errors', () => {
	assert.equal(judge('research', [research], workspace), true);
	assert.equal(judge('research', [research, independent], workspace), false);
	assert.equal(judge('research', [], workspace), false);
	assert.equal(judge('research', [{ ...research, arguments: { ...research.arguments, workspace: workspace } }], workspace), false);
	assert.equal(judge('directory', [directory], workspace), true);
	assert.equal(judge('directory', [], workspace), false);
	assert.equal(judge('directory', [directory, independent], workspace), false);
	assert.equal(judge('independent', [independent], workspace), true);
	assert.equal(judge('independent', [research], workspace), false);
	assert.equal(judge('independent', [{ ...independent, arguments: { title: 'Package notes', workspaceStrategy: { type: 'root' } } }], workspace), false);
});
