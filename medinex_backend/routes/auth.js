import express from "express";
import { body, validationResult } from "express-validator";
import { sendOtp, verifyOtp } from "../controllers/authController.js";

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

// Send OTP
router.post(
  "/send-otp",
  [
    body("phoneNumber")
      .isMobilePhone("any")
      .withMessage("Please provide a valid phone number"),
  ],
  validateRequest,
  async (req, res) => {
    try {
      const result = await sendOtp(req.body);
      res.status(result.statusCode).json(result.body);
    } catch (error) {
      console.error("Send OTP error:", error);
      res.status(500).json({
        response: false,
        message: "Failed to send OTP",
        error: error.message,
      });
    }
  }
);

// Verify OTP
router.post(
  "/verify-otp",
  [
    body("phoneNumber")
      .isMobilePhone("any")
      .withMessage("Please provide a valid phone number"),
    body("otp")
      .isLength({ min: 4, max: 4 })
      .isNumeric()
      .withMessage("OTP must be 4 digits"),
  ],
  validateRequest,
  async (req, res) => {
    try {
      const result = await verifyOtp(req.body);
      res.status(result.statusCode).json(result.body);
    } catch (error) {
      console.error("Verify OTP error:", error);
      res.status(500).json({
        response: false,
        message: "Failed to verify OTP",
        error: error.message,
      });
    }
  }
);

export default router;
