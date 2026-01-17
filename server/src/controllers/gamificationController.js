import GamificationProfile from "../models/GamificationProfile.js";
import DailyHealthLog from "../models/DailyHealthLog.js";

/**
 * GET PROFILE
 */
export const getGamificationProfile = async (req, res) => {
  try {
    const userId = req.user.id;

    let profile = await GamificationProfile.findOne({ userId });

    if (!profile) {
      profile = await GamificationProfile.create({
        userId,
        lastUpdatedDate: new Date().toISOString().split("T")[0]
      });
    }

    res.json(profile);
  } catch (err) {
    res.status(500).json({ message: "Failed to fetch gamification profile" });
  }
};

/**
 * SYNC DAILY POINTS
 */
export const syncGamification = async (req, res) => {
  try {
    const userId = req.user.id;
    const today = new Date().toISOString().split("T")[0];

    let profile = await GamificationProfile.findOne({ userId });

    if (!profile) {
      profile = await GamificationProfile.create({
        userId,
        lastUpdatedDate: today
      });
    }

    // 🔄 Reset daily points if new day
    if (profile.lastUpdatedDate !== today) {
      profile.dailyPoints = 0;
      profile.lastUpdatedDate = today;
    }

    const todayLog = await DailyHealthLog.findOne({ userId, date: today });
    if (!todayLog) {
      return res.json({ message: "No activity today" });
    }

    let points = 0;

    // 🟢 Base
    points += 10;

    // 🚶 Steps
    if (todayLog.steps >= 8000) points += 20;
    if (todayLog.steps >= 12000) points += 10;

    // 🔥 Calories
    if (todayLog.caloriesBurned >= 400) points += 20;

    // 😴 Sleep
    if (todayLog.sleep?.duration >= 7) points += 20;

    profile.dailyPoints += points;
    profile.points += points;
    profile.level = Math.floor(profile.points / 100) + 1;

    await profile.save();

    res.json({
      message: "Gamification synced",
      dailyPoints: profile.dailyPoints,
      totalPoints: profile.points,
      level: profile.level
    });
  } catch (err) {
    res.status(500).json({ message: "Gamification sync failed" });
  }
};

/**
 * TODAY LEADERBOARD (FIXED)
 */
export const getTodayLeaderboard = async (req, res) => {
  try {
    const leaderboard = await GamificationProfile.find({
      dailyPoints: { $gt: 0 }
    })
      .populate("userId", "name email")
      .sort({ dailyPoints: -1 })
      .limit(10);

    res.json(leaderboard);
  } catch (err) {
    res.status(500).json({ message: "Failed to fetch leaderboard" });
  }
};

/**
 * RESET
 */
export const resetGamification = async (req, res) => {
  try {
    const userId = req.user.id;

    await GamificationProfile.findOneAndUpdate(
      { userId },
      { points: 0, dailyPoints: 0, level: 1, badges: [] }
    );

    res.json({ message: "Gamification reset" });
  } catch (err) {
    res.status(500).json({ message: "Reset failed" });
  }
};
