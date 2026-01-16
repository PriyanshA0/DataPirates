import express from "express";
import {
  getWeeklyAnalytics,
  getMonthlyAnalytics
} from "../controllers/analyticsController.js";
import authMiddleware from "../middleware/authMiddleware.js";

const router = express.Router();

// 🔐 protected
router.use(authMiddleware);

// Weekly analytics
router.get("/weekly", getWeeklyAnalytics);

// Monthly analytics
router.get("/monthly", getMonthlyAnalytics);

export default router;
