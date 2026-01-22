import express from "express";
import { analyzeFoodImage, logFoodEntry } from "../controllers/foodController.js";
import authMiddleware from "../middleware/authMiddleware.js";

const router = express.Router();

// Analyze food image and get calorie/nutrition info
router.post("/analyze", authMiddleware, analyzeFoodImage);

// Log food entry to daily health log
router.post("/log", authMiddleware, logFoodEntry);

export default router;
