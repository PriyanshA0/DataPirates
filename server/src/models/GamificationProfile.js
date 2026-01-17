import mongoose from "mongoose";

// const gamificationProfileSchema = new mongoose.Schema(
//   {
//     userId: {
//       type: mongoose.Schema.Types.ObjectId,
//       ref: "User",
//       required: true,
//       unique: true
//     },

//     points: {
//       type: Number,
//       default: 0
//     },

//     dailyPoints: {
//       type: Number,
//       default: 0
//     },

//     level: {
//       type: Number,
//       default: 1
//     },

//     badges: {
//       type: [String],
//       default: []
//     },

//     lastUpdatedDate: {
//       type: String // YYYY-MM-DD
//     }
//   },
//   { timestamps: true }
// );

const gamificationProfileSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", unique: true },

  points: { type: Number, default: 0 },        // lifetime points
  dailyPoints: { type: Number, default: 0 },   // today only
  lastUpdatedDate: { type: String },           

  level: { type: Number, default: 1 },
  badges: [String]
}, { timestamps: true });
export default mongoose.model("GamificationProfile", gamificationProfileSchema);
