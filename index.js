const express = require('express');
const { version } = require('./package.json');

const app = express();

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
    environment: process.env.APP_ENV || 'local'
  });
});

if (require.main === module) {
  app.listen(3000, () => {
    console.log('Servidor escuchando en el puerto 3000');
  });
}

module.exports = app;
