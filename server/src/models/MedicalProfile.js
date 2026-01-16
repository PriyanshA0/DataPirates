import mongoose from "mongoose";

const medicalProfileSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      unique: true,
      required: true
    },

    conditions: [String],

    medications: [
      {
        name: String,
        dosage: String,
        timing: String
      }
    ],

    vaccinations: [
      {
        name: String,
        date: String
      }
    ],

    reports: [
      {
        title: String,
        fileUrl: String,
        uploadedAt: Date
      }
    ]
  },
  { timestamps: true }
);

export default mongoose.model("MedicalProfile", medicalProfileSchema);
