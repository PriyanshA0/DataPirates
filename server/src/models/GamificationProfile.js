import mongoose from "mongoose";

const gamificationProfileSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      unique: true,
      required: true
    },

    points: { type: Number, default: 0 },
    level: { type: Number, default: 1 },

    badges: [String],
    challengesJoined: [String]
  },
  { timestamps: true }
);

export default mongoose.model(
  "GamificationProfile",
  gamificationProfileSchema
);
