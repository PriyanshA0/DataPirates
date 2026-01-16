import express from "express"
import dotenv from "dotenv"
import cors from "cors"
import cookieParser from "cookie-parser";


import connectDB from "./config/db.js";
import authRoutes from "./routes/authRoutes.js"
import healthRoutes from "./routes/healthRoutes.js"

dotenv.config();
const app = express();
const PORT = process.env.PORT || 4000;

app.use(cors({
  origin: "http://localhost:3000",
  credentials: true
}));
app.use(cookieParser());
app.use(express.json());

connectDB();

app.get("/", (req, res) => {res.send("Hi there this is the / route of datapirates")})

app.use("/api/auth", authRoutes);

app.use("/api/health", healthRoutes);


// app.use('/api/v1/health', healthRoutes);

app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
})