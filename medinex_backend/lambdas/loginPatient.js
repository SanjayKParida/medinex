import { getMongoClient } from "../db/db.js";

let mongoClient;

export const loginPatient = async (event, context) => {
  context.callbackWaitsForEmptyEventLoop = false;

  try {
    console.log("Login Event Received ::: ", event);
    mongoClient = await getMongoClient();
    const { phoneNumber } = event;

    if (!phoneNumber) {
      return {
        statusCode: 400,
        body: {
          response: false,
          message: "Phone number is required",
        },
      };
    }

    // Check if patient exists
    const patient = await mongoClient
      .db("medenix")
      .collection("patients")
      .findOne({ phoneNumber: phoneNumber });

    console.log("patient :: ", patient);

    if (patient) {
      console.log("Patient exists, logging in...");
      return {
        statusCode: 200,
        body: {
          response: true,
          message: "Login successful",
          userData: patient,
        },
      };
    } else {
      console.log("Patient not found, redirecting to registration...");
      return {
        statusCode: 404,
        body: {
          response: false,
          message: "Patient not found, proceed to registration",
        },
      };
    }
  } catch (error) {
    console.error("Error logging in patient ::: ", error);
    return {
      statusCode: error.statusCode || 500,
      body: {
        response: false,
        message: error.message || "Failed to log in",
        error: error.error || "LOGIN_FAILED",
      },
    };
  }
};
