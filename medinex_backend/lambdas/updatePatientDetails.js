import { getMongoClient } from "../db/db.js";

export const handler = async (event, context) => {
  console.log("Update Patient Event Received ::: ", event);
  context.callbackWaitsForEmptyEventLoop = false;

  let mongoClient;
  try {
    mongoClient = await getMongoClient();
    const { patientId, doctorId, action = "add" } = event;

    if (!patientId) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          response: false,
          message: "patientId is required",
        }),
      };
    }

    const patientsCollection = mongoClient.db("medenix").collection("patients");
    let updateOperation;

    if (action === "remove") {
      if (!doctorId) {
        return {
          statusCode: 400,
          body: JSON.stringify({
            response: false,
            message: "doctorId is required for removal",
          }),
        };
      }
      // Only remove the doctorId if it matches the current one
      updateOperation = {
        $unset: { doctorId: "" },
      };
    } else {
      if (!doctorId) {
        return {
          statusCode: 400,
          body: JSON.stringify({
            response: false,
            message: "doctorId is required for adding",
          }),
        };
      }
      updateOperation = {
        $set: { doctorId: doctorId },
      };
    }

    const result = await patientsCollection.updateOne(
      { patientId: patientId },
      updateOperation
    );

    if (result.matchedCount === 0) {
      return {
        statusCode: 404,
        body: JSON.stringify({
          response: false,
          message: "Patient not found",
        }),
      };
    }

    return {
      statusCode: 200,
      body: JSON.stringify({
        response: true,
        message:
          action === "remove"
            ? "Doctor removed from patient successfully"
            : "Doctor added to patient successfully",
        updatedCount: result.modifiedCount,
      }),
    };
  } catch (error) {
    console.error("Error updating patient's doctor:", error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        response: false,
        message: "Error updating patient's doctor",
        error: error.message,
      }),
    };
  }
};
