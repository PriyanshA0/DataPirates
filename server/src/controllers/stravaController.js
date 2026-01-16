import axios from "axios";
import User from "../models/User.js";
import Workout from "../models/Workout.js";
import DailyHealthLog from "../models/DailyHealthLog.js";
import Activity from "../models/Activity.js";
import { ensureValidStravaToken } from "../utils/refreshStravaToken.js";


export const connectStrava = (req, res) => {
    // console.log(req.user.id);
    
  const redirectUrl =
    `https://www.strava.com/oauth/authorize` +
    `?client_id=${process.env.STRAVA_CLIENT_ID}` +
    `&response_type=code` +
    `&redirect_uri=http://localhost:4000/api/strava/callback` +
    `&scope=activity:read_all` +
    `&state=${req.user.id}`;

  res.redirect(redirectUrl);
};


export const stravaCallback = async (req, res) => {
  try {
    const { code, state } = req.query; // state = userId

    const tokenRes = await axios.post(
      "https://www.strava.com/oauth/token",
      {
        client_id: process.env.STRAVA_CLIENT_ID,
        client_secret: process.env.STRAVA_CLIENT_SECRET,
        code,
        grant_type: "authorization_code"
      }
    );
    // console.log("TOKEN:", tokenRes.data);


    await User.findByIdAndUpdate(state, {
      strava: {
        accessToken: tokenRes.data.access_token,
        refreshToken: tokenRes.data.refresh_token,
        expiresAt: tokenRes.data.expires_at,
        athleteId: tokenRes.data.athlete.id
      }
    });

    res.json({ message: "Strava connected successfully" });

  } catch (err) {
    console.error(err.response?.data || err.message);
    res.status(500).json({ message: "Strava OAuth failed" });
  }
};


// controllers/stravaSyncController.js
// import axios from "axios";
// import DailyHealthLog from "../models/DailyHealthLog.js";
// import User from "../models/User.js";

// export const syncStravaActivities = async (req, res) => {
//   try {
//     const user = await User.findById(req.user.id);

//     if (!user?.strava?.accessToken) {
//       return res.status(400).json({ message: "Strava not connected" });
//     }

//     const response = await axios.get(
//       "https://www.strava.com/api/v3/athlete/activities",
//       {
//         headers: {
//           Authorization: `Bearer ${user.strava.accessToken}`,
//         },
//         params: { per_page: 50 },
//       }
//     );

//     const activities = response.data;

//     console.log(activities);
    
//     const dailyMap = {};

//     for (const act of activities) {
//       const date = act.start_date_local.split("T")[0];
//       const durationMin = act.moving_time / 60;
//       const distanceKm = act.distance ? act.distance / 1000 : 0;

//       // MET values
//       let MET = 3; // default yoga
//       if (["Run"].includes(act.type)) MET = 8;
//       if (["Walk", "Hike"].includes(act.type)) MET = 3.5;
//       if (["Ride"].includes(act.type)) MET = 6;

//       const weightKg = 70; // hackathon default
//       const calories = Math.round(MET * weightKg * (durationMin / 60));

//       const steps =
//         act.type === "Run" || act.type === "Walk"
//           ? Math.round(distanceKm * 1312) // steps per km
//           : 0;

//       if (!dailyMap[date]) {
//         dailyMap[date] = {
//           steps: 0,
//           distance: 0,
//           caloriesBurned: 0,
//           heartRateSum: 0,
//           hrCount: 0,
//         };
//       }

//       dailyMap[date].steps += steps;
//       dailyMap[date].distance += distanceKm;
//       dailyMap[date].caloriesBurned += calories;

//       if (typeof act.average_heartrate === "number") {
//         dailyMap[date].heartRateSum += act.average_heartrate;
//         dailyMap[date].hrCount += 1;
//         }


//       // Save raw activity
//       await Activity.findOneAndUpdate(
//         { stravaActivityId: act.id },
//         {
//           userId: req.user.id,
//           source: "strava",
//           stravaActivityId: act.id,
//           type: act.type,
//           durationMin: Math.round(durationMin),
//           avgHeartRate: act.average_heartrate || null,
//           maxHeartRate: act.max_heartrate || null,
//           caloriesBurned: calories,
//           distance: distanceKm || 0,
//           steps,
//           startTime: act.start_date,
//         },
//         { upsert: true }
//       );
//     }

//     // Save DailyHealthLog
//     for (const date in dailyMap) {
//       const d = dailyMap[date];
//       await DailyHealthLog.findOneAndUpdate(
//         { userId: req.user.id, date },
//         {
//           steps: d.steps,
//           distance: Number(d.distance.toFixed(2)),
//           caloriesBurned: d.caloriesBurned,
//           avgHeartRate:
//                 d.hrCount > 0
//                 ? Math.round(d.heartRateSum / d.hrCount)
//                 : undefined,

//           source: "strava",
//         },
//         { upsert: true }
//       );
//     }

//     res.json({
//       message: "Strava activities synced correctly",
//       days: Object.keys(dailyMap).length,
//     });
//   } catch (err) {
//     console.error(err);
//     res.status(500).json({ message: "Strava sync failed" });
//   }
// };


export const syncStravaActivities = async (req, res) => {
  try {
    const user = await User.findById(req.user.id);

    if (!user?.strava?.refreshToken) {
      return res.status(400).json({ message: "Strava not connected" });
    }

    // ✅ ENSURE TOKEN IS VALID
    const accessToken = await ensureValidStravaToken(user);

    // ✅ NOW CALL STRAVA
    const response = await axios.get(
      "https://www.strava.com/api/v3/athlete/activities",
      {
        headers: {
          Authorization: `Bearer ${accessToken}`,
        },
        params: { per_page: 50 },
      }
    );

    const activities = response.data;
    console.log(activities);
    
    const dailyMap = {};

    for (const act of activities) {
      const date = act.start_date_local.split("T")[0];
      const durationMin = act.moving_time / 60;
      const distanceKm = act.distance ? act.distance / 1000 : 0;

      let MET = 3;
      if (act.type === "Run") MET = 8;
      if (["Walk", "Hike"].includes(act.type)) MET = 3.5;
      if (act.type === "Ride") MET = 6;

      const calories = Math.round(MET * 70 * (durationMin / 60));
      const steps =
        act.type === "Run" || act.type === "Walk"
          ? Math.round(distanceKm * 1312)
          : 0;

      if (!dailyMap[date]) {
        dailyMap[date] = {
          steps: 0,
          distance: 0,
          caloriesBurned: 0,
          hrSum: 0,
          hrCount: 0,
        };
      }

      dailyMap[date].steps += steps;
      dailyMap[date].distance += distanceKm;
      dailyMap[date].caloriesBurned += calories;

      if (typeof act.average_heartrate === "number") {
        dailyMap[date].hrSum += act.average_heartrate;
        dailyMap[date].hrCount++;
      }



      // Save activity
      await Activity.findOneAndUpdate(
        { stravaActivityId: act.id },
        {
          userId: user._id,
          source: "strava",
          stravaActivityId: act.id,
          type: act.type,
          durationMin: Math.round(durationMin),
          avgHeartRate: act.average_heartrate ?? null,
          maxHeartRate: act.max_heartrate ?? null,
          caloriesBurned: calories,
          distance: distanceKm,
          steps,
          startTime: act.start_date,
        },
        { upsert: true }
      );
    }

    // Save DailyHealthLog
    for (const date in dailyMap) {
      const d = dailyMap[date];

      await DailyHealthLog.findOneAndUpdate(
        { userId: user._id, date },
        {
          steps: d.steps,
          distance: Number(d.distance.toFixed(2)),
          caloriesBurned: d.caloriesBurned,
          avgHeartRate:
            d.hrCount > 0 ? Math.round(d.hrSum / d.hrCount) : null,
          source: "strava",
        },
        { upsert: true }
      );
    }

    res.json({
      message: "Strava synced successfully",
      days: Object.keys(dailyMap).length,
    });
  } catch (err) {
    console.error(err.response?.data || err.message);
    res.status(500).json({ message: "Strava sync failed" });
  }
};