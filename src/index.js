require('dotenv').config();
const express = require('express');
const axios = require('axios');

const app = express();
const PORT = process.env.PORT || 3000;
const TARGET_SERVICE_URL = process.env.TARGET_SERVICE_URL;

// Middleware to parse JSON bodies
app.use(express.json());

// Logging middleware
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.path}`);
  next();
});

// Main route that accepts metadata and forwards to another service
app.post('/forward', async (req, res) => {
  try {
    const metadata = req.body;
    
    console.log('Received metadata:', metadata);
    
    // Forward the request to the target service
    console.log(`Forwarding request to: ${TARGET_SERVICE_URL}`);
    const response = await axios.post(TARGET_SERVICE_URL, metadata, {
      headers: {
        'Content-Type': 'application/json',
      },
      timeout: 30000, // 30 second timeout
    });
    
    console.log('Received response from target service');
    
    // Return the response from the target service
    res.status(response.status).json(response.data);
    
  } catch (error) {
    console.error('Error forwarding request:', error.message);
    
    if (error.response) {
      // The target service responded with an error
      res.status(error.response.status).json({
        error: 'Target service error',
        message: error.response.data,
      });
    } else if (error.request) {
      // No response received from target service
      res.status(503).json({
        error: 'Service unavailable',
        message: 'No response from target service',
      });
    } else {
      // Other errors
      res.status(500).json({
        error: 'Internal server error',
        message: error.message,
      });
    }
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Start the server
app.listen(PORT, () => {
  console.log(`Middleman service running on port ${PORT}`);
  console.log(`Target service URL: ${TARGET_SERVICE_URL}`);
  console.log(`Ready to forward requests to /forward endpoint`);
});

