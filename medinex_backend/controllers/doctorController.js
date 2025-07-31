import { getMongoClient } from "../db/db.js";
import bcrypt from "bcryptjs";

let mongoClient;

// Function to generate a unique doctorId like DOC-87234557
const generateUniqueDoctorId = async (mongoClient) => {
  let doctorId;
  let exists = true;

  while (exists) {
    const timestampPart = Date.now().toString().slice(-6); // last 6 digits
    const randomPart = Math.floor(10 + Math.random() * 90); // 2-digit random number
    doctorId = `DOC-${timestampPart}${randomPart}`;

    const existing = await mongoClient
      .db("medenix")
      .collection("doctors")
      .findOne({ doctorId });

    if (!existing) exists = false;
  }

  return doctorId;
};

// Register doctor
export const registerDoctor = async (event) => {
  try {
    console.log("Event received ::: ", event);
    mongoClient = await getMongoClient();
    const requestBody = event;

    const {
      name,
      dob,
      gender,
      mobileNumber,
      email,
      clinicName,
      workAddress,
      medicalRegistrationNumber,
      specialization,
      yearsOfExperience,
      degreeInstitution,
      governmentID,
      password,
    } = requestBody;

    if (!password) {
      throw new Error("Password is required");
    }

    // Generate unique doctorId
    const doctorId = await generateUniqueDoctorId(mongoClient);

    // Hash the password
    const hashedPassword = await bcrypt.hash(password, 10);

    const doctorData = {
      doctorId,
      ...(name && { name }),
      ...(dob && { dob }),
      ...(gender && { gender }),
      ...(mobileNumber && { mobileNumber }),
      ...(email && { email }),
      ...(clinicName && { clinicName }),
      ...(workAddress && { workAddress }),
      ...(medicalRegistrationNumber && { medicalRegistrationNumber }),
      ...(specialization && { specialization }),
      ...(yearsOfExperience && { yearsOfExperience }),
      ...(degreeInstitution && { degreeInstitution }),
      ...(governmentID && { governmentID }),
      password: hashedPassword,
      isApproved: false,
    };

    const savedDoctor = await mongoClient
      .db("medenix")
      .collection("doctors")
      .insertOne(doctorData);

    if (savedDoctor.acknowledged) {
      console.log("Doctor registered successfully =>", savedDoctor);

      const { password: _, ...sanitizedDoctorData } = doctorData;

      return {
        statusCode: 200,
        body: {
          response: true,
          message: "Doctor registered successfully. Awaiting admin approval.",
          doctorData: sanitizedDoctorData,
        },
      };
    } else {
      throw new Error("Registration not successful");
    }
  } catch (error) {
    console.error("Error registering doctor ::: ", error);
    return {
      statusCode: error.statusCode || 500,
      body: {
        response: false,
        message: error.message || "Failed to register doctor",
        error: error.error || "REGISTRATION_FAILED",
      },
    };
  }
};

// Login doctor
export const loginDoctor = async (event) => {
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
          isApproved: doctor.isApproved,
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

    // Exclude password from response
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

// Set doctor password
export const setDoctorPassword = async (event) => {
  try {
    console.log("Set Password Event Received ::: ", event);
    mongoClient = await getMongoClient();
    const { doctorLoginId, password } = event;

    if (!doctorLoginId || !password) {
      return {
        statusCode: 400,
        body: {
          response: false,
          message: "Login ID and password are required",
        },
      };
    }

    // Check if doctor exists and is approved
    const doctor = await mongoClient
      .db("medenix")
      .collection("doctors")
      .findOne({ doctorLoginId, isApproved: true });

    if (!doctor) {
      return {
        statusCode: 404,
        body: {
          response: false,
          message: "Doctor not found or not approved",
        },
      };
    }

    // Hash the password before saving
    const hashedPassword = await bcrypt.hash(password, 10);

    // Update doctor with password
    await mongoClient
      .db("medenix")
      .collection("doctors")
      .updateOne({ doctorLoginId }, { $set: { password: hashedPassword } });

    return {
      statusCode: 200,
      body: {
        response: true,
        message: "Password set successfully",
      },
    };
  } catch (error) {
    console.error("Error setting password ::: ", error);
    return {
      statusCode: error.statusCode || 500,
      body: {
        response: false,
        message: error.message || "Failed to set password",
        error: "SET_PASSWORD_FAILED",
      },
    };
  }
};

// Get doctor details by login ID
export const getDoctorDetails = async (event) => {
  try {
    console.log("Fetching doctor details ::: ", event);
    mongoClient = await getMongoClient();

    const { doctorId } = event;

    if (!doctorId) {
      return {
        statusCode: 400,
        body: {
          response: false,
          message: "Doctor login ID is required",
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
          message: "Doctor not found",
        },
      };
    }

    // Exclude sensitive data like password
    const { password, ...doctorData } = doctor;

    return {
      statusCode: 200,
      body: {
        response: true,
        message: "Doctor details fetched successfully",
        doctorData,
      },
    };
  } catch (error) {
    console.error("Error fetching doctor details ::: ", error);
    return {
      statusCode: 500,
      body: {
        response: false,
        message: "Internal server error",
        error: "DOCTOR_DETAILS_FETCH_FAILED",
      },
    };
  }
};

// Get approved doctors
export const getVerifiedDoctors = async () => {
  try {
    mongoClient = await getMongoClient();

    const doctors = await mongoClient
      .db("medenix")
      .collection("doctors")
      .find({ isApproved: true })
      .project({
        password: 0, // exclude sensitive fields
      })
      .toArray();

    return {
      statusCode: 200,
      body: {
        response: true,
        message: "Approved doctors fetched successfully",
        doctors,
      },
    };
  } catch (error) {
    console.error("Error fetching approved doctors :::", error);
    return {
      statusCode: 500,
      body: {
        response: false,
        message: "Internal server error",
        error: "FETCH_APPROVED_DOCTORS_FAILED",
      },
    };
  }
};

// Get doctor's patients
export const getDoctorPatients = async (event) => {
  let mongoClient = null;

  try {
    try {
      mongoClient = await getMongoClient();

      if (!mongoClient) {
        throw new Error("Failed to get MongoDB client");
      }

      await mongoClient.db("admin").command({ ping: 1 });
      console.log("MongoDB connection verified for getDoctorPatients");
    } catch (dbError) {
      console.error("MongoDB connection failed:", dbError);
      return {
        statusCode: 500,
        body: {
          response: false,
          message: "Database connection error",
          error: dbError.message,
        },
      };
    }

    const { doctorId } = event;

    if (!doctorId) {
      return {
        statusCode: 400,
        body: {
          response: false,
          message: "Doctor ID is required",
        },
      };
    }

    const patients = await mongoClient
      .db("medenix")
      .collection("patients")
      .find({ doctorId: doctorId })
      .toArray();

    if (patients.length === 0) {
      return {
        statusCode: 200,
        body: {
          response: true,
          message: "No patients found for this doctor",
          data: [],
        },
      };
    }

    return {
      statusCode: 200,
      body: {
        response: true,
        message: "Patients retrieved successfully",
        data: patients,
      },
    };
  } catch (error) {
    console.error("Error fetching doctor's patients:", error);

    return {
      statusCode: 500,
      body: {
        response: false,
        message: "Error retrieving patients",
        error: error.message,
      },
    };
  }
};

// Update doctor details
export const updateDoctorDetails = async (event) => {
  console.log("Update Doctor Event Received ::: ", event);

  let mongoClient;
  try {
    mongoClient = await getMongoClient();
    const { doctorId, patientId, action = "add" } = event;

    if (!doctorId || !patientId) {
      return {
        statusCode: 400,
        body: {
          response: false,
          message: "doctorId and patientId are required",
        },
      };
    }

    const doctorsCollection = mongoClient.db("medenix").collection("doctors");
    let result;

    if (action === "remove") {
      result = await doctorsCollection.updateOne(
        { doctorId: doctorId },
        { $pull: { patients: patientId } }
      );
    }

    if (result.matchedCount === 0) {
      return {
        statusCode: 404,
        body: {
          response: false,
          message: "Doctor not found",
        },
      };
    }

    return {
      statusCode: 200,
      body: {
        response: true,
        message:
          action === "remove"
            ? "Patient removed from doctor's patient list successfully"
            : "Patient added to doctor's patient list successfully",
        updatedCount: result.modifiedCount,
      },
    };
  } catch (error) {
    console.error("Error updating doctor's patient list:", error);
    return {
      statusCode: 500,
      body: {
        response: false,
        message: "Error updating doctor's patient list",
        error: error.message,
      },
    };
  }
};
