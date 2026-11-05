const test = require('node:test');
const assert = require('node:assert/strict');
const app = require('../index');

test('La aplicación Express se inicializa', () => {
  assert.equal(typeof app, 'function');
});

test('La ruta /health está registrada', () => {
  const route = app._router?.stack?.some(
    layer => layer.route?.path === '/health'
  ) ?? app.router?.stack?.some(
    layer => layer.route?.path === '/health'
  );

  assert.equal(route, true);
});

test('La ruta /version está registrada', () => {
  const route = app.router.stack.some(
    layer => layer.route?.path === '/version'
  );

  assert.equal(route, true);
});
