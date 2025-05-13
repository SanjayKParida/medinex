import { getMongoClient } from "../../db/db.js";

export const handler = async (event) => {
  const connectionId = event.requestContext.connectionId;
  console.log(
    "WebSocket connection request received, Connection ID:",
    connectionId
  );
  let mongoClient = null;

  try {
    // Get MongoDB client with more explicit error handling
    try {
      console.log("Attempting to get MongoDB client...");
      mongoClient = await getMongoClient();

      // Verify the connection is active with timeout
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
    } catch (dbError) {
      console.error("MongoDB connection failed:", dbError);
      return {
        statusCode: 500,
        body: JSON.stringify({
          message: "Database connection error",
          error: dbError.message,
          connectionId: connectionId, // Include connectionId for client tracking
        }),
      };
    }

    if (!mongoClient) {
      console.error("MongoDB client is null after successful connection");
      throw new Error("Failed to establish MongoDB connection");
    }

    // Store connection in MongoDB with specific error handling
    console.log("Storing WebSocket connection in MongoDB...");
    try {
      const result = await mongoClient
        .db("medenix")
        .collection("connections")
        .updateOne(
          { connectionId },
          {
            $set: {
              connectionId,
              connectedAt: new Date(),
              status: "connected",
              requestContext: JSON.stringify(event.requestContext),
            },
          },
          { upsert: true }
        );

      console.log(
        `WebSocket connection stored in MongoDB. ConnectionId: ${connectionId}, Operation result:`,
        JSON.stringify(result)
      );
    } catch (dbOpError) {
      console.error("Failed to store connection in MongoDB:", dbOpError);
      throw new Error(`Database operation failed: ${dbOpError.message}`);
    }

    // Connection successful - return JSON response with connectionId
    console.log(`WebSocket connection successful for ${connectionId}`);
    return {
      statusCode: 200,
      body: JSON.stringify({
        message: "Connected successfully",
        connectionId: connectionId,
      }),
    };
  } catch (error) {
    console.error("WebSocket connection error:", error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: "Failed to connect",
        error: error.message,
        connectionId: connectionId, // Include connectionId even on error
      }),
    };
  } finally {
    // Don't close the MongoDB connection in Lambda functions
    // AWS Lambda reuses the container, so we want to keep the connection alive
    // for future invocations to benefit from connection reuse

    // Only close if there was an error establishing the connection
    if (mongoClient && mongoClient._errorConnection) {
      try {
        await mongoClient.close();
        console.log("Closed problematic MongoDB connection");
      } catch (closeError) {
        console.error("Error closing MongoDB connection:", closeError);
      }
    } else if (mongoClient) {
      console.log("Keeping MongoDB connection alive for future invocations");
    }
  }
};
