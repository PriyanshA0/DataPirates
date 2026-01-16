import express from "express"
import dotenv from "dotenv"
import cors from "cors"
import connectDB from "./config/db.js";

dotenv.config();
const app = express();
const PORT = process.env.PORT || 4000;

app.use(cors());
app.use(express.json());

connectDB();

app.get("/", (req, res) => {res.send("Hi there this is the / route of datapirates")})


// app.use("/api/launches", launchRoutes);

app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
})