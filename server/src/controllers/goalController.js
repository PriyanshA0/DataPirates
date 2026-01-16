import Goal from "../models/Goal.js";

/**
 * 1️⃣ CREATE GOAL
 * POST /api/goals
 */
export const createGoal = async (req, res) => {
  try {
    const userId = req.user.id;
    const { type, targetValue, startDate, endDate } = req.body;

    if (!type || !targetValue) {
      return res.status(400).json({ message: "Type and target value required" });
    }

    const goal = await Goal.create({
      userId,
      type,
      targetValue,
      startDate,
      endDate
    });

    res.status(201).json({
      message: "Goal created successfully",
      data: goal
    });
  } catch (error) {
    console.log(error.message);
    res.status(500).json({ message: "Server error" });
  }
};

/**
 * 2️⃣ GET ALL GOALS
 * GET /api/goals
 */
export const getGoals = async (req, res) => {
  try {
    const userId = req.user.id;

    const goals = await Goal.find({ userId }).sort({ createdAt: -1 });

    res.status(200).json(goals);
  } catch (error) {
    res.status(500).json({ message: "Server error" });
  }
};

/**
 * 3️⃣ UPDATE GOAL
 * PUT /api/goals/:id
 */
export const updateGoal = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;
    const updates = req.body;

    const goal = await Goal.findOneAndUpdate(
      { _id: id, userId },
      updates,
      { new: true }
    );

    if (!goal) {
      return res.status(404).json({ message: "Goal not found" });
    }

    res.status(200).json({
      message: "Goal updated successfully",
      data: goal
    });
  } catch (error) {
    res.status(500).json({ message: "Server error" });
  }
};

/**
 * 4️⃣ DELETE GOAL
 * DELETE /api/goals/:id
 */
export const deleteGoal = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    const goal = await Goal.findOneAndDelete({ _id: id, userId });

    if (!goal) {
      return res.status(404).json({ message: "Goal not found" });
    }

    res.status(200).json({
      message: "Goal deleted successfully"
    });
  } catch (error) {
    res.status(500).json({ message: "Server error" });
  }
};
