import { getMongoClient } from "../db/db.js";

let mongoClient;

export const createAppointment = async (event, context) => {
  context.callbackWaitsForEmptyEventLoop = false;

  try {
    console.log("Creating appointment ::: ", event);
    mongoClient = await getMongoClient();

    const {
      patientId,
      doctorId, // this is doctorLoginId
      date,     // format: "YYYY-MM-DD"
      time,     // format: "HH:mm"
      reason,
    } = event;

    // Validate required fields
    if (!patientId || !doctorId || !date || !time || !reason) {
      return {
        statusCode: 400,
        body: {
          response: false,
          message: "Missing required appointment fields",
        },
      };
    }

    const doctorCollection = mongoClient.db("medenix").collection("doctors");
    const appointmentCollection = mongoClient
      .db("medenix")
      .collection("appointments");

    // 1. Find the doctor by loginId
    const doctor = await doctorCollection.findOne({ doctorId: doctorId });

    if (!doctor || !doctor.isApproved) {
      return {
        statusCode: 404,
        body: {
          response: false,
          message: "Doctor not found or not approved.",
        },
      };
    }

    // 2. Check how many appointments the doctor has for this date
    const appointmentsOnDate = await appointmentCollection
      .find({ doctorId, date })
      .toArray();

    if (appointmentsOnDate.length >= 3) {
      return {
        statusCode: 403,
        body: {
          response: false,
          message: "Doctor is fully booked for this date.",
        },
      };
    }

    // 3. Check if the requested time slot is already taken
    const isSlotTaken = appointmentsOnDate.find((appt) => appt.time === time);

    if (isSlotTaken) {
      return {
        statusCode: 409,
        body: {
          response: false,
          message: "Selected time slot is already booked.",
        },
      };
    }

    // 4. Create the appointment (auto-confirmed)
    const appointment = {
      patientId,
      doctorId,
      date,
      time,
      reason,
      status: "confirmed", // always confirmed if passed validations
      createdAt: new Date(),
    };

    const result = await appointmentCollection.insertOne(appointment);

    return {
      statusCode: 201,
      body: {
        response: true,
        message: "Appointment booked successfully",
        appointmentId: result.insertedId,
      },
    };
  } catch (error) {
    console.error("Error creating appointment ::: ", error);
    return {
      statusCode: 500,
      body: {
        response: false,
        message: "Internal server error",
        error: "APPOINTMENT_CREATION_FAILED",
      },
    };
  }
};
