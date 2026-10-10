import { readdir, readFile, access } from 'node:fs/promises';
import { dirname, resolve, relative, basename } from 'node:path';
import { pathToFileURL } from 'node:url';

async function markdownFiles(dir) {
	const files = [];
	for (const entry of await readdir(dir, { withFileTypes: true })) {
		if (entry.name.startsWith('.') || entry.name === 'node_modules') continue;
		const path = resolve(dir, entry.name);
		if (entry.isDirectory()) files.push(...await markdownFiles(path));
		else if (entry.isFile() && entry.name.endsWith('.md')) files.push(path);
	}
	return files.sort();
}

function scalar(raw) {
	if (raw.startsWith('"')) return JSON.parse(raw);
	if (raw.startsWith("'")) {
		if (!/^'(?:[^']|'')*'$/.test(raw)) throw new Error('invalid quoted string');
		return raw.slice(1, -1).replaceAll("''", "'");
	}
	if (!raw || /^[\[\]{>&*!|]/.test(raw) || /^(true|false|null|\d+)$/i.test(raw)) {
		throw new Error('expected a single-line string');
	}
	return raw;
}

export async function checkPackage(root) {
	const diagnostics = [];
	const files = await markdownFiles(root);
	for (const file of files) {
		const source = (await readFile(file, 'utf8')).replaceAll('\r\n', '\n');
		const lines = source.split('\n');
		const report = (line, message) => diagnostics.push({ file: relative(root, file), line, message });
		let bodyStart = 0;
		if (lines[0] === '---') {
			const end = lines.indexOf('---', 1);
			if (end === -1) { report(1, 'unterminated frontmatter'); continue; }
			bodyStart = end + 1;
			const fields = new Map();
			for (let i = 1; i < end; i++) {
				const match = /^([a-z-]+):\s*(.*)$/.exec(lines[i]);
				if (!match) { report(i + 1, 'expected a flat frontmatter field'); continue; }
				const [, key, raw] = match;
				if (fields.has(key)) report(i + 1, `duplicate frontmatter field ${key}`);
				fields.set(key, raw);
				if (!['name', 'description', 'disable-model-invocation'].includes(key)) {
					report(i + 1, `unsupported frontmatter field ${key}`);
				} else if (key === 'disable-model-invocation') {
					if (!['true', 'false'].includes(raw)) report(i + 1, `${key} must be a boolean`);
				} else {
					try {
						const value = scalar(raw);
						if (typeof value !== 'string' || !value.trim()) throw new Error('expected a nonempty string');
						if (key === 'name') {
							if (!/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(value)) throw new Error('invalid name');
							if (basename(file) === 'SKILL.md' && value !== basename(dirname(file))) throw new Error('name differs from skill directory');
						}
					} catch (error) { report(i + 1, `${key}: ${error.message}`); }
				}
			}
			for (const key of ['name', 'description']) {
				if (!fields.has(key)) report(1, `missing frontmatter field ${key}`);
			}
		} else if (basename(file) === 'SKILL.md') report(1, 'missing frontmatter');

		let fence = null;
		for (let i = bodyStart; i < lines.length; i++) {
			const marker = /^\s*(`{3,}|~{3,})/.exec(lines[i]);
			if (marker) {
				if (!fence) fence = marker[1];
				else if (marker[1][0] === fence[0] && marker[1].length >= fence.length) fence = null;
				continue;
			}
			if (fence) continue;
			const prose = lines[i].replace(/(`+)(.*?)\1/g, '');
			for (const match of prose.matchAll(/!?\[[^\]\n]*\]\((<[^>\n]+>|[^)\n]+)\)/g)) {
				let target = match[1].trim();
				if (target.startsWith('<')) target = target.slice(1, -1);
				else target = target.replace(/\s+["'][^"']*["']$/, '');
				if (/^[a-z][a-z\d+.-]*:/i.test(target) || target.startsWith('#') || target.startsWith('//')) continue;
				try {
					target = decodeURIComponent(target.split('#')[0]);
					if (!target || target.startsWith('/')) throw new Error('use a relative package path');
					const destination = resolve(dirname(file), target);
					const packagePath = relative(resolve(root), destination);
					if (packagePath === '..' || packagePath.startsWith('../')) throw new Error('reference leaves package');
					if (relative(root, file).startsWith('skills/') && !packagePath.startsWith('skills/')) throw new Error('reference leaves installed skills');
					await access(destination);
				} catch (error) {
					report(i + 1, `broken local reference ${target}: ${error.code ?? error.message}`);
				}
			}
		}
	}
	return { files: files.length, diagnostics };
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
	try {
		const result = await checkPackage(resolve(process.argv[2] ?? '.'));
		for (const item of result.diagnostics) console.error(`${item.file}:${item.line}: ${item.message}`);
		console.log(`${result.files} Markdown files checked; ${result.diagnostics.length} errors`);
		process.exitCode = result.diagnostics.length ? 1 : 0;
	} catch (error) {
		console.error(error.message);
		process.exitCode = 1;
	}
}
