import express from "express";
import { body, validationResult } from "express-validator";
import {
  createAppointment,
  getAppointmentsByPatientId,
  getAppointmentsByDoctorId,
  cancelAppointment,
  getAvailableSlots,
} from "../controllers/appointmentController.js";

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

// Create appointment
router.post(
  "/create",
  [
    body("patientId").notEmpty().withMessage("Patient ID is required"),
    body("doctorId").notEmpty().withMessage("Doctor ID is required"),
    body("date").isISO8601().withMessage("Valid date is required"),
    body("time")
      .matches(/^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/)
      .withMessage("Valid time format (HH:mm) is required"),
    body("reason").notEmpty().withMessage("Reason is required"),
  ],
  validateRequest,
  async (req, res) => {
    try {
      const result = await createAppointment(req.body);
      res.status(result.statusCode).json(result.body);
    } catch (error) {
      console.error("Create appointment error:", error);
      res.status(500).json({
        response: false,
        message: "Failed to create appointment",
        error: error.message,
      });
    }
  }
);

// Get appointments by patient ID
router.get("/patient/:patientId", async (req, res) => {
  try {
    const result = await getAppointmentsByPatientId({
      patientId: req.params.patientId,
    });
    res.status(result.statusCode).json(result.body);
  } catch (error) {
    console.error("Get patient appointments error:", error);
    res.status(500).json({
      response: false,
      message: "Failed to get patient appointments",
      error: error.message,
    });
  }
});

// Get appointments by doctor ID
router.get("/doctor/:doctorId", async (req, res) => {
  try {
    const result = await getAppointmentsByDoctorId({
      doctorId: req.params.doctorId,
    });
    res.status(result.statusCode).json(result.body);
  } catch (error) {
    console.error("Get doctor appointments error:", error);
    res.status(500).json({
      response: false,
      message: "Failed to get doctor appointments",
      error: error.message,
    });
  }
});

// Cancel appointment
router.put(
  "/cancel",
  [
    body("appointmentId").notEmpty().withMessage("Appointment ID is required"),
    body("reason").notEmpty().withMessage("Cancellation reason is required"),
    body("cancelledBy")
      .notEmpty()
      .withMessage("Cancelled by field is required"),
  ],
  validateRequest,
  async (req, res) => {
    try {
      const result = await cancelAppointment(req.body);
      res.status(result.statusCode).json(result.body);
    } catch (error) {
      console.error("Cancel appointment error:", error);
      res.status(500).json({
        response: false,
        message: "Failed to cancel appointment",
        error: error.message,
      });
    }
  }
);

// Get available slots for a doctor on a specific date
router.get("/slots/:doctorId/:date", async (req, res) => {
  try {
    const result = await getAvailableSlots({
      doctorId: req.params.doctorId,
      date: req.params.date,
    });
    res.status(result.statusCode).json(result.body);
  } catch (error) {
    console.error("Get available slots error:", error);
    res.status(500).json({
      response: false,
      message: "Failed to get available slots",
      error: error.message,
    });
  }
});

export default router;
