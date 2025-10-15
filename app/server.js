const express = require('express');
const client = require('prom-client');

const app = express();
const collectDefaultMetrics = client.collectDefaultMetrics;
collectDefaultMetrics();

app.get('/', (req, res) => {
  res.send('Hello DevSecOps!');
});

app.get('/metrics', async (req, res) => {
  res.set('Content-Type', client.register.contentType);
  res.end(await client.register.metrics());
});

const port = process.env.PORT || 3000;
app.listen(port, () => console.log(`app listening on ${port}`));
