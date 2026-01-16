import express from "express";
import {
  createGoal,
  getGoals,
  updateGoal,
  deleteGoal
} from "../controllers/goalController.js";
import authMiddleware from "../middleware/authMiddleware.js";

const router = express.Router();

// 🔐 all goal routes are protected
router.use(authMiddleware);

// 1️⃣ Create goal
router.post("/", createGoal);

// 2️⃣ Get all goals
router.get("/", getGoals);

// 3️⃣ Update goal (progress / status)
router.put("/:id", updateGoal);

// 4️⃣ Delete goal
router.delete("/:id", deleteGoal);

export default router;
