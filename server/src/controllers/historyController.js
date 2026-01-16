import DailyHealthLog from "../models/DailyHealthLog.js";
import Activity from "../models/Activity.js";

export const getHealthHistory = async (req, res) => {
  try {
    const userId = req.user.id;
    const days = Number(req.query.days || 30);

    // 1️⃣ Fetch daily logs
    const logs = await DailyHealthLog.find({ userId })
      .sort({ date: -1 })
      .limit(days)
      .lean();

    // 2️⃣ Fetch activities for same period
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);

    const activities = await Activity.find({
      userId,
      startTime: { $gte: startDate }
    }).lean();

    // 3️⃣ Group activities by date
    const activityMap = {};
    activities.forEach(act => {
      const date = act.startTime.toISOString().split("T")[0];
      if (!activityMap[date]) activityMap[date] = [];
      activityMap[date].push({
        type: act.type,
        durationMin: act.durationMin,
        calories: act.calories || 0
      });
    });

    // 4️⃣ Merge logs + activities
    const history = logs.map(log => ({
      date: log.date,
      steps: log.steps || 0,
      distance: Number((log.distance || 0) / 1000).toFixed(2), // km
      calories: log.caloriesBurned || 0,
      activities: activityMap[log.date] || []
    }));

    res.json({ history });

  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Failed to fetch history" });
  }
};
