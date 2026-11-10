
const express = require('express');
const pino = require('pino');
const pinoHttp = require('pino-http');
const { version } = require('./package.json');

const app = express();

const environment = process.env.APP_ENV || 'local';

const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  base: {
    application: 'app-demo',
    environment,
    version
  }
});

// Middleware de logging HTTP
app.use(pinoHttp({
  logger,
  redact: {
    paths: [
      'req.headers.authorization',
      'req.headers.cookie',
      'res.headers["set-cookie"]'
    ],
    censor: '[REDACTED]'
  },
  serializers: {
    req(req) {
      return {
        method: req.method,
        url: req.url
      };
    },
    res(res) {
      return {
        statusCode: res.statusCode
      };
    }
  }
}));

app.get('/', (req, res) => {
  res.send('Laboratorio DevSecOps v3 - Desplegado con Jenkins y Argo CD');
});

app.get('/health', (req, res) => {
  res.json({ status: 'UP' });
});

app.get('/version', (req, res) => {
  res.json({
    application: 'app-demo',
    version,
    environment
  });
});

// Ruta de diagnóstico habilitada explícitamente
if (process.env.ENABLE_TEST_ENDPOINTS === 'true') {
  app.get('/test-error', (req, res) => {
    req.log.error(
      { test: true },
      'Error HTTP 500 generado para validar observabilidad'
    );

    res.status(500).json({
      error: 'Simulated internal server error',
      environment
    });
  });
}

if (require.main === module) {
  app.listen(3000, () => {
    logger.info({ port: 3000 }, 'Servidor iniciado');
  });
}

module.exports = app;
