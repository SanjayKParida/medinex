import express from "express";
import { body, validationResult } from "express-validator";
import { logSymptoms, getHealthLogs } from "../controllers/healthController.js";

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

// Log symptoms
router.post(
  "/log-symptoms",
  [
    body("currentSymptoms")
      .notEmpty()
      .withMessage("Current symptoms are required"),
    body("patientId").notEmpty().withMessage("Patient ID is required"),
  ],
  validateRequest,
  async (req, res) => {
    try {
      const result = await logSymptoms(req.body);
      res.status(result.statusCode).json(result.body);
    } catch (error) {
      console.error("Log symptoms error:", error);
      res.status(500).json({
        response: false,
        message: "Failed to log symptoms",
        error: error.message,
      });
    }
  }
);

// Get health logs by patient ID
router.get("/logs/:patientId", async (req, res) => {
  try {
    const result = await getHealthLogs({ patientId: req.params.patientId });
    res.status(result.statusCode).json(result.body);
  } catch (error) {
    console.error("Get health logs error:", error);
    res.status(500).json({
      response: false,
      message: "Failed to get health logs",
      error: error.message,
    });
  }
});

export default router;
