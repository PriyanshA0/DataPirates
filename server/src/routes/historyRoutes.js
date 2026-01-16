import express from "express";
import { getHealthHistory } from "../controllers/historyController.js";
import authMiddleware from "../middleware/authMiddleware.js";

const router = express.Router();

router.get("/", authMiddleware, getHealthHistory);

export default router;
