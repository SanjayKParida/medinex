import { getMongoClient } from "../../db/db.js";

export const disconnect = async (event) => {
  const connectionId = event.requestContext.connectionId;
  const mongoClient = await getMongoClient();

  await mongoClient.db("medenix").collection("connections").deleteOne({
    connectionId,
  });

  return { statusCode: 200, body: "Disconnected." };
};
