import { getMongoClient } from "../db/db.js";

const connectedUsers = new Map();

export default function websocketHandler(io) {
  io.on("connection", async (socket) => {
    console.log(`WebSocket connection established: ${socket.id}`);

    try {
      // Store connection in MongoDB
      const mongoClient = await getMongoClient();
      await mongoClient
        .db("medenix")
        .collection("connections")
        .updateOne(
          { connectionId: socket.id },
          {
            $set: {
              connectionId: socket.id,
              connectedAt: new Date(),
              status: "connected",
            },
          },
          { upsert: true }
        );

      console.log(`WebSocket connection stored in MongoDB: ${socket.id}`);
    } catch (error) {
      console.error("Failed to store connection in MongoDB:", error);
    }

    // Handle user registration
    socket.on("register", async (data) => {
      try {
        const { userId } = data;
        if (!userId) {
          socket.emit("registration_response", {
            type: "registration_response",
            status: "error",
            message: "Missing userId",
          });
          return;
        }

        // Update in-memory cache
        connectedUsers.set(socket.id, userId);
        connectedUsers.set(userId, socket.id);
        console.log(
          `Registered user ${userId} with connection ${socket.id} in memory`
        );

        // Store in database
        try {
          const mongoClient = await getMongoClient();
          await mongoClient
            .db("medenix")
            .collection("connections")
            .updateOne(
              { connectionId: socket.id },
              { $set: { userId, connectedAt: new Date() } },
              { upsert: true }
            );
          console.log(
            `Stored connection in MongoDB: ${socket.id} -> ${userId}`
          );
        } catch (dbError) {
          console.error("Failed to store connection in MongoDB:", dbError);
        }

        // Send confirmation to client
        socket.emit("registration_response", {
          type: "registration_response",
          status: "success",
          message: "registered",
          userId: userId,
          timestamp: new Date().toISOString(),
        });

        console.log(`Sent registration confirmation to ${socket.id}`);
      } catch (error) {
        console.error("Registration error:", error);
        socket.emit("registration_response", {
          type: "registration_response",
          status: "error",
          message: "Registration failed",
        });
      }
    });

    // Handle QR scan
    socket.on("qr_scan", async (data) => {
      try {
        const { qrCode, doctorId, doctorName, specialization } = data;
        if (!qrCode || !doctorId) {
          socket.emit("qr_scan_response", {
            status: "error",
            message: "Missing qrCode or doctorId",
          });
          return;
        }

        // Parse QR code to get patient ID
        const patientData = JSON.parse(qrCode);
        const patientId = patientData.patientId;

        if (!patientId) {
          socket.emit("qr_scan_response", {
            status: "error",
            message: "Invalid QR code - missing patientId",
          });
          return;
        }

        console.log(`QR scan from doctor ${doctorId} for patient ${patientId}`);

        // Find patient connection
        let patientSocketId = connectedUsers.get(patientId);
        console.log(
          `In-memory patient connection: ${patientSocketId || "not found"}`
        );

        // If not in memory, check database
        if (!patientSocketId) {
          try {
            const mongoClient = await getMongoClient();
            const result = await mongoClient
              .db("medenix")
              .collection("connections")
              .findOne({ userId: patientId });

            if (result) {
              patientSocketId = result.connectionId;
              connectedUsers.set(patientId, patientSocketId);
              console.log(
                `Found patient connection in MongoDB: ${patientSocketId}`
              );
            }
          } catch (dbError) {
            console.error(
              "Error querying patient connection from MongoDB:",
              dbError
            );
          }
        }

        if (!patientSocketId) {
          socket.emit("qr_scan_response", {
            status: "error",
            message: "Patient not connected",
          });
          return;
        }

        // Send message to patient
        io.to(patientSocketId).emit("doctor_request", {
          type: "doctor_request",
          doctorId,
          doctorName,
          specialization,
        });

        console.log(`Sent doctor request to patient ${patientId}`);

        socket.emit("qr_scan_response", {
          status: "success",
          message: "Doctor request sent",
        });
      } catch (error) {
        console.error("QR scan error:", error);
        socket.emit("qr_scan_response", {
          status: "error",
          message: "Invalid QR code format",
        });
      }
    });

    // Handle connection response
    socket.on("connection_response", async (data) => {
      try {
        const { doctorId, patientId, response } = data;

        if (!doctorId || !patientId || !response) {
          socket.emit("connection_response_result", {
            status: "error",
            message: "Invalid response data",
          });
          return;
        }

        // Find doctor connection
        let doctorSocketId = connectedUsers.get(doctorId);
        console.log(
          `In-memory doctor connection: ${doctorSocketId || "not found"}`
        );

        // If not in memory, check database
        if (!doctorSocketId) {
          try {
            const mongoClient = await getMongoClient();
            const result = await mongoClient
              .db("medenix")
              .collection("connections")
              .findOne({ userId: doctorId });

            if (result) {
              doctorSocketId = result.connectionId;
              connectedUsers.set(doctorId, doctorSocketId);
              console.log(
                `Found doctor connection in MongoDB: ${doctorSocketId}`
              );
            }
          } catch (dbError) {
            console.error(
              "Error querying doctor connection from MongoDB:",
              dbError
            );
          }
        }

        if (!doctorSocketId) {
          socket.emit("connection_response_result", {
            status: "error",
            message: "Doctor not connected",
          });
          return;
        }

        const accepted = response === "accepted";
        console.log(
          `Patient ${patientId} ${
            accepted ? "accepted" : "declined"
          } doctor ${doctorId}`
        );

        // Send message to doctor
        io.to(doctorSocketId).emit("patient_response", {
          type: "patient_response",
          accepted,
          patientId,
        });

        console.log(`Sent patient response to doctor ${doctorId}`);

        // Update patient record if accepted
        if (accepted) {
          try {
            const mongoClient = await getMongoClient();
            await mongoClient
              .db("medenix")
              .collection("patients")
              .updateOne(
                { patientId },
                { $set: { doctorId, updatedAt: new Date() } }
              );
            console.log(`Updated patient ${patientId} with doctor ${doctorId}`);
          } catch (dbError) {
            console.error("Failed to update patient record:", dbError);
          }
        }

        socket.emit("connection_response_result", {
          status: "success",
          message: "Response sent",
        });
      } catch (error) {
        console.error("Connection response error:", error);
        socket.emit("connection_response_result", {
          status: "error",
          message: "Failed to process response",
        });
      }
    });

    // Handle disconnect
    socket.on("disconnect", async () => {
      console.log(`WebSocket disconnected: ${socket.id}`);

      // Remove from in-memory cache
      const userId = connectedUsers.get(socket.id);
      if (userId) {
        connectedUsers.delete(socket.id);
        connectedUsers.delete(userId);
        console.log(`Removed user ${userId} from in-memory cache`);
      }

      // Update connection status in database
      try {
        const mongoClient = await getMongoClient();
        await mongoClient
          .db("medenix")
          .collection("connections")
          .updateOne(
            { connectionId: socket.id },
            {
              $set: {
                disconnectedAt: new Date(),
                status: "disconnected",
              },
            }
          );
        console.log(`Updated connection status in MongoDB: ${socket.id}`);
      } catch (error) {
        console.error("Failed to update connection status:", error);
      }
    });
  });
}
