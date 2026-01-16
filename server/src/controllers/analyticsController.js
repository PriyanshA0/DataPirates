import DailyHealthLog from "../models/DailyHealthLog.js";
import mongoose from "mongoose";

/**
 * WEEKLY ANALYTICS
 * GET /api/analytics/weekly
 */
export const getWeeklyAnalytics = async (req, res) => {
  try {
    const userId = new mongoose.Types.ObjectId(req.user.id);

    // console.log("USER ID:", req.user.id);

    // last 7 days
    const logs = await DailyHealthLog.find({
      userId
    }).sort({ date: -1 }).limit(7);

    // console.log("LOGS:", logs);

    

    const summary = {
      totalSteps: 0,
      totalCaloriesBurned: 0,
      avgHeartRate: 0,
      avgSleep: 0
    };

    logs.forEach(log => {
      summary.totalSteps += log.steps || 0;
      summary.totalCaloriesBurned += log.caloriesBurned || 0;
      summary.avgHeartRate += log.heartRateAvg || 0;
      summary.avgSleep += log.sleep?.duration || 0;
    });

    const count = logs.length || 1;

    summary.avgHeartRate = Math.round(summary.avgHeartRate / count);
    summary.avgSleep = Number((summary.avgSleep / count).toFixed(1));

    res.status(200).json({
      summary,
      dailyData: logs.reverse()
    });
  } catch (error) {
    console.log(error.message);
    
    res.status(500).json({ message: "Server error" });
  }
};

/**
 * MONTHLY ANALYTICS
 * GET /api/analytics/monthly
 */
export const getMonthlyAnalytics = async (req, res) => {
  try {
    const userId = new mongoose.Types.ObjectId(req.user.id);

    // last 30 days
    const logs = await DailyHealthLog.find({
      userId
    }).sort({ date: -1 }).limit(30);

    const summary = {
      totalSteps: 0,
      totalCaloriesBurned: 0,
      avgHeartRate: 0,
      avgSleep: 0
    };

    logs.forEach(log => {
      summary.totalSteps += log.steps || 0;
      summary.totalCaloriesBurned += log.caloriesBurned || 0;
      summary.avgHeartRate += log.heartRateAvg || 0;
      summary.avgSleep += log.sleep?.duration || 0;
    });

    const count = logs.length || 1;

    summary.avgHeartRate = Math.round(summary.avgHeartRate / count);
    summary.avgSleep = Number((summary.avgSleep / count).toFixed(1));

    res.status(200).json({
      summary,
      dailyData: logs.reverse()
    });
  } catch (error) {
    res.status(500).json({ message: "Server error" });
  }
};
