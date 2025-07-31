# Medinex Express Backend

This is the Express.js backend for the Medinex application, migrated from AWS Lambda serverless architecture.

## 🚀 Features

- **Express.js Server** with RESTful API endpoints
- **Socket.IO** for real-time WebSocket communication
- **MongoDB** integration for data persistence
- **AWS Services** integration (SNS for OTP, DynamoDB for OTP storage)
- **Gemini AI** integration for health insights
- **Input Validation** using express-validator
- **Security Middleware** (Helmet, CORS, Rate Limiting)

## 📁 Project Structure

```
medinex_backend/
├── server.js                 # Main Express server
├── db/
│   └── db.js                # MongoDB connection
├── routes/                   # API routes
│   ├── auth.js              # Authentication routes
│   ├── patients.js          # Patient management routes
│   ├── doctors.js           # Doctor management routes
│   ├── appointments.js      # Appointment management routes
│   └── health.js            # Health logs routes
├── controllers/              # Business logic
│   ├── authController.js    # Authentication logic
│   ├── patientController.js # Patient operations
│   ├── doctorController.js  # Doctor operations
│   ├── appointmentController.js # Appointment operations
│   └── healthController.js  # Health operations
├── websocket/               # WebSocket handlers
│   └── websocketHandler.js  # Socket.IO event handlers
└── lambdas/                 # Original Lambda functions (for reference)
```

## 🛠️ Setup Instructions

### 1. Install Dependencies

```bash
npm install
```

### 2. Environment Variables

Create a `.env` file in the root directory with the following variables:

```env
# Database Configuration
MONGODB_URL=mongodb://localhost:27017/medenix

# AWS Configuration (for OTP and other AWS services)
AWS_REGION=ap-south-1
AWS_ACCESS_KEY_ID=your_aws_access_key
AWS_SECRET_ACCESS_KEY=your_aws_secret_key

# Gemini AI API Key
GEMINI_API_KEY=your_gemini_api_key

# Server Configuration
PORT=3001
NODE_ENV=development

# Frontend URL (for CORS)
FRONTEND_URL=http://localhost:3000

# JWT Secret (if you want to add JWT authentication later)
JWT_SECRET=your_jwt_secret_key
```

### 3. Run the Server

**Development mode:**

```bash
npm run dev
```

**Production mode:**

```bash
npm start
```

The server will start on `http://localhost:3001` (or the PORT specified in your .env file).

## 📡 API Endpoints

### Authentication

- `POST /api/auth/send-otp` - Send OTP to phone number
- `POST /api/auth/verify-otp` - Verify OTP

### Patients

- `POST /api/patients/register` - Register new patient
- `POST /api/patients/login` - Patient login
- `GET /api/patients/details/:phoneNumber` - Get patient details
- `PUT /api/patients/update` - Update patient details

### Doctors

- `POST /api/doctors/register` - Register new doctor
- `POST /api/doctors/login` - Doctor login
- `POST /api/doctors/set-password` - Set doctor password
- `GET /api/doctors/details/:doctorId` - Get doctor details
- `GET /api/doctors/verified` - Get verified doctors
- `GET /api/doctors/:doctorId/patients` - Get doctor's patients
- `PUT /api/doctors/update` - Update doctor details

### Appointments

- `POST /api/appointments/create` - Create appointment
- `GET /api/appointments/patient/:patientId` - Get patient appointments
- `GET /api/appointments/doctor/:doctorId` - Get doctor appointments
- `PUT /api/appointments/cancel` - Cancel appointment
- `GET /api/appointments/slots/:doctorId/:date` - Get available slots

### Health

- `POST /api/health/log-symptoms` - Log symptoms and get AI insights
- `GET /api/health/logs/:patientId` - Get health logs

## 🔌 WebSocket Events

### Client to Server

- `register` - Register user for real-time communication
- `qr_scan` - Handle QR code scan by doctor
- `connection_response` - Handle patient response to doctor request

### Server to Client

- `registration_response` - Registration confirmation
- `doctor_request` - Doctor request to patient
- `patient_response` - Patient response to doctor
- `qr_scan_response` - QR scan result
- `connection_response_result` - Connection response result

## 🌐 Deployment Options

### 1. Railway

Railway is a great option for Express.js applications:

1. Connect your GitHub repository to Railway
2. Set environment variables in Railway dashboard
3. Deploy automatically on push

### 2. Render

Another excellent free option:

1. Connect your GitHub repository to Render
2. Set environment variables
3. Configure build command: `npm install`
4. Configure start command: `npm start`

### 3. Heroku

Traditional choice for Node.js apps:

1. Install Heroku CLI
2. Create Heroku app: `heroku create your-app-name`
3. Set environment variables: `heroku config:set VARIABLE_NAME=value`
4. Deploy: `git push heroku main`

### 4. DigitalOcean App Platform

Good for production deployments:

1. Connect your GitHub repository
2. Set environment variables
3. Configure build and run commands
4. Deploy

## 🔧 Key Differences from Serverless

1. **Persistent Server**: Instead of stateless functions, we have a persistent Express server
2. **Socket.IO**: Replaces AWS API Gateway WebSockets with Socket.IO
3. **Middleware**: Added validation, security, and error handling middleware
4. **Connection Management**: In-memory and database-based connection tracking
5. **Error Handling**: Centralized error handling with proper HTTP status codes

## 🚀 Next Steps

1. **Add Authentication**: Implement JWT-based authentication
2. **Add Logging**: Implement proper logging with Winston or similar
3. **Add Testing**: Add unit and integration tests
4. **Add Monitoring**: Implement health checks and monitoring
5. **Add Caching**: Implement Redis for caching frequently accessed data

## 📝 Notes

- The original Lambda functions are preserved in the `lambdas/` folder for reference
- All business logic has been converted to Express controllers
- WebSocket functionality has been migrated from AWS API Gateway to Socket.IO
- The API maintains the same response format as the original Lambda functions
