import express from "express"
import dotenv from "dotenv"
import cors from "cors"
import cookieParser from "cookie-parser";

// Load environment variables FIRST before any other imports
dotenv.config();

import connectDB from "./config/db.js";
import authRoutes from "./routes/authRoutes.js"
import healthRoutes from "./routes/healthRoutes.js"
import workoutRoutes from "./routes/workoutRoutes.js"
import goalRoutes from "./routes/goalRoutes.js"
import notificationRoutes from "./routes/notificationRoutes.js";
import medicalRoutes from "./routes/medicalRoutes.js";
import analyticsRoutes from "./routes/analyticsRoutes.js";
import gamificationRoutes from "./routes/gamificationRoutes.js";
import stravaRoutes from "./routes/stravaRoutes.js";
import aiRoutes from "./routes/aiRoutes.js";
import historyRoutes from "./routes/historyRoutes.js";

const app = express();
const PORT = process.env.PORT || 4000;

app.use(cors({
  origin: "*", // hackathon safe
}));
app.use(cookieParser());
app.use(express.json());

connectDB();

app.get("/", (req, res) => {res.send("Hi there this is the / route of datapirates")})

app.use("/api/auth", authRoutes);

app.use("/api/health", healthRoutes);

app.use("/api/workouts", workoutRoutes);

app.use("/api/goals", goalRoutes);

app.use("/api/notifications", notificationRoutes);

app.use("/api/medical", medicalRoutes);

app.use("/api/analytics", analyticsRoutes);

app.use("/api/gamification", gamificationRoutes);

app.use("/api/strava", stravaRoutes);

app.use("/api/ai", aiRoutes);

app.use("/api/history", historyRoutes);




// app.use('/api/v1/health', healthRoutes);

app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
})