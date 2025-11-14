require('dotenv').config();
const express = require('express');
const axios = require('axios');
const rateLimit = require('express-rate-limit');

const app = express();
const PORT = process.env.PORT || 3000;
const TARGET_SERVICE_URL = process.env.TARGET_SERVICE_URL;

// Trust proxy - needed for rate limiting when behind proxies/load balancers
app.set('trust proxy', 1);

// Middleware to parse JSON bodies with size limit to prevent abuse
// Set to 1MB to match Stripe's practical limits (they don't enforce a strict limit)
app.use(express.json({ limit: '1mb' }));

// Logging middleware
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.path}`);
  next();
});

// Rate limiting - limit requests to prevent abuse
// Stripe allows ~100 requests per second, we'll set 100 requests per minute as a reasonable limit
const limiter = rateLimit({
  windowMs: (parseInt(process.env.RATE_LIMIT_WINDOW_MINUTES) || 1) * 60 * 1000, // Default: 1 minute
  max: parseInt(process.env.RATE_LIMIT) || 100, // Default: 100 requests per minute (Stripe-like)
  message: { error: 'Too many requests, please try again later.' },
  standardHeaders: true, // Return rate limit info in the `RateLimit-*` headers
  legacyHeaders: false, // Disable the `X-RateLimit-*` headers
});

// Apply rate limiting to the forward endpoint
app.use('/forward', limiter);

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

// Error handler for payload too large (must be after routes)
app.use((err, req, res, next) => {
  if (err.type === 'entity.too.large') {
    return res.status(413).json({
      error: 'Payload too large',
      message: 'Request body exceeds the 1MB limit',
    });
  }
  next(err);
});

// Start the server
app.listen(PORT, () => {
  console.log(`Middleman service running on port ${PORT}`);
  console.log(`Target service URL: ${TARGET_SERVICE_URL}`);
  console.log(`Ready to forward requests to /forward endpoint`);
});

