import { ObjectId } from "mongodb";
import { getMongoClient } from "../db/db.js";

export const cancelAppointment = async (event, context) => {
  context.callbackWaitsForEmptyEventLoop = false;

  try {
    const mongoClient = await getMongoClient();
    const { appointmentId } = event;

    const result = await mongoClient
      .db("medenix")
      .collection("appointments")
      .deleteOne({ _id: new ObjectId(appointmentId) });

    if (result.deletedCount === 0) {
      return {
        statusCode: 404,
        body: JSON.stringify({
          response: false,
          message: "Appointment not found",
        }),
      };
    }

    return {
      statusCode: 200,
      body: JSON.stringify({
        response: true,
        message: "Appointment cancelled successfully",
      }),
    };
  } catch (error) {
    console.error("Error cancelling appointment:", error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        response: false,
        message: "Internal server error",
        error: "CANCEL_APPOINTMENT_FAILED",
      }),
    };
  }
};
