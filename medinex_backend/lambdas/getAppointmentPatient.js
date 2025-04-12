import { getMongoClient } from "../db/db.js";

export const getAppointmentsByPatientId = async (event, context) => {
    context.callbackWaitsForEmptyEventLoop = false;
  
    try {
      const mongoClient = await getMongoClient();
      const { patientId } = event;
  
      const appointments = await mongoClient
        .db("medenix")
        .collection("appointments")
        .find({ patientId })
        .sort({ date: -1 })
        .toArray();
  
      return {
        statusCode: 200,
        body: {
          response: true,
          message: "Appointments fetched successfully",
          appointments,
        },
      };
    } catch (error) {
      console.error("Error fetching appointments:", error);
      return {
        statusCode: 500,
        body: {
          response: false,
          message: "Internal server error",
          error: "FETCH_APPOINTMENTS_FAILED",
        },
      };
    }
  };
  