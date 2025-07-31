import { getMongoClient } from "../db/db.js";

let mongoClient;

// Register patient
export const registerPatient = async (event) => {
  try {
    console.log("Event received ::: ", event);
    mongoClient = await getMongoClient();
    const requestBody = event;

    const {
      name,
      dob,
      weight,
      height,
      bloodGroup,
      gender,
      doctorId,
      medicalConditions,
      phoneNumber,
      address,
      pastSurgeries,
      currentMedications,
      emergencyDetails,
    } = requestBody;

    // Check if patient already exists by phone number
    const existingPatient = await mongoClient
      .db("medenix")
      .collection("patients")
      .findOne({ phoneNumber });

    if (existingPatient) {
      return {
        statusCode: 400,
        body: {
          response: false,
          message: "Patient already registered with this phone number",
        },
      };
    }

    // Generate human-readable unique patient ID
    const patientId = `PAT-${Date.now().toString().slice(-6)}${Math.floor(
      10 + Math.random() * 90
    )}`;

    const userData = {
      patientId,
      ...(name && { name }),
      ...(dob && { dob }),
      ...(weight && { weight }),
      ...(height && { height }),
      ...(bloodGroup && { bloodGroup }),
      ...(phoneNumber && { phoneNumber }),
      ...(gender && { gender }),
      ...(doctorId && { doctorId }),
      ...(medicalConditions && { medicalConditions }),
      ...(address && { address }),
      ...(pastSurgeries && { pastSurgeries }),
      ...(currentMedications && { currentMedications }),
      ...(emergencyDetails && { emergencyDetails }),
    };

    const savedPatient = await mongoClient
      .db("medenix")
      .collection("patients")
      .insertOne(userData);

    if (savedPatient.acknowledged) {
      console.log("Patient registered successfully =>", savedPatient);

      return {
        statusCode: 200,
        body: {
          response: true,
          message: "Patient registered successfully",
          userData,
        },
      };
    } else {
      throw new Error("Registration not successful");
    }
  } catch (error) {
    console.error("Error registering patient ::: ", error);
    return {
      statusCode: error.statusCode || 500,
      body: {
        response: false,
        message: error.message || "Failed to register patient",
        error: error.error || "REGISTRATION_FAILED",
      },
    };
  }
};

// Login patient
export const loginPatient = async (event) => {
  try {
    console.log("Login Event Received ::: ", event);
    mongoClient = await getMongoClient();
    const { phoneNumber } = event;

    if (!phoneNumber) {
      return {
        statusCode: 400,
        body: {
          response: false,
          message: "Phone number is required",
        },
      };
    }

    // Check if patient exists
    const patient = await mongoClient
      .db("medenix")
      .collection("patients")
      .findOne({ phoneNumber: phoneNumber });

    console.log("patient :: ", patient);

    if (patient) {
      console.log("Patient exists, logging in...");
      return {
        statusCode: 200,
        body: {
          response: true,
          message: "Login successful",
          userData: patient,
        },
      };
    } else {
      console.log("Patient not found, redirecting to registration...");
      return {
        statusCode: 404,
        body: {
          response: false,
          message: "Patient not found, proceed to registration",
        },
      };
    }
  } catch (error) {
    console.error("Error logging in patient ::: ", error);
    return {
      statusCode: error.statusCode || 500,
      body: {
        response: false,
        message: error.message || "Failed to log in",
        error: error.error || "LOGIN_FAILED",
      },
    };
  }
};

// Get patient details by phone number
export const getPatientDetails = async (event) => {
  try {
    console.log("Get Patient Details Event Received ::: ", event);
    mongoClient = await getMongoClient();

    const { phoneNumber } = event;

    if (!phoneNumber) {
      return {
        statusCode: 400,
        body: {
          response: false,
          message: "Mobile number is required",
        },
      };
    }

    const patient = await mongoClient
      .db("medenix")
      .collection("patients")
      .findOne({ phoneNumber });

    if (!patient) {
      return {
        statusCode: 404,
        body: {
          response: false,
          message: "Patient not found",
        },
      };
    }

    return {
      statusCode: 200,
      body: {
        response: true,
        message: "Patient details fetched successfully",
        patientData: patient,
      },
    };
  } catch (error) {
    console.error("Error fetching patient details ::: ", error);
    return {
      statusCode: 500,
      body: {
        response: false,
        message: "Failed to fetch patient details",
        error: "FETCH_FAILED",
      },
    };
  }
};

// Update patient details
export const updatePatientDetails = async (event) => {
  console.log("Update Patient Event Received ::: ", event);

  let mongoClient;
  try {
    mongoClient = await getMongoClient();
    const { patientId, doctorId, action = "add" } = event;

    if (!patientId) {
      return {
        statusCode: 400,
        body: {
          response: false,
          message: "patientId is required",
        },
      };
    }

    const patientsCollection = mongoClient.db("medenix").collection("patients");
    let updateOperation;

    if (action === "remove") {
      if (!doctorId) {
        return {
          statusCode: 400,
          body: {
            response: false,
            message: "doctorId is required for removal",
          },
        };
      }
      // Only remove the doctorId if it matches the current one
      updateOperation = {
        $unset: { doctorId: "" },
      };
    } else {
      if (!doctorId) {
        return {
          statusCode: 400,
          body: {
            response: false,
            message: "doctorId is required for adding",
          },
        };
      }
      updateOperation = {
        $set: { doctorId: doctorId },
      };
    }

    const result = await patientsCollection.updateOne(
      { patientId: patientId },
      updateOperation
    );

    if (result.matchedCount === 0) {
      return {
        statusCode: 404,
        body: {
          response: false,
          message: "Patient not found",
        },
      };
    }

    return {
      statusCode: 200,
      body: {
        response: true,
        message:
          action === "remove"
            ? "Doctor removed from patient successfully"
            : "Doctor added to patient successfully",
        updatedCount: result.modifiedCount,
      },
    };
  } catch (error) {
    console.error("Error updating patient's doctor:", error);
    return {
      statusCode: 500,
      body: {
        response: false,
        message: "Error updating patient's doctor",
        error: error.message,
      },
    };
  }
};
