import { getMongoClient } from "../db/db.js";

let mongoClient;

export const getPatientDetailsByNumber = async (event, context) => {
  context.callbackWaitsForEmptyEventLoop = false;

  try {
    console.log("Get Patient Details Event Received ::: ", event);
    mongoClient = await getMongoClient();

    const { phoneNumber } = event;

    if (!phoneNumber) {
      return {
        statusCode: 400,
        body: {
          response: false,
          message: "Mobile number is required",
        },
      };
    }

    const patient = await mongoClient
      .db("medenix")
      .collection("patients")
      .findOne({ phoneNumber });

    if (!patient) {
      return {
        statusCode: 404,
        body: {
          response: false,
          message: "Patient not found",
        },
      };
    }

    return {
      statusCode: 200,
      body: {
        response: true,
        message: "Patient details fetched successfully",
        patientData: patient,
      },
    };
  } catch (error) {
    console.error("Error fetching patient details ::: ", error);
    return {
      statusCode: 500,
      body: {
        response: false,
        message: "Failed to fetch patient details",
        error: "FETCH_FAILED",
      },
    };
  }
};
