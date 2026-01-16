import GamificationProfile from "../models/GamificationProfile.js";
import DailyHealthLog from "../models/DailyHealthLog.js";

export const getGamificationProfile = async (req, res) => {
  try {
    const userId = req.user.id;

    let profile = await GamificationProfile.findOne({ userId });
    if (!profile) {
      profile = await GamificationProfile.create({ userId });
    }

    res.json(profile);
  } catch (err) {
    res.status(500).json({ message: "Failed to fetch gamification profile" });
  }
};

export const syncGamification = async (req, res) => {
  try {
    const userId = req.user.id;
    const today = new Date().toISOString().split("T")[0];

    let profile = await GamificationProfile.findOne({ userId });
    if (!profile) {
      profile = await GamificationProfile.create({ userId });
    }

    const todayLog = await DailyHealthLog.findOne({ userId, date: today });
    if (!todayLog) {
      return res.json({ message: "No health activity today" });
    }

    let pointsToAdd = 0;

    // 1️⃣ Daily sync bonus
    pointsToAdd += 10;

    // 2️⃣ Steps bonus
    if (todayLog.steps >= 8000) {
      pointsToAdd += 20;
    }

    // 3️⃣ 7‑day activity streak
    const last7Logs = await DailyHealthLog.find({
      userId,
      date: { $lte: today }
    })
      .sort({ date: -1 })
      .limit(7);

    if (last7Logs.length === 7) {
      pointsToAdd += 50;
    }

    profile.points += pointsToAdd;
    profile.level = Math.floor(profile.points / 100) + 1;

    await profile.save();

    res.json({
      message: "Gamification synced",
      pointsAdded: pointsToAdd,
      profile
    });
  } catch (err) {
    res.status(500).json({ message: "Gamification sync failed" });
  }
};

export const resetGamification = async (req, res) => {
  try {
    const userId = req.user.id;

    await GamificationProfile.findOneAndUpdate(
      { userId },
      { points: 0, level: 1, badges: [] }
    );

    res.json({ message: "Gamification reset" });
  } catch (err) {
    res.status(500).json({ message: "Reset failed" });
  }
};
