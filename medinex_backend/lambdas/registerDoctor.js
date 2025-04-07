import { getMongoClient } from "../db/db.js";
import bcrypt from "bcryptjs"; 

let mongoClient;

// Function to generate a random doctor login ID
const generateDoctorLoginId = async (mongoClient) => {
  let isUnique = false;
  let loginId;
  
  while (!isUnique) {
    // Generate random 4 digit number
    const randomNum = Math.floor(1000 + Math.random() * 9000);
    loginId = `DOC1${randomNum}`;
    
    // Check if this ID already exists in the database
    const existingDoctor = await mongoClient
      .db("medenix")
      .collection("doctors")
      .findOne({ doctorLoginId: loginId });
    
    // If no doctor found with this ID, it's unique
    if (!existingDoctor) {
      isUnique = true;
    }
  }
  
  return loginId;
};

export const registerDoctor = async (event, context) => {
  context.callbackWaitsForEmptyEventLoop = false;

  try {
    console.log("Event received ::: ", event);
    mongoClient = await getMongoClient();
    const requestBody = event;

    const {
      name,
      dob,
      gender,
      mobileNumber,
      email,
      clinicName,
      workAddress,
      medicalRegistrationNumber,
      specialization,
      yearsOfExperience,
      degreeInstitution,
      governmentID,
      password,
    } = requestBody;

    // Validate password
    if (!password) {
      throw new Error("Password is required");
    }

    // Generate a unique doctor login ID
    const loginID = await generateDoctorLoginId(mongoClient);

    // Hash password before storing it
    const hashedPassword = await bcrypt.hash(password, 10);

    const doctorData = {
      ...(name && { name }),
      ...(dob && { dob }),
      ...(gender && { gender }),
      ...(mobileNumber && { mobileNumber }),
      ...(email && { email }),
      ...(clinicName && { clinicName }),
      ...(workAddress && { workAddress }),
      ...(medicalRegistrationNumber && { medicalRegistrationNumber }),
      ...(specialization && { specialization }),
      ...(yearsOfExperience && { yearsOfExperience }),
      ...(degreeInstitution && { degreeInstitution }),
      ...(governmentID && { governmentID }),
      password: hashedPassword, // Store hashed password
      isApproved: false, // Default to false (waiting for admin approval)
      doctorLoginId : loginID, // Set the generated login ID
    };

    const savedDoctor = await mongoClient
      .db("medenix")
      .collection("doctors")
      .insertOne(doctorData);

    if (savedDoctor.acknowledged) {
      console.log("Doctor registered successfully =>", savedDoctor);
      return {
        statusCode: 200,
        body: {
          response: true,
          message: "Doctor registered successfully. Awaiting admin approval.",
          doctorData: {
            ...doctorData,
            password: undefined, // Remove password from response
          },
        },
      };
    } else {
      throw new Error("Registration not successful");
    }
  } catch (error) {
    console.error("Error registering doctor ::: ", error);
    return {
      statusCode: error.statusCode || 500,
      body: {
        response: false,
        message: error.message || "Failed to register doctor",
        error: error.error || "REGISTRATION_FAILED",
      },
    };
  }
};