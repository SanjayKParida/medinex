import { MongoClient, ServerApiVersion } from "mongodb";
import dotenv from "dotenv";

dotenv.config();
export const getMongoClient = async () => {
  try {
    const client = new MongoClient(process.env.MONGODB_URL, {
      serverApi: {
        version: ServerApiVersion.v1,
        deprecationErrors: true,
      },
    });
    await client.connect();
    console.log("Connection successful");
    return client;
  } catch (error) {
    throw new Error(`Error in creating mongo db client ::: ${error}`);
  }
};