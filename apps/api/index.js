const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

// Set these via env vars at deploy time — this is how canary vs stable
// identify themselves once Argo Rollouts is in the picture
const DEPLOYMENT = process.env.DEPLOYMENT || 'stable';
const VERSION = process.env.VERSION || 'v1.0.0';
const COMMIT = process.env.COMMIT || 'local';

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

app.get('/version', (req, res) => {
  res.status(200).json({
    service: 'sentinel-api',
    version: VERSION,
    deployment: DEPLOYMENT,
    commit: COMMIT
  });
});

app.listen(PORT, () => {
  console.log(`sentinel-api listening on port ${PORT}`);
});