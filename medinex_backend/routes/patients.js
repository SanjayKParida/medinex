import express from "express";
import { body, validationResult } from "express-validator";
import {
  registerPatient,
  loginPatient,
  getPatientDetails,
  updatePatientDetails,
} from "../controllers/patientController.js";

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

// Register patient
router.post(
  "/register",
  [
    body("name").notEmpty().withMessage("Name is required"),
    body("phoneNumber")
      .isMobilePhone("any")
      .withMessage("Valid phone number is required"),
    body("gender")
      .isIn(["male", "female", "other"])
      .withMessage("Valid gender is required"),
    body("dob").isISO8601().withMessage("Valid date of birth is required"),
  ],
  validateRequest,
  async (req, res) => {
    try {
      const result = await registerPatient(req.body);
      res.status(result.statusCode).json(result.body);
    } catch (error) {
      console.error("Patient registration error:", error);
      res.status(500).json({
        response: false,
        message: "Failed to register patient",
        error: error.message,
      });
    }
  }
);

// Login patient
router.post(
  "/login",
  [
    body("phoneNumber")
      .isMobilePhone("any")
      .withMessage("Valid phone number is required"),
  ],
  validateRequest,
  async (req, res) => {
    try {
      const result = await loginPatient(req.body);
      res.status(result.statusCode).json(result.body);
    } catch (error) {
      console.error("Patient login error:", error);
      res.status(500).json({
        response: false,
        message: "Failed to login patient",
        error: error.message,
      });
    }
  }
);

// Get patient details by phone number
router.get("/details/:phoneNumber", async (req, res) => {
  try {
    const result = await getPatientDetails({
      phoneNumber: req.params.phoneNumber,
    });
    res.status(result.statusCode).json(result.body);
  } catch (error) {
    console.error("Get patient details error:", error);
    res.status(500).json({
      response: false,
      message: "Failed to get patient details",
      error: error.message,
    });
  }
});

// Update patient details
router.put(
  "/update",
  [body("patientId").notEmpty().withMessage("Patient ID is required")],
  validateRequest,
  async (req, res) => {
    try {
      const result = await updatePatientDetails(req.body);
      res.status(result.statusCode).json(result.body);
    } catch (error) {
      console.error("Update patient error:", error);
      res.status(500).json({
        response: false,
        message: "Failed to update patient",
        error: error.message,
      });
    }
  }
);

export default router;
