import AWS from "aws-sdk";
import { getMongoClient } from "../../db/db.js";
import dotenv from "dotenv";

dotenv.config();

const connectedUsers = new Map();

const getApiGatewayManagementApi = (event) => {
  const { domainName, stage } = event.requestContext || {};
  if (!domainName || !stage) {
    throw new Error("Invalid WebSocket event structure");
  }
  const endpoint = `https://${domainName}/${stage}`;
  return new AWS.ApiGatewayManagementApi({ endpoint });
};

export const handler = async (event) => {
  let mongoClient = null;
  try {
    const connectionId = event.requestContext?.connectionId;
    if (!connectionId) {
      console.error("Missing connectionId");
      return {
        statusCode: 400,
        body: JSON.stringify({ error: "Missing connectionId" }),
      };
    }

    const body = JSON.parse(event.body || "{}");
    const action = body.action;
    const data = body.data || {};

    if (!action) {
      console.error("No action provided");
      return {
        statusCode: 400,
        body: JSON.stringify({ error: "Action missing" }),
      };
    }

    console.log("Processing action:", action);

    // Get MongoDB client with proper connection validation
    try {
      console.log("Attempting to get MongoDB client...");
      mongoClient = await getMongoClient();

      // Verify the MongoDB connection is active with a timeout
      if (mongoClient) {
        console.log("Verifying MongoDB connection with ping...");
        await Promise.race([
          mongoClient.db("admin").command({ ping: 1 }),
          new Promise((_, reject) =>
            setTimeout(
              () => reject(new Error("MongoDB ping timeout after 3 seconds")),
              3000
            )
          ),
        ]);
        console.log("MongoDB connection verified successfully with ping");
      } else {
        throw new Error("MongoDB client is null after getMongoClient()");
      }
    } catch (dbError) {
      console.error("MongoDB connection failed:", dbError);
      // Don't return early for non-database actions
      // We'll skip DB operations but still try to handle the action
      mongoClient = null;
    }

    // Handle different actions
    let result;
    switch (action) {
      case "register":
        result = await handleRegister(connectionId, data, mongoClient, event);
        break;
      case "qr_scan":
        result = await handleQrScan(connectionId, data, mongoClient, event);
        break;
      case "connection_response":
        result = await handleConnectionResponse(
          connectionId,
          data,
          mongoClient,
          event
        );
        break;
      default:
        result = {
          statusCode: 400,
          body: JSON.stringify({ error: "Unknown action" }),
        };
        break;
    }

    // Ensure response body is JSON
    if (
      typeof result.body === "string" &&
      !result.body.startsWith("{") &&
      !result.body.startsWith("[")
    ) {
      console.log(`Converting string response "${result.body}" to JSON object`);
      result.body = JSON.stringify({ message: result.body });
    }

    return result;
  } catch (error) {
    console.error("Server Error:", error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        error: "Internal Server Error",
        message: error.message,
      }),
    };
  } finally {
    // Only close MongoDB client if it was successfully connected
    if (mongoClient) {
      try {
        await mongoClient.close();
        console.log("MongoDB connection closed");
      } catch (closeError) {
        console.error("Error closing MongoDB connection:", closeError);
      }
    }
  }
};

async function handleRegister(connectionId, data, client, event) {
  const { userId } = data;
  if (!userId) {
    return {
      statusCode: 400,
      body: JSON.stringify({ error: "Missing userId" }),
    };
  }

  // Update in-memory cache
  connectedUsers.set(connectionId, userId);
  connectedUsers.set(userId, connectionId);
  console.log(
    `Registered user ${userId} with connection ${connectionId} in memory`
  );

  // Store in database if MongoDB is connected
  if (client) {
    try {
      await client
        .db("medenix")
        .collection("connections")
        .updateOne(
          { connectionId },
          { $set: { userId, connectedAt: new Date() } },
          { upsert: true }
        );
      console.log(`Stored connection in MongoDB: ${connectionId} -> ${userId}`);
    } catch (dbError) {
      console.error("Failed to store connection in MongoDB:", dbError);
      // Continue with in-memory registration only
    }
  } else {
    console.log(
      "Skipping MongoDB storage - using in-memory only for registration"
    );
  }

  // Send confirmation to client regardless of MongoDB status
  try {
    const api = getApiGatewayManagementApi(event);
    // ALWAYS send proper JSON formatted responses
    const responseData = {
      type: "registration_response",
      status: "success",
      message: "registered",
      userId: userId,
      timestamp: new Date().toISOString(),
    };

    console.log(
      `Sending registration confirmation to ${connectionId}: ${JSON.stringify(
        responseData
      )}`
    );

    await api
      .postToConnection({
        ConnectionId: connectionId,
        Data: JSON.stringify(responseData),
      })
      .promise();
    console.log(`Sent registration confirmation to ${connectionId}`);
  } catch (apiError) {
    console.error("Failed to send registration confirmation:", apiError);
    // Connection might be stale
    connectedUsers.delete(connectionId);
    connectedUsers.delete(userId);

    if (apiError.code === "GoneException") {
      console.log(`Connection ${connectionId} is no longer valid`);
    }

    // Don't throw here, just return a status
    return {
      statusCode: 500,
      body: JSON.stringify({ error: "Failed to send confirmation" }),
    };
  }

  return {
    statusCode: 200,
    body: JSON.stringify({ status: "success", message: "Registered" }),
  };
}

async function handleQrScan(connectionId, data, client, event) {
  const { qrCode, doctorId, doctorName, specialization } = data;
  if (!qrCode || !doctorId) {
    return {
      statusCode: 400,
      body: JSON.stringify({ error: "Missing qrCode or doctorId" }),
    };
  }

  try {
    // patientId will be extracted from QRCode JSON
    const patientData = JSON.parse(qrCode);
    const patientId = patientData.patientId;

    if (!patientId) {
      console.error("QR code missing patientId field");
      return {
        statusCode: 400,
        body: JSON.stringify({ error: "Invalid QR code - missing patientId" }),
      };
    }

    console.log(`QR scan from doctor ${doctorId} for patient ${patientId}`);

    // First check in-memory cache
    let patientConnId = connectedUsers.get(patientId);
    console.log(
      `In-memory patient connection: ${patientConnId || "not found"}`
    );

    // If not in memory and MongoDB is connected, check database
    if (!patientConnId && client) {
      try {
        const result = await client
          .db("medenix")
          .collection("connections")
          .findOne({ userId: patientId });

        if (result) {
          patientConnId = result.connectionId;
          // Update in-memory cache
          connectedUsers.set(patientId, patientConnId);
          console.log(`Found patient connection in MongoDB: ${patientConnId}`);
        }
      } catch (dbError) {
        console.error(
          "Error querying patient connection from MongoDB:",
          dbError
        );
      }
    }

    if (!patientConnId) {
      console.log(`Patient ${patientId} not connected.`);
      return {
        statusCode: 404,
        body: JSON.stringify({ error: "Patient not connected" }),
      };
    }

    // Try to send message to patient
    try {
      const api = getApiGatewayManagementApi(event);
      await api
        .postToConnection({
          ConnectionId: patientConnId,
          Data: JSON.stringify({
            type: "doctor_request",
            doctorId,
            doctorName,
            specialization,
          }),
        })
        .promise();
      console.log(`Sent doctor request to patient ${patientId}`);
    } catch (apiError) {
      console.error("Failed to send doctor request to patient:", apiError);

      // If connection is stale, remove it
      if (apiError.code === "GoneException") {
        console.log(`Patient connection ${patientConnId} is no longer valid`);
        connectedUsers.delete(patientId);

        // Also remove from DB if possible
        if (client) {
          try {
            await client
              .db("medenix")
              .collection("connections")
              .deleteOne({ connectionId: patientConnId });
            console.log(
              `Removed stale connection from MongoDB: ${patientConnId}`
            );
          } catch (dbError) {
            console.error(
              "Failed to remove stale connection from MongoDB:",
              dbError
            );
          }
        }
      }

      return {
        statusCode: 500,
        body: JSON.stringify({
          error: "Failed to send doctor request to patient",
        }),
      };
    }

    return {
      statusCode: 200,
      body: JSON.stringify({
        status: "success",
        message: "Doctor request sent",
      }),
    };
  } catch (parseError) {
    console.error("Error parsing QR code:", parseError);
    return {
      statusCode: 400,
      body: JSON.stringify({ error: "Invalid QR code format" }),
    };
  }
}

async function handleConnectionResponse(connectionId, data, client, event) {
  const { doctorId, patientId, response } = data;

  if (!doctorId || !patientId || !response) {
    return {
      statusCode: 400,
      body: JSON.stringify({ error: "Invalid response data" }),
    };
  }

  // First check in-memory cache
  let doctorConnId = connectedUsers.get(doctorId);
  console.log(`In-memory doctor connection: ${doctorConnId || "not found"}`);

  // If not in memory and MongoDB is connected, check database
  if (!doctorConnId && client) {
    try {
      const result = await client
        .db("medenix")
        .collection("connections")
        .findOne({ userId: doctorId });

      if (result) {
        doctorConnId = result.connectionId;
        // Update in-memory cache
        connectedUsers.set(doctorId, doctorConnId);
        console.log(`Found doctor connection in MongoDB: ${doctorConnId}`);
      }
    } catch (dbError) {
      console.error("Error querying doctor connection from MongoDB:", dbError);
    }
  }

  if (!doctorConnId) {
    console.log(`Doctor ${doctorId} not connected.`);
    return {
      statusCode: 404,
      body: JSON.stringify({ error: "Doctor not connected" }),
    };
  }

  const accepted = response === "accepted";
  console.log(
    `Patient ${patientId} ${
      accepted ? "accepted" : "declined"
    } doctor ${doctorId}`
  );

  // Try to send message to doctor
  try {
    const api = getApiGatewayManagementApi(event);
    await api
      .postToConnection({
        ConnectionId: doctorConnId,
        Data: JSON.stringify({
          type: "patient_response",
          accepted,
          patientId,
        }),
      })
      .promise();
    console.log(`Sent patient response to doctor ${doctorId}`);
  } catch (apiError) {
    console.error("Failed to send patient response to doctor:", apiError);

    // If connection is stale, remove it
    if (apiError.code === "GoneException") {
      console.log(`Doctor connection ${doctorConnId} is no longer valid`);
      connectedUsers.delete(doctorId);

      // Also remove from DB if possible
      if (client) {
        try {
          await client
            .db("medenix")
            .collection("connections")
            .deleteOne({ connectionId: doctorConnId });
          console.log(`Removed stale connection from MongoDB: ${doctorConnId}`);
        } catch (dbError) {
          console.error(
            "Failed to remove stale connection from MongoDB:",
            dbError
          );
        }
      }
    }

    return {
      statusCode: 500,
      body: JSON.stringify({
        error: "Failed to send patient response to doctor",
      }),
    };
  }

  // Update patient record if accepted
  if (accepted && client) {
    try {
      await client
        .db("medenix")
        .collection("patients")
        .updateOne(
          { patientId },
          { $set: { doctorId, updatedAt: new Date() } }
        );
      console.log(`Updated patient ${patientId} with doctor ${doctorId}`);
    } catch (dbError) {
      console.error("Failed to update patient record:", dbError);
      // Continue anyway - the response has already been sent
    }
  }

  return {
    statusCode: 200,
    body: JSON.stringify({ status: "success", message: "Response sent" }),
  };
}
