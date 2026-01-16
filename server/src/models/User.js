// User profile, goals, badge array

import mongoose from "mongoose";

const userSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },

    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true
    },

    strava: {
      accessToken: String,
      refreshToken: String,
      expiresAt: Number
    },


    password: { type: String, required: true },

    age: Number,
    gender: { type: String, enum: ["male", "female", "other"] },

    height: Number, // cm
    weight: Number, // kg

    role: { type: String, default: "user" }
  },
  { timestamps: true }
);

export default mongoose.model("User", userSchema);
