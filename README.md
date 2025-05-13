# Medinix
[![Flutter License](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart License](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
![MongoDB](https://img.shields.io/badge/MongoDB-%234ea94b.svg?style=for-the-badge&logo=mongodb&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)
![JavaScript](https://img.shields.io/badge/javascript-%23323330.svg?style=for-the-badge&logo=javascript&logoColor=%23F7DF1E)
![NodeJS](https://img.shields.io/badge/node.js-6DA55F?style=for-the-badge&logo=node.js&logoColor=white)

Medinix is a comprehensive medical application that facilitates seamless communication between patients and doctors through real-time websocket connections. The platform incorporates AI-powered diagnostics to provide preliminary assessments and connect patients with appropriate medical professionals.

## 🚀 Features

- **Real-time Communication**: Direct websocket connection between patients and doctors
- **AI-Powered Diagnostics**: Preliminary assessment of symptoms using advanced AI
- **Multi-platform Support**: Cross-platform functionality (iOS, Android)
- **Appointment Management**: Schedule, view, and cancel appointments
- **Doctor Verification System**: Ensuring only qualified professionals are accessible
- **Symptom Logging**: Patients can log and track their symptoms over time
- **Health History**: Comprehensive health logs for better medical assessment
- **Secure Authentication**: Separate login systems for doctors and patients
- **Profile Management**: Update personal and professional details
- **Serverless Architecture**: AWS-powered backend for maximum scalability

## 📁 Project Structure

```
MEDINEX/
├── .serverless/                 # Serverless deployment configuration
├── .vscode/                     
├── medinex_backend/             
│   ├── .serverless/             
│   ├── db/                      
│   ├── lambdas/                 
│   │   ├── websocket/           
│   │   │   ├── websocket functions
│   │   └──lambda functions
│   ├── node_modules/            
│   ├── .env                     
│   ├── package-lock.json        
│   ├── package.json             
│   └── serverless.yml          
├── medinix_frontend/           
│   ├── .dart_tool/             
│   ├── .idea/                  
│   ├── .vscode/                
│   ├── android/                
│   ├── assets/                 
│   ├── build/                  
│   ├── ios/                    
│   ├── lib/
│   ├── linux/
│   ├── macos/                  
│   ├── test/                   
│   ├── web/                    
│   ├── windows/                
│   ├── .env                    
│   ├── .flutter-plugins        
│   ├── .flutter-plugins-dependencies 
│   ├── .gitignore
│   ├── .metadata 
│   ├── analysis_options.yaml   
│   ├── flutter_01.png          
│   ├── medinix_frontend.iml    
│   ├── pubspec.lock
│   ├── pubspec.yaml
│   └── README.md   
└── .gitignore      
```

## 🛠️ Technologies Used

### Backend
- **AWS Lambda** - Serverless compute service
- **AWS API Gateway** - API management
- **AWS DynamoDB** - NoSQL database
- **Node.js** - JavaScript runtime
- **MongoDB Atlas** - Main database for major operations
- **Serverless Framework** - Deployment and infrastructure management

### Frontend
- **Flutter** - Cross-platform UI framework
- **Dart** - Programming language
- **WebSocket** - Real-time communication protocol

### AI Integration
- Used Gemini for AI capabilities

## 🚀 Getting Started

### Prerequisites
- Node.js 14.x or higher
- Flutter 2.x or higher
- MongoDB Atlas or Compass
- AWS CLI configured with appropriate permissions
- Serverless Framework installed globally

### Backend Setup
1. Navigate to the backend directory:
   ```
   cd medinex_backend
   ```
2. Install dependencies:
   ```
   npm install
   ```
3. Create a `.env` file with your AWS credentials and other environment variables
4. Deploy to AWS:
   ```
   serverless deploy
   ```

### Frontend Setup
1. Navigate to the frontend directory:
   ```
   cd medinix_frontend
   ```
2. Install dependencies:
   ```
   flutter pub get
   ```
3. Create a `.env` file with your backend API endpoints
4. Run the application:
   ```
   flutter run
   ```

## 📱 Supported Platforms
- iOS
- Android

## 🔒 Security Features
- End-to-end encryption for patient-doctor communications
- Secure authentication flows
- HIPAA-compliant data storage
- Doctor verification system
- OTP-based verification

## 🤝 Contributing
Contributions are welcome! Please feel free to submit a Pull Request.


## 📞 Contact

Sanjay Kumar Parida - [kumarparidasanjay23@gmail.com](mailto:kumarparidasanjay23@gmail.com)
Project Link: [https://github.com/SanjayKParida/collaborative-study-platform](https://github.com/SanjayKParida/collaborative-study-platform)

---

**Note**: Medinix is designed with scalability in mind, leveraging serverless architecture to handle varying loads efficiently while maintaining performance and reliability.
