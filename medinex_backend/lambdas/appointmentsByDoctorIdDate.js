import { getMongoClient } from "../db/db.js";

export const getAvailableSlots = async (event, context) => {
  context.callbackWaitsForEmptyEventLoop = false;

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
