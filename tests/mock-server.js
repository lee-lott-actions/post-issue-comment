const express = require('express');
const app = express();
app.use(express.json());

app.post('/repos/:owner/:repo/issues/:issue_number/comments', (req, res) => {
  console.log(`Mock intercepted: POST /repos/${req.params.owner}/${req.params.repo}/issues/${req.params.issue_number}/comments`);
  console.log('Request body:', JSON.stringify(req.body));
  console.log('Request headers:', JSON.stringify(req.headers));

  // Validate the request body
  if (req.body.body && typeof req.body.body === 'string') {
    // Simulate response based on parameters
    if (
      req.params.owner === 'test-owner' &&
      req.params.repo === 'test-repo' &&
      req.params.issue_number === '1'
    ) {
      res.status(201).json({ id: 123, body: req.body.body });
    } else {
      res.status(404).json({ message: 'Issue not found' });
    }
  } else {
    res.status(400).json({ message: 'Invalid request: body must be a non-empty string' });
  }
});

app.listen(3000, () => {
  console.log('Mock server listening on http://127.0.0.1:3000...');
});
