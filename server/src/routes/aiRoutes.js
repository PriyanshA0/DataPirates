import express from "express";
import { getAISummary } from "../controllers/aiController.js";
import authMiddleware from "../middleware/authMiddleware.js";

const router = express.Router();

router.get("/summary", authMiddleware, getAISummary);

export default router;
