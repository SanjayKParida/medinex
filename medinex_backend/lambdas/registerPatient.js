import { getMongoClient } from "../db/db.js";

let mongoClient;

export const registerPatient = async (event, context) => {
  context.callbackWaitsForEmptyEventLoop = false;

  try {
    console.log("Event received ::: ", event);
    mongoClient = await getMongoClient();
    const requestBody = event;

    const {
      name,
      dob,
      weight,
      height,
      bloodGroup,
      gender,
      doctorID,
      medicalConditions,
      phoneNumber,
      symptoms,
      address,
      pastSurgeries,
      currentMedications,
      emergencyDetails,
    } = requestBody;

    // ✅ Check if patient already exists by phone number
    const existingPatient = await mongoClient
      .db("medenix")
      .collection("patients")
      .findOne({ phoneNumber });

    if (existingPatient) {
      return {
        statusCode: 400,
        body: {
          response: false,
          message: "Patient already registered with this phone number",
        },
      };
    }

    // ✅ Generate human-readable unique patient ID
    const patientId = `PAT-${Date.now().toString().slice(-6)}${Math.floor(10 + Math.random() * 90)}`;

    const userData = {
      patientId,
      ...(name && { name }),
      ...(dob && { dob }),
      ...(weight && { weight }),
      ...(height && { height }),
      ...(bloodGroup && { bloodGroup }),
      ...(phoneNumber && { phoneNumber }),
      ...(gender && { gender }),
      ...(doctorID && { doctorID }),
      ...(medicalConditions && { medicalConditions }),
      ...(symptoms && { symptoms }),
      ...(address && { address }),
      ...(pastSurgeries && { pastSurgeries }),
      ...(currentMedications && { currentMedications }),
      ...(emergencyDetails && { emergencyDetails }),
    };

    const savedPatient = await mongoClient
      .db("medenix")
      .collection("patients")
      .insertOne(userData);

    if (savedPatient.acknowledged) {
      console.log("Patient registered successfully =>", savedPatient);

      return {
        statusCode: 200,
        body: {
          response: true,
          message: "Patient registered successfully",
          userData,
        },
      };
    } else {
      throw new Error("Registration not successful");
    }
  } catch (error) {
    console.error("Error registering patient ::: ", error);
    return {
      statusCode: error.statusCode || 500,
      body: {
        response: false,
        message: error.message || "Failed to register patient",
        error: error.error || "REGISTRATION_FAILED",
      },
    };
  }
};
