import { MongoClient, ServerApiVersion } from "mongodb";
import dotenv from "dotenv";

dotenv.config();

// Add connection options with timeout and retries
const connectionOptions = {
  serverApi: {
    version: ServerApiVersion.v1,
    deprecationErrors: true,
  },
  connectTimeoutMS: 5000,
  socketTimeoutMS: 30000,
  maxPoolSize: 10,
  retryWrites: true,
  retryReads: true,
};

// Cache client to reuse connections
let cachedClient = null;

export const getMongoClient = async () => {
  try {
    // Check for MongoDB URL
    const mongoUrl = process.env.MONGODB_URL;
    if (!mongoUrl) {
      throw new Error("MONGODB_URL environment variable is not set");
    }

    // Return cached connection if available
    if (cachedClient) {
      console.log("Using cached MongoDB connection");
      return cachedClient;
    }

    console.log("Creating new MongoDB connection");
    const client = new MongoClient(mongoUrl, connectionOptions);

    // Connect with retry
    let retries = 3;
    let lastError = null;

    while (retries > 0) {
      try {
        await client.connect();
        console.log("MongoDB connection successful");

        // Test the connection with a simple command
        await client.db("admin").command({ ping: 1 });
        console.log("MongoDB ping successful");

        // Cache the client for reuse
        cachedClient = client;
        return client;
      } catch (error) {
        lastError = error;
        console.error(
          `MongoDB connection attempt failed (${retries} retries left): ${error.message}`
        );
        retries--;

        if (retries > 0) {
          // Wait before retrying (exponential backoff)
          const delay = Math.pow(2, 3 - retries) * 1000;
          console.log(`Retrying MongoDB connection in ${delay}ms...`);
          await new Promise((resolve) => setTimeout(resolve, delay));
        }
      }
    }

    throw new Error(
      `Failed to connect to MongoDB after multiple attempts: ${lastError?.message}`
    );
  } catch (error) {
    console.error(`MongoDB connection error: ${error.message}`);
    throw new Error(`Error in creating mongo db client: ${error.message}`);
  }
};

// Gracefully close MongoDB connection
export const closeMongoClient = async () => {
  if (cachedClient) {
    try {
      await cachedClient.close();
      cachedClient = null;
      console.log("MongoDB connection closed");
    } catch (error) {
      console.error(`Error closing MongoDB connection: ${error.message}`);
    }
  }
};
