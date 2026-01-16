import axios from "axios";
import User from "../models/User.js";

export const ensureValidStravaToken = async (user) => {
  const now = Math.floor(Date.now() / 1000);

  // Token still valid → use it
  if (user.strava.expiresAt > now) {
    return user.strava.accessToken;
  }

  // 🔄 Refresh token
  const response = await axios.post(
    "https://www.strava.com/oauth/token",
    {
      client_id: process.env.STRAVA_CLIENT_ID,
      client_secret: process.env.STRAVA_CLIENT_SECRET,
      grant_type: "refresh_token",
      refresh_token: user.strava.refreshToken,
    }
  );

  const { access_token, refresh_token, expires_at } = response.data;

  // Save new tokens
  user.strava.accessToken = access_token;
  user.strava.refreshToken = refresh_token;
  user.strava.expiresAt = expires_at;
  await user.save();

  return access_token;
};
