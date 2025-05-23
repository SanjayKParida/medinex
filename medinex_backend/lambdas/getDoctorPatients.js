import { getMongoClient } from "../db/db.js";

export const handler = async (event) => {
  let mongoClient = null;

  try {
    // Get MongoDB client with proper error handling
    try {
      mongoClient = await getMongoClient();

      // Verify the connection is active
      if (!mongoClient) {
        throw new Error("Failed to get MongoDB client");
      }

      // Test the connection with a ping command
      await mongoClient.db("admin").command({ ping: 1 });
      console.log("MongoDB connection verified for getDoctorPatients");
    } catch (dbError) {
      console.error("MongoDB connection failed:", dbError);
      return {
        statusCode: 500,
        body: {
          response: false,
          message: "Database connection error",
          error: dbError.message,
        },
      };
    }

    const { doctorId } = event;

    // Validate doctorId
    if (!doctorId) {
      return {
        statusCode: 400,
        body: {
          response: false,
          message: "Doctor ID is required",
        },
      };
    }

    // Find all patients with this doctorId
    const patients = await mongoClient
      .db("medenix")
      .collection("patients")
      .find({ doctorId: doctorId })
      .toArray();

    // Check if patients were found
    if (patients.length === 0) {
      return {
        statusCode: 200,
        body: {
          response: true,
          message: "No patients found for this doctor",
          data: [],
        },
      };
    }

    // Return successful response with patient data
    return {
      statusCode: 200,
      body: {
        response: true,
        message: "Patients retrieved successfully",
        data: patients,
      },
    };
  } catch (error) {
    console.error("Error fetching doctor's patients:", error);

    return {
      statusCode: 500,
      body: {
        response: false,
        message: "Error retrieving patients",
        error: error.message,
      },
    };
  } finally {
    // Don't close the MongoDB connection in Lambda functions
    // AWS Lambda reuses the container, so we want to keep the connection alive
    // for future invocations to benefit from connection reuse

    // Only close if there was an error establishing the connection
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
