import { getMongoClient } from "../../db/db.js";


export const handler = async (event) => {
  const connectionId = event.requestContext.connectionId;
  let mongoClient;

  try {
    mongoClient = await getMongoClient();

    // Get user ID associated with this connection
    const connection = await mongoClient
      .db("medenix")
      .collection("connections")
      .findOne({ connectionId });

    if (connection && connection.userId) {
      // Clean up in-memory map if you're using one in your application
      console.log(`Disconnecting user: ${connection.userId}`);
    }

    // Update connection status in database
    await mongoClient
      .db("medenix")
      .collection("connections")
      .updateOne(
        { connectionId },
        {
          $set: {
            disconnectedAt: new Date(),
            status: "disconnected",
          },
        }
      );

    console.log(`WebSocket disconnected: ${connectionId}`);

    return {
      statusCode: 200,
      body: "Disconnected",
    };
  } catch (error) {
    console.error("Disconnect error:", error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: "Failed to process disconnect",
        error: error.message,
      }),
    };
  } finally {
    if (mongoClient) await mongoClient.close();
  }
};
