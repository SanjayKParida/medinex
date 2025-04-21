import { getMongoClient } from "../db/db.js";
import bcrypt from "bcryptjs";

let mongoClient;

export const loginDoctor = async (event, context) => {
  context.callbackWaitsForEmptyEventLoop = false;

  try {
    console.log("Doctor Login Event Received ::: ", event);
    mongoClient = await getMongoClient();
    const { doctorId, password } = event;

    if (!doctorId || !password) {
      return {
        statusCode: 400,
        body: {
          response: false,
          message: "Doctor ID and password are required",
        },
      };
    }

    const doctor = await mongoClient
      .db("medenix")
      .collection("doctors")
      .findOne({ doctorId });

    if (!doctor) {
      return {
        statusCode: 404,
        body: {
          response: false,
          message: "Doctor not found. Please register first.",
        },
      };
    }

    // Check approval status
    if (!doctor.isApproved) {
      const { password: _, ...doctorData } = doctor;

      return {
        statusCode: 200,
        body: {
          response: false,
          isApproved:
            doctor.isApproved,
          doctorData,
        },
      };
    }

    // Verify password
    const passwordMatch = await bcrypt.compare(password, doctor.password);
    if (!passwordMatch) {
      return {
        statusCode: 401,
        body: {
          response: false,
          message: "Invalid password. Please try again.",
        },
      };
    }

    //  Exclude password from response
    const { password: _, ...doctorData } = doctor;

    console.log("Doctor login successful:", doctor.name);
    return {
      statusCode: 200,
      body: {
        response: true,
        message: "Login successful",
        doctorData,
      },
    };
  } catch (error) {
    console.error("Error logging in doctor ::: ", error);
    return {
      statusCode: 500,
      body: {
        response: false,
        message: "Failed to log in",
        error: "LOGIN_FAILED",
      },
    };
  }
};
