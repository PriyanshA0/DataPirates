import DailyHealthLog from "../models/DailyHealthLog.js";

/**
 * 1️⃣ CREATE or UPDATE daily health log
 * POST /api/health/sync
 */
export const syncDailyHealth = async (req, res) => {
  try {
    const userId = req.user.id;
    const { date, ...healthData } = req.body;

    if (!date) {
      return res.status(400).json({ message: "Date is required" });
    }

    const log = await DailyHealthLog.findOneAndUpdate(
      { userId, date },
      {
        $set: {
          ...healthData,
          userId,
          date
        }
      },
      {
        new: true,
        upsert: true
      }
    );

    res.status(200).json({
      message: "Daily health synced successfully",
      data: log
    });
  } catch (error) {
    console.error(error.message);
    res.status(500).json({ message: "Server error" });
  }
};

/**
 * 2️⃣ GET health log by date
 * GET /api/health/day/:date
 */
export const getHealthByDate = async (req, res) => {
  try {
    const userId = req.user.id;
    const { date } = req.params;

    const log = await DailyHealthLog.findOne({ userId, date });

    if (!log) {
      return res.status(404).json({ message: "No health data found" });
    }

    res.status(200).json(log);
  } catch (error) {
    res.status(500).json({ message: "Server error" });
  }
};

/**
 * 3️⃣ GET health logs by date range
 * GET /api/health/range?start=YYYY-MM-DD&end=YYYY-MM-DD
 */
export const getHealthByRange = async (req, res) => {
  try {
    const userId = req.user.id;
    const { start, end } = req.query;

    if (!start || !end) {
      return res.status(400).json({ message: "Start and end dates required" });
    }

    const logs = await DailyHealthLog.find({
      userId,
      date: { $gte: start, $lte: end }
    }).sort({ date: 1 });

    res.status(200).json(logs);
  } catch (error) {
    res.status(500).json({ message: "Server error" });
  }
};
