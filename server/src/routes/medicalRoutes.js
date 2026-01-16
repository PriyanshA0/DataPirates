import express from "express";
import {
  getMedicalProfile,
  upsertMedicalProfile
} from "../controllers/medicalController.js";
import authMiddleware from "../middleware/authMiddleware.js";

const router = express.Router();

// 🔐 protected
router.use(authMiddleware);

// 1️⃣ Get medical profile
router.get("/", getMedicalProfile);

// 2️⃣ Create or update medical profile
router.post("/", upsertMedicalProfile);

export default router;
