import { ObjectId } from "mongodb";
import { getMongoClient } from "../db/db.js";

let mongoClient;

// Create appointment
export const createAppointment = async (event) => {
  try {
    console.log("Creating appointment ::: ", event);
    mongoClient = await getMongoClient();

    const {
      patientId,
      doctorId, // this is doctorLoginId
      date, // format: "YYYY-MM-DD"
      time, // format: "HH:mm"
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

// Get appointments by patient ID
export const getAppointmentsByPatientId = async (event) => {
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

// Get appointments by doctor ID
export const getAppointmentsByDoctorId = async (event) => {
  try {
    const mongoClient = await getMongoClient();
    const { doctorId } = event;

    const appointments = await mongoClient
      .db("medenix")
      .collection("appointments")
      .find({ doctorId })
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
    console.error("Error fetching doctor appointments:", error);
    return {
      statusCode: 500,
      body: {
        response: false,
        message: "Internal server error",
        error: "FETCH_DOCTOR_APPOINTMENTS_FAILED",
      },
    };
  }
};

// Cancel appointment
export const cancelAppointment = async (event) => {
  try {
    const mongoClient = await getMongoClient();
    const { appointmentId, reason, cancelledBy } = event;

    const result = await mongoClient
      .db("medenix")
      .collection("appointments")
      .updateOne(
        { _id: new ObjectId(appointmentId) },
        {
          $set: {
            status: "cancelled",
            cancellationReason: reason,
            cancelledBy: cancelledBy,
            cancelledAt: new Date(),
          },
        }
      );

    if (result.matchedCount === 0) {
      return {
        statusCode: 404,
        body: {
          response: false,
          message: "Appointment not found",
        },
      };
    }

    return {
      statusCode: 200,
      body: {
        response: true,
        message: "Appointment cancelled successfully",
      },
    };
  } catch (error) {
    console.error("Error cancelling appointment:", error);
    return {
      statusCode: 500,
      body: {
        response: false,
        message: "Internal server error",
        error: "CANCEL_APPOINTMENT_FAILED",
      },
    };
  }
};

// Get available slots
export const getAvailableSlots = async (event) => {
  try {
    const { doctorId, date } = event;

    if (!doctorId || !date) {
      return {
        statusCode: 400,
        body: {
          response: false,
          message: "Missing doctorId or date",
        },
      };
    }

    const client = await getMongoClient();
    const appointmentCollection = client
      .db("medenix")
      .collection("appointments");

    const bookedAppointments = await appointmentCollection
      .find({ doctorId, date })
      .toArray();

    const allSlots = ["10:00", "12:00", "14:00"];

    const bookedSlots = bookedAppointments.map((appt) => appt.time);

    const availableSlots = allSlots.filter(
      (slot) => !bookedSlots.includes(slot)
    );

    return {
      statusCode: 200,
      body: {
        response: true,
        availableSlots,
      },
    };
  } catch (err) {
    console.error("Slot fetch failed :::", err);
    return {
      statusCode: 500,
      body: {
        response: false,
        message: "Failed to fetch available slots",
      },
    };
  }
};
