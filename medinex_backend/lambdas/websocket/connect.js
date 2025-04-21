import { getMongoClient } from "../../db/db.js";

export const connect = async (event) => {
  const connectionId = event.requestContext.connectionId;
  const mongoClient = await getMongoClient();

  await mongoClient.db("medenix").collection("connections").insertOne({
    connectionId,
    connectedAt: new Date(),
  });

  return { statusCode: 200, body: "Connected." };
};
