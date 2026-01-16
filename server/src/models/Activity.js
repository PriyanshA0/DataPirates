import mongoose from "mongoose";

const activitySchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true
    },

    source: {
      type: String,
      enum: ["strava", "manual"],
      required: true
    },

    // Strava specific
    stravaActivityId: {
      type: Number,
      index: true
    },

    type: {
      type: String, // Yoga, Run, Walk, Ride
      required: true
    },

    durationMin: Number,

    distanceKm: Number,
    steps: Number,

    avgHeartRate: Number,
    maxHeartRate: Number,

    caloriesBurned: Number,

    startTime: Date,

    raw: {
      type: Object // optional: store raw Strava payload for demo/debug
    }
  },
  { timestamps: true }
);

export default mongoose.model("Activity", activitySchema);
