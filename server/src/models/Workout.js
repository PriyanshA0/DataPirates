import mongoose from "mongoose";

const workoutSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true
    },

    type: { type: String, required: true }, // running, gym, yoga
    duration: Number, // minutes
    caloriesBurned: Number,

    date: { type: String }, // YYYY-MM-DD
    source: { type: String, enum: ["google_fit", "manual"] }
  },
  { timestamps: true }
);

export default mongoose.model("Workout", workoutSchema);
