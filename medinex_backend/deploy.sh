#!/bin/bash

echo "🚀 Medinex Express Backend Deployment Script"
echo "============================================="

# Check if .env file exists
if [ ! -f .env ]; then
    echo "❌ .env file not found!"
    echo "Please create a .env file with the required environment variables."
    echo "See README.md for the required variables."
    exit 1
fi

# Check if all required environment variables are set
echo "🔍 Checking environment variables..."

required_vars=("MONGODB_URL" "AWS_REGION" "AWS_ACCESS_KEY_ID" "AWS_SECRET_ACCESS_KEY" "GEMINI_API_KEY")

for var in "${required_vars[@]}"; do
    if ! grep -q "^${var}=" .env; then
        echo "❌ Missing required environment variable: ${var}"
        exit 1
    fi
done

echo "✅ All required environment variables are set"

# Install dependencies
echo "📦 Installing dependencies..."
npm install

if [ $? -ne 0 ]; then
    echo "❌ Failed to install dependencies"
    exit 1
fi

echo "✅ Dependencies installed successfully"

# Run tests (if any)
if [ -f "package.json" ] && grep -q "\"test\"" package.json; then
    echo "🧪 Running tests..."
    npm test
    
    if [ $? -ne 0 ]; then
        echo "❌ Tests failed"
        exit 1
    fi
    
    echo "✅ Tests passed"
fi

# Start the server
echo "🚀 Starting the server..."
echo "Server will be available at: http://localhost:${PORT:-3001}"
echo "Health check endpoint: http://localhost:${PORT:-3001}/health"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

npm start 