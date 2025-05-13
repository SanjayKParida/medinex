import { getMongoClient } from "../db/db.js";

export const handler = async (event) => {
  let mongoClient = null;

  try {
    console.log(
      "getHealthLogs lambda invoked with event:",
      JSON.stringify(event)
    );

    try {
      mongoClient = await getMongoClient();

      if (!mongoClient) {
        throw new Error("Failed to get MongoDB client");
      }

      await mongoClient.db("admin").command({ ping: 1 });
      console.log("MongoDB connection verified for getHealthLogs");
    } catch (dbError) {
      console.error("MongoDB connection failed:", dbError);
      return {
        statusCode: 500,
        body: JSON.stringify({
          response: false,
          message: "Database connection error",
          error: dbError.message,
        }),
      };
    }

    const { patientId } = event;

    if (!patientId) {
      console.error("No patientId provided in the request");
      return {
        statusCode: 400,
        body: JSON.stringify({
          response: false,
          message: "Patient ID is required",
        }),
      };
    }

    console.log(`Fetching health logs for patient: ${patientId}`);

    //Find all health logs for the patient
    const healthLogs = await mongoClient
      .db("medenix")
      .collection("healthLogs")
      .find({ patientId: patientId })
      .toArray();

    console.log(
      `Found ${healthLogs.length} health logs for patient ${patientId}`
    );

    //Check if any health logs were found
    if (healthLogs.length === 0) {
      return {
        statusCode: 200,
        body: JSON.stringify({
          response: true,
          message: "No health logs found for this patient",
          healthLogs: [],
        }),
      };
    }

    //Return the health logs
    return {
      statusCode: 200,
      body: JSON.stringify({
        response: true,
        message: "Health logs retrieved successfully",
        healthLogs: healthLogs,
      }),
    };
  } catch (error) {
    console.error("Error fetching health logs:", error);

    return {
      statusCode: 500,
      body: JSON.stringify({
        response: false,
        message: "Error retrieving health logs",
        error: error.message,
      }),
    };
  } finally {
    if (mongoClient && mongoClient._errorConnection) {
      try {
        await mongoClient.close();
        console.log("Closed problematic MongoDB connection");
      } catch (closeError) {
        console.error("Error closing MongoDB connection:", closeError);
      }
    }
  }
};
