import express from "express";
import authMiddleware from "../middleware/authMiddleware.js";
import {
  connectStrava,
  stravaCallback,
  syncStravaActivities
} from "../controllers/stravaController.js";

const router = express.Router();

// 🚀 PUBLIC ROUTES (NO AUTH)
router.get("/connect", authMiddleware, connectStrava);
router.get("/callback",authMiddleware, stravaCallback);

// 🔐 PROTECTED ROUTE
router.get("/sync", authMiddleware, syncStravaActivities);

export default router;
