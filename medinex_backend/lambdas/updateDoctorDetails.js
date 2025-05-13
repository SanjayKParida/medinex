import { getMongoClient } from "../db/db.js";

export const handler = async (event, context) => {
  console.log("Update Doctor Event Received ::: ", event);
  context.callbackWaitsForEmptyEventLoop = false;

  let mongoClient;
  try {
    mongoClient = await getMongoClient();
    const { doctorId, patientId, action = "add" } = event;

    if (!doctorId || !patientId) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          response: false,
          message: "doctorId and patientId are required",
        }),
      };
    }

    const doctorsCollection = mongoClient.db("medenix").collection("doctors");
    let result;

    if (action === "remove") {
      const result = await doctorsCollection.updateOne(
        { doctorId: doctorId },
        { $pull: { patients: patientId } }
      );
    
      if (result.matchedCount === 0) {
        return {
          statusCode: 404,
          body: JSON.stringify({
            response: false,
            message: "Doctor not found",
          }),
        };
      }
    
      return {
        statusCode: 200,
        body: JSON.stringify({
          response: true,
          message: "Patient removed from doctor's patient list successfully",
          updatedCount: result.modifiedCount,
        }),
      };
    }

    if (result.matchedCount === 0) {
      return {
        statusCode: 404,
        body: JSON.stringify({
          response: false,
          message: "Doctor not found",
        }),
      };
    }

    return {
      statusCode: 200,
      body: JSON.stringify({
        response: true,
        message:
          action === "remove"
            ? "Patient removed from doctor's patient list successfully"
            : "Patient added to doctor's patient list successfully",
        updatedCount: result.modifiedCount,
      }),
    };
  } catch (error) {
    console.error("Error updating doctor's patient list:", error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        response: false,
        message: "Error updating doctor's patient list",
        error: error.message,
      }),
    };
  }
};
