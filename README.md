# Hubby Payment App Middleman

A simple Node.js + Express middleman service that accepts metadata and forwards requests to another service.

## Features

- Single endpoint that accepts metadata via POST request
- Forwards requests to a configurable target service
- Waits for and returns the response from the target service
- Error handling for various failure scenarios
- Health check endpoint
- Rate limiting (100 requests per minute by default, Stripe-like)
- Request size limit (1MB by default, following industry standards)

## Installation

```bash
npm install
```

## Configuration

Create a `.env` file in the root directory:

```
PORT=3000
TARGET_SERVICE_URL=http://localhost:4000
RATE_LIMIT_WINDOW_MINUTES=1
RATE_LIMIT=100
```

- `PORT`: The port this middleman service runs on (default: 3000)
- `TARGET_SERVICE_URL`: The URL of the target service to forward requests to
- `RATE_LIMIT_WINDOW_MINUTES`: Time window for rate limiting in minutes (default: 1)
- `RATE_LIMIT`: Maximum requests allowed per time window (default: 100)

## Usage

### Start the server

```bash
npm start
```

### Development mode (with auto-reload)

```bash
npm run dev
```

### Run tests

```bash
./run-tests.sh
```

## API Endpoints

### POST /forward

Accepts metadata and forwards it to the target service.

**Request:**
```bash
curl -X POST http://localhost:3000/forward \
  -H "Content-Type: application/json" \
  -d '{"key": "value", "metadata": "your data here"}'
```

**Response:**
Returns whatever the target service responds with.

### GET /health

Health check endpoint.

**Request:**
```bash
curl http://localhost:3000/health
```

**Response:**
```json
{
  "status": "ok",
  "timestamp": "2025-11-13T..."
}
```

## Error Handling

The service handles three types of errors:

1. **Target service error** (4xx/5xx from target): Returns the error response from the target service
2. **Service unavailable** (no response): Returns 503 when target service is unreachable
3. **Internal error**: Returns 500 for other unexpected errors

## Project Structure

```
hubby-payment-app-middleman/
├── src/
│   └── index.js          # Main Express application
├── .env                  # Environment configuration (create this)
├── .gitignore           # Git ignore rules
├── package.json         # Project dependencies
└── README.md            # This file
```