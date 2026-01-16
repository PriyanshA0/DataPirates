import mongoose from "mongoose";

const goalSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true
    },

    type: {
      type: String,
      enum: ["steps", "weight", "sleep", "calories"]
    },

    targetValue: Number,
    currentValue: { type: Number, default: 0 },

    startDate: String,
    endDate: String,

    status: {
      type: String,
      enum: ["active", "completed"],
      default: "active"
    }
  },
  { timestamps: true }
);

export default mongoose.model("Goal", goalSchema);
