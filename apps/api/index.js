const express = require('express');
const client = require('prom-client');

const app = express();
const PORT = process.env.PORT || 3000;

// Set these via env vars at deploy time — this is how canary vs stable
// identify themselves once Argo Rollouts is in the picture
const DEPLOYMENT = process.env.DEPLOYMENT || 'stable';
const VERSION = process.env.VERSION || 'v4.0.0';
const COMMIT = process.env.COMMIT || 'local';

const register = new client.Registry();
client.collectDefaultMetrics({ register });

const httpRequestsTotal = new client.Counter({
  name: 'http_requests_total',
  help: 'Total HTTP requests',
  labelNames: ['method', 'route', 'status_code'],
  registers: [register],
});

// Must be registered BEFORE the routes, or handled routes never reach it
app.use((req, res, next) => {
  res.on('finish', () => {
    httpRequestsTotal.inc({
      method: req.method,
      route: req.route ? req.route.path : 'unmatched',
      status_code: res.statusCode,
    });
  });
  next();
});

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

app.get('/version', (req, res) => {
  res.status(200).json({
    service: 'sentinel-api',
    version: VERSION,
    deployment: DEPLOYMENT,
    commit: COMMIT,
  });
});

app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`sentinel-api listening on port ${PORT}`);
  });
}

module.exports = app;