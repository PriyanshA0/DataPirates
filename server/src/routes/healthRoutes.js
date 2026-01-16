import express from "express";
import {
  syncDailyHealth,
  getHealthByDate,
  getHealthByRange
} from "../controllers/healthController.js";
import authMiddleware from "../middleware/authMiddleware.js";

const router = express.Router();

// 🔐 all health routes are protected
router.use(authMiddleware);

// 1️⃣ Create or Update daily health log
router.post("/sync", syncDailyHealth);

// 2️⃣ Get health log for a specific date
router.get("/day/:date", getHealthByDate);

// 3️⃣ Get health logs for date range (week / month)
router.get("/range", getHealthByRange);

export default router;
