import express from "express";
import {
  getNotifications,
  markAsRead
} from "../controllers/notificationController.js";
import authMiddleware from "../middleware/authMiddleware.js";

const router = express.Router();

// 🔐 protected routes
router.use(authMiddleware);

// 1️⃣ Get all notifications
router.get("/", getNotifications);

// 2️⃣ Mark notification as read
router.put("/:id/read", markAsRead);

export default router;
