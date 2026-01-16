import MedicalProfile from "../models/MedicalProfile.js";

/**
 * 1️⃣ GET MEDICAL PROFILE
 * GET /api/medical
 */
export const getMedicalProfile = async (req, res) => {
  try {
    const userId = req.user.id;

    const profile = await MedicalProfile.findOne({ userId });

    if (!profile) {
      return res.status(200).json(null); // clean UX
    }

    res.status(200).json(profile);
  } catch (error) {
    res.status(500).json({ message: "Server error" });
  }
};

/**
 * 2️⃣ CREATE or UPDATE MEDICAL PROFILE (UPSERT)
 * POST /api/medical
 */
export const upsertMedicalProfile = async (req, res) => {
  try {
    const userId = req.user.id;
    const data = req.body;

    const profile = await MedicalProfile.findOneAndUpdate(
      { userId },
      { $set: { ...data, userId } },
      { new: true, upsert: true }
    );

    res.status(200).json({
      message: "Medical profile saved successfully",
      data: profile
    });
  } catch (error) {
    res.status(500).json({ message: "Server error" });
  }
};
