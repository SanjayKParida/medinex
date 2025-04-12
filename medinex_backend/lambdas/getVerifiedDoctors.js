import { getMongoClient } from "../db/db.js";

let mongoClient;

export const getApprovedDoctors = async (event, context) => {
  context.callbackWaitsForEmptyEventLoop = false;

  try {
    mongoClient = await getMongoClient();

    const doctors = await mongoClient
      .db("medenix")
      .collection("doctors")
      .find({ isApproved: true })
      .project({
        password: 0, // exclude sensitive fields
      })
      .toArray();

    return {
      statusCode: 200,
      body: {
        response: true,
        message: "Approved doctors fetched successfully",
        doctors,
      },
    };
  } catch (error) {
    console.error("Error fetching approved doctors :::", error);
    return {
      statusCode: 500,
      body: {
        response: false,
        message: "Internal server error",
        error: "FETCH_APPROVED_DOCTORS_FAILED",
      },
    };
  }
};
