import express from "express";
import {
  addWorkout,
  getWorkouts,
  deleteWorkout
} from "../controllers/workoutController.js";
import authMiddleware from "../middleware/authMiddleware.js";

const router = express.Router();

// 🔐 all workout routes are protected
router.use(authMiddleware);

// 1️⃣ Add workout
router.post("/", addWorkout);

// 2️⃣ Get all workouts
router.get("/", getWorkouts);

// 3️⃣ Delete workout
router.delete("/:id", deleteWorkout);

export default router;
