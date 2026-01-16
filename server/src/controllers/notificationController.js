import Notification from "../models/Notification.js";

/**
 * 1️⃣ GET ALL NOTIFICATIONS
 * GET /api/notifications
 */
export const getNotifications = async (req, res) => {
  try {
    const userId = req.user.id;

    const notifications = await Notification.find({ userId })
      .sort({ createdAt: -1 });

    res.status(200).json(notifications);
  } catch (error) {
    res.status(500).json({ message: "Server error" });
  }
};

/**
 * 2️⃣ MARK AS READ
 * PUT /api/notifications/:id/read
 */
export const markAsRead = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    const notification = await Notification.findOneAndUpdate(
      { _id: id, userId },
      { isRead: true },
      { new: true }
    );

    if (!notification) {
      return res.status(404).json({ message: "Notification not found" });
    }

    res.status(200).json({
      message: "Notification marked as read",
      data: notification
    });
  } catch (error) {
    res.status(500).json({ message: "Server error" });
  }
};
