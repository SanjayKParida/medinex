import express from "express";
import { body, validationResult } from "express-validator";
import {
  registerDoctor,
  loginDoctor,
  setDoctorPassword,
  getDoctorDetails,
  getVerifiedDoctors,
  getDoctorPatients,
  updateDoctorDetails,
} from "../controllers/doctorController.js";

const router = express.Router();

// Validation middleware
const validateRequest = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      response: false,
      message: "Validation failed",
      errors: errors.array(),
    });
  }
  next();
};

// Register doctor
router.post(
  "/register",
  [
    body("name").notEmpty().withMessage("Name is required"),
    body("mobileNumber")
      .isMobilePhone("any")
      .withMessage("Valid mobile number is required"),
    body("email").isEmail().withMessage("Valid email is required"),
    body("password")
      .isLength({ min: 6 })
      .withMessage("Password must be at least 6 characters"),
  ],
  validateRequest,
  async (req, res) => {
    try {
      const result = await registerDoctor(req.body);
      res.status(result.statusCode).json(result.body);
    } catch (error) {
      console.error("Doctor registration error:", error);
      res.status(500).json({
        response: false,
        message: "Failed to register doctor",
        error: error.message,
      });
    }
  }
);

// Login doctor
router.post(
  "/login",
  [
    body("doctorId").notEmpty().withMessage("Doctor ID is required"),
    body("password").notEmpty().withMessage("Password is required"),
  ],
  validateRequest,
  async (req, res) => {
    try {
      const result = await loginDoctor(req.body);
      res.status(result.statusCode).json(result.body);
    } catch (error) {
      console.error("Doctor login error:", error);
      res.status(500).json({
        response: false,
        message: "Failed to login doctor",
        error: error.message,
      });
    }
  }
);

// Set doctor password
router.post(
  "/set-password",
  [
    body("doctorLoginId").notEmpty().withMessage("Doctor login ID is required"),
    body("password")
      .isLength({ min: 6 })
      .withMessage("Password must be at least 6 characters"),
  ],
  validateRequest,
  async (req, res) => {
    try {
      const result = await setDoctorPassword(req.body);
      res.status(result.statusCode).json(result.body);
    } catch (error) {
      console.error("Set password error:", error);
      res.status(500).json({
        response: false,
        message: "Failed to set password",
        error: error.message,
      });
    }
  }
);

// Get doctor details by login ID
router.get("/details/:doctorId", async (req, res) => {
  try {
    const result = await getDoctorDetails({ doctorId: req.params.doctorId });
    res.status(result.statusCode).json(result.body);
  } catch (error) {
    console.error("Get doctor details error:", error);
    res.status(500).json({
      response: false,
      message: "Failed to get doctor details",
      error: error.message,
    });
  }
});

// Get verified doctors
router.get("/verified", async (req, res) => {
  try {
    const result = await getVerifiedDoctors();
    res.status(result.statusCode).json(result.body);
  } catch (error) {
    console.error("Get verified doctors error:", error);
    res.status(500).json({
      response: false,
      message: "Failed to get verified doctors",
      error: error.message,
    });
  }
});

// Get doctor's patients
router.get("/:doctorId/patients", async (req, res) => {
  try {
    const result = await getDoctorPatients({ doctorId: req.params.doctorId });
    res.status(result.statusCode).json(result.body);
  } catch (error) {
    console.error("Get doctor patients error:", error);
    res.status(500).json({
      response: false,
      message: "Failed to get doctor patients",
      error: error.message,
    });
  }
});

// Update doctor details
router.put(
  "/update",
  [body("doctorId").notEmpty().withMessage("Doctor ID is required")],
  validateRequest,
  async (req, res) => {
    try {
      const result = await updateDoctorDetails(req.body);
      res.status(result.statusCode).json(result.body);
    } catch (error) {
      console.error("Update doctor error:", error);
      res.status(500).json({
        response: false,
        message: "Failed to update doctor",
        error: error.message,
      });
    }
  }
);

export default router;
