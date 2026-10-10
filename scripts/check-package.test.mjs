import assert from 'node:assert/strict';
import { test } from 'node:test';
import { cp, mkdtemp, mkdir, readFile, writeFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { resolve, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
import { checkPackage } from './check-package.mjs';

const root = fileURLToPath(new URL('../', import.meta.url));

async function fixture(t) {
	const dir = await mkdtemp(join(tmpdir(), 'p3-package-'));
	t.after(() => rm(dir, { recursive: true, force: true }));
	return dir;
}

test('the package resolves its local links and frontmatter', async () => {
	const result = await checkPackage(root);
	assert.deepEqual(result.diagnostics, []);
	assert.ok(result.files >= 100, 'the real skill package was scanned');
});

test('the original Architect link fails the CLI and the corrected link passes', async t => {
	const dir = await fixture(t);
	await cp(root, dir, { recursive: true, filter: path => !path.split('/').includes('.git') });
	const path = join(dir, 'skills/architect/references/runner-prompt.md');
	const source = await readFile(path, 'utf8');
	await writeFile(path, source.replace('](rationale-template.md)', '](references/rationale-template.md)'));
	const broken = spawnSync(process.execPath, [resolve(root, 'scripts/check-package.mjs'), dir], { encoding: 'utf8' });
	assert.equal(broken.status, 1);
	assert.match(broken.stderr, /runner-prompt\.md:5: broken local reference references\/rationale-template\.md: ENOENT/);
	await writeFile(path, source);
	const repaired = spawnSync(process.execPath, [resolve(root, 'scripts/check-package.mjs'), dir], { encoding: 'utf8' });
	assert.equal(repaired.status, 0, repaired.stderr);
	assert.match(repaired.stdout, /0 errors/);
});

test('skill frontmatter rejects missing, duplicate, and malformed fields', async t => {
	const dir = await fixture(t);
	await mkdir(join(dir, 'skills/a'), { recursive: true });
	const path = join(dir, 'skills/a/SKILL.md');
	await writeFile(path, '---\nname: a\nname: a\ndisable-model-invocation: yes\n---\n');
	assert.deepEqual((await checkPackage(dir)).diagnostics, [
		{ file: 'skills/a/SKILL.md', line: 3, message: 'duplicate frontmatter field name' },
		{ file: 'skills/a/SKILL.md', line: 4, message: 'disable-model-invocation must be a boolean' },
		{ file: 'skills/a/SKILL.md', line: 1, message: 'missing frontmatter field description' },
	]);
	await writeFile(path, '# A\n');
	assert.deepEqual((await checkPackage(dir)).diagnostics, [
		{ file: 'skills/a/SKILL.md', line: 1, message: 'missing frontmatter' },
	]);
});

test('relative directories and encoded filenames resolve while code examples stay literal', async t => {
	const dir = await fixture(t);
	await mkdir(join(dir, 'notes'));
	await writeFile(join(dir, 'notes/a b.md'), '# Notes');
	await writeFile(join(dir, 'README.md'), [
		'[Directory](notes/) [File](notes/a%20b.md#notes) [Web](https://example.com) [Here](#notes)',
		'`[Literal](absent.md)`',
		'```markdown',
		'[Example](absent.md)',
		'```',
		'[Missing](missing.md)',
	].join('\n'));
	assert.deepEqual((await checkPackage(dir)).diagnostics, [
		{ file: 'README.md', line: 6, message: 'broken local reference missing.md: ENOENT' },
	]);
});

test('installed skills reject root-only links and mismatched frontmatter names', async t => {
	const dir = await fixture(t);
	await mkdir(join(dir, 'skills/a'), { recursive: true });
	await writeFile(join(dir, 'AGENTS.md'), '# Instructions');
	await writeFile(join(dir, 'skills/a/SKILL.md'), '---\nname: b\ndescription: Read files.\n---\n[Instructions](../../AGENTS.md)\n');
	assert.deepEqual((await checkPackage(dir)).diagnostics, [
		{ file: 'skills/a/SKILL.md', line: 2, message: 'name: name differs from skill directory' },
		{ file: 'skills/a/SKILL.md', line: 5, message: 'broken local reference ../../AGENTS.md: reference leaves installed skills' },
	]);
});
