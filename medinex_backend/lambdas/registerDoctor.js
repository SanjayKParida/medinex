import { getMongoClient } from "../db/db.js";
import bcrypt from "bcryptjs";

let mongoClient;

// Function to generate a unique doctorId like DOC-87234557
const generateUniqueDoctorId = async (mongoClient) => {
  let doctorId;
  let exists = true;

  while (exists) {
    const timestampPart = Date.now().toString().slice(-6); // last 6 digits
    const randomPart = Math.floor(10 + Math.random() * 90); // 2-digit random number
    doctorId = `DOC-${timestampPart}${randomPart}`;

    const existing = await mongoClient
      .db("medenix")
      .collection("doctors")
      .findOne({ doctorId });

    if (!existing) exists = false;
  }

  return doctorId;
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

    if (!password) {
      throw new Error("Password is required");
    }

    // Generate unique doctorId
    const doctorId = await generateUniqueDoctorId(mongoClient);

    // Hash the password
    const hashedPassword = await bcrypt.hash(password, 10);

    const doctorData = {
      doctorId,
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
      password: hashedPassword,
      isApproved: false,
    };

    const savedDoctor = await mongoClient
      .db("medenix")
      .collection("doctors")
      .insertOne(doctorData);

    if (savedDoctor.acknowledged) {
      console.log("Doctor registered successfully =>", savedDoctor);

      const { password: _, ...sanitizedDoctorData } = doctorData;

      return {
        statusCode: 200,
        body:{
          response: true,
          message: "Doctor registered successfully. Awaiting admin approval.",
          doctorData: sanitizedDoctorData,
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
