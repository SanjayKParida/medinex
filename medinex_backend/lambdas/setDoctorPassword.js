import { getMongoClient } from "../db/db.js";
import bcrypt from "bcryptjs";

let mongoClient;

export const setDoctorPassword = async (event, context) => {
  context.callbackWaitsForEmptyEventLoop = false;

  try {
    console.log("Set Password Event Received ::: ", event);
    mongoClient = await getMongoClient();
    const { doctorLoginId, password } = event;

    if (!doctorLoginId || !password) {
    //   console.log(`doctorLoginId : ${doctorLoginId} password: ${password}`);
      return {
        statusCode: 400,
        body: {
          response: false,
          message: "Login ID and password are required",
        },
      };
    }

    // Check if doctor exists and is approved
    const doctor = await mongoClient
      .db("medenix")
      .collection("doctors")
      .findOne({ doctorLoginId, isApproved: true });

    if (!doctor) {
      return {
        statusCode: 404,
        body: {
          response: false,
          message: "Doctor not found or not approved",
        },
      };
    }

    // Hash the password before saving
    const hashedPassword = await bcrypt.hash(password, 10);

    // Update doctor with password
    await mongoClient
      .db("medenix")
      .collection("doctors")
      .updateOne({ doctorLoginId }, { $set: { password: hashedPassword } });

    return {
      statusCode: 200,
      body: {
        response: true,
        message: "Password set successfully",
      },
    };
  } catch (error) {
    console.error("Error setting password ::: ", error);
    return {
      statusCode: error.statusCode || 500,
      body: {
        response: false,
        message: error.message || "Failed to set password",
        error: "SET_PASSWORD_FAILED",
      },
    };
  }
};
