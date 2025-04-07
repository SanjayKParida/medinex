import { getMongoClient } from "../db/db.js";

let mongoClient;

export const getDoctorDetailsByLoginId = async (event, context) => {
  context.callbackWaitsForEmptyEventLoop = false;

  try {
    console.log("Fetching doctor details ::: ", event);
    mongoClient = await getMongoClient();

    const { doctorLoginId } = event;

    if (!doctorLoginId) {
      return {
        statusCode: 400,
        body: {
          response: false,
          message: "Doctor login ID is required",
        },
      };
    }

    const doctor = await mongoClient
      .db("medenix")
      .collection("doctors")
      .findOne({ doctorLoginId });

    if (!doctor) {
      return {
        statusCode: 404,
        body: {
          response: false,
          message: "Doctor not found",
        },
      };
    }

    // Exclude sensitive data like password
    const { password, ...doctorData } = doctor;

    return {
      statusCode: 200,
      body: {
        response: true,
        message: "Doctor details fetched successfully",
        doctorData,
      },
    };
  } catch (error) {
    console.error("Error fetching doctor details ::: ", error);
    return {
      statusCode: 500,
      body: {
        response: false,
        message: "Internal server error",
        error: "DOCTOR_DETAILS_FETCH_FAILED",
      },
    };
  }
};
