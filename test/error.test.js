
const test = require('node:test');
const assert = require('node:assert/strict');
const { spawnSync } = require('node:child_process');

test('La ruta de diagnóstico está deshabilitada por defecto', () => {
  const result = spawnSync(process.execPath, ['-e', `
    delete process.env.ENABLE_TEST_ENDPOINTS;
    const app = require('./index');
    const exists = app.router.stack.some(
      layer => layer.route?.path === '/test-error'
    );
    process.stdout.write(String(exists));
  `], {
    cwd: process.cwd(),
    encoding: 'utf8'
  });

  assert.equal(result.status, 0, result.stderr);
  assert.equal(result.stdout, 'false');
});

test('La ruta de diagnóstico se habilita explícitamente', () => {
  const result = spawnSync(process.execPath, ['-e', `
    const app = require('./index');
    const exists = app.router.stack.some(
      layer => layer.route?.path === '/test-error'
    );
    process.stdout.write(String(exists));
  `], {
    cwd: process.cwd(),
    encoding: 'utf8',
    env: {
      ...process.env,
      ENABLE_TEST_ENDPOINTS: 'true'
    }
  });

  assert.equal(result.status, 0, result.stderr);
  assert.equal(result.stdout, 'true');
});
