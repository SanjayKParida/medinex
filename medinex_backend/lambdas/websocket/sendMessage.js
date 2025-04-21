import AWS from "aws-sdk";
import { getMongoClient } from "../../db/db.js";
import dotenv from "dotenv";

dotenv.config();

const apigwManagementApi = new AWS.ApiGatewayManagementApi({
  endpoint: process.env.WEBSOCKET_API_ENDPOINT,
});

export const sendMessage = async (event) => {
  const mongoClient = await getMongoClient();
  const connectionId = event.requestContext.connectionId;
  const body = JSON.parse(event.body);

  const { action, data } = body;

  switch (action) {
    case "register":
      return await handleRegisterUser(data, connectionId, mongoClient);

    case "request_appointment":
      return await handleRequestAppointment(data, connectionId, mongoClient);

    case "respond_appointment":
      return await handleResponseAppointment(data, connectionId, mongoClient);

    default:
      return { statusCode: 400, body: "Unknown action." };
  }
};

async function handleRegisterUser(data, connectionId, client) {
  const { userId } = data;

  if (!userId) {
    return { statusCode: 400, body: "userId is required" };
  }

  try {
    // Save or update the connection with userId
    await client
      .db("medenix")
      .collection("connections")
      .updateOne(
        { connectionId },
        {
          $set: {
            userId,
            connectionId,
            connectedAt: new Date(),
          },
        },
        { upsert: true }
      );

    console.log(`User ${userId} registered with connection ${connectionId}`);
    return { statusCode: 200, body: "User registered successfully" };
  } catch (error) {
    console.error("Error registering user:", error);
    return { statusCode: 500, body: "Error registering user" };
  }
}

async function handleRequestAppointment(data, doctorConnId, client) {
  const { patientId, doctorId } = data;

  // Get patient connection ID
  const patientConn = await client
    .db("medenix")
    .collection("connections")
    .findOne({ userId: patientId });

  if (!patientConn) {
    return { statusCode: 404, body: "Patient not connected" };
  }

  await apigwManagementApi
    .postToConnection({
      ConnectionId: patientConn.connectionId,
      Data: JSON.stringify({
        type: "doctor_request",
        doctorId,
      }),
    })
    .promise();

  return { statusCode: 200, body: "Appointment request sent" };
}

async function handleResponseAppointment(data, patientConnId, client) {
  const { response, doctorId, patientId } = data;

  // Get doctor connection ID
  const doctorConn = await client
    .db("medenix")
    .collection("connections")
    .findOne({ userId: doctorId });

  // If response is "accepted", update the patient document with doctorId
  if (response === "accepted") {
    try {
      await client
        .db("medenix")
        .collection("patients")
        .updateOne(
          { patientId: patientId },
          { $set: { doctorId: doctorId, updatedAt: new Date() } }
        );

      console.log(
        `Patient ${patientId} is now associated with doctor ${doctorId}`
      );
    } catch (error) {
      console.error("Error updating patient document:", error);
    }
  }

  if (doctorConn) {
    await apigwManagementApi
      .postToConnection({
        ConnectionId: doctorConn.connectionId,
        Data: JSON.stringify({
          type: "patient_response",
          accepted: response === "accepted",
          patientId: patientId, // Include patientId in the response
        }),
      })
      .promise();
  }

  return { statusCode: 200, body: "Response sent" };
}
