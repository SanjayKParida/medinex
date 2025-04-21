import { getMongoClient } from "../db/db.js";

export const handler = async (event) => {
  const mongoClient = await getMongoClient();

  try {
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
    await mongoClient.close();
  }
};
