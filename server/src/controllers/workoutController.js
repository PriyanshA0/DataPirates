import Workout from "../models/Workout.js";

/**
 * 1️⃣ ADD WORKOUT
 * POST /api/workouts
 */
export const addWorkout = async (req, res) => {
  try {
    const userId = req.user.id;
    const { type, duration, caloriesBurned, date, source } = req.body;

    if (!type || !date) {
      return res.status(400).json({ message: "Type and date are required" });
    }

    const workout = await Workout.create({
      userId,
      type,
      duration,
      caloriesBurned,
      date,
      source
    });

    res.status(201).json({
      message: "Workout added successfully",
      data: workout
    });
  } catch (error) {
    console.error(error.message);
    res.status(500).json({ message: "Server error" });
  }
};

/**
 * 2️⃣ GET ALL WORKOUTS
 * GET /api/workouts
 */
export const getWorkouts = async (req, res) => {
  try {
    const userId = req.user.id;

    const workouts = await Workout.find({ userId }).sort({ date: -1 });

    res.status(200).json(workouts);
  } catch (error) {
    res.status(500).json({ message: "Server error" });
  }
};

/**
 * 3️⃣ DELETE WORKOUT
 * DELETE /api/workouts/:id
 */
export const deleteWorkout = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    const workout = await Workout.findOneAndDelete({
      _id: id,
      userId
    });

    if (!workout) {
      return res.status(404).json({ message: "Workout not found" });
    }

    res.status(200).json({
      message: "Workout deleted successfully"
    });
  } catch (error) {
    res.status(500).json({ message: "Server error" });
  }
};

