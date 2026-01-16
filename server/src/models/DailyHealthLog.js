import mongoose from "mongoose";

const dailyHealthLogSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true
    },

    date: {
      type: String, // YYYY-MM-DD
      required: true
    },

    steps: { type: Number, default: 0 },
    distance: { type: Number, default: 0 }, // km
    caloriesBurned: { type: Number, default: 0 },
    heartRateAvg: Number,

    sleep: {
      duration: Number, // hours
      quality: { type: String, enum: ["poor", "average", "good"] }
    },

    nutrition: {
      caloriesConsumed: Number,
      waterIntake: Number // liters
    },

    mood: {
      moodLevel: { type: Number, min: 1, max: 5 },
      stressLevel: { type: Number, min: 1, max: 5 }
    },

    source: {
      type: String,
      enum: ["google_fit", "manual"],
      default: "manual"
    }
  },
  { timestamps: true }
);

// Prevent duplicate logs per user per day
dailyHealthLogSchema.index({ userId: 1, date: 1 }, { unique: true });

export default mongoose.model("DailyHealthLog", dailyHealthLogSchema);
