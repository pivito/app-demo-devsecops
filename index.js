const express = require('express');

const app = express();

app.get('/', (req, res) => {
  res.send('Laboratorio DevSecOps v2 - Desplegado con Jenkins y Argo CD - By Miguel Angel');
});

app.get('/health', (req, res) => {
  res.json({ status: 'UP' });
});

if (require.main === module) {
  app.listen(3000, () => {
    console.log('Servidor escuchando en el puerto 3000');
  });
}

module.exports = app;
