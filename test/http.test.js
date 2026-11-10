
const test = require('node:test');
const assert = require('node:assert/strict');
const app = require('../index');

test('GET /version devuelve la versión de la aplicación', async () => {
  const server = app.listen(0);

  try {
    await new Promise(resolve => {
      if (server.listening) resolve();
      else server.once('listening', resolve);
    });

    const port = server.address().port;

    const response = await fetch(
      `http://127.0.0.1:${port}/version`
    );

    assert.equal(response.status, 200);

    const body = await response.json();

    assert.equal(body.application, 'app-demo');
    assert.equal(body.version, '3.0.0');
    assert.equal(body.environment, process.env.APP_ENV || 'local');
  } finally {
    await new Promise((resolve, reject) => {
      server.close(error => error ? reject(error) : resolve());
    });
  }
});
