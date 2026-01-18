# DataPirates

# 🏥 Swasth-Setu - Comprehensive Health & Fitness Tracking Platform

> A full-stack mobile application for health monitoring, fitness tracking, and AI-powered wellness insights.

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [System Architecture](#system-architecture)
3. [Tech Stack](#tech-stack)
4. [Features](#features)
5. [Database Schema](#database-schema)
6. [API Documentation](#api-documentation)
7. [Authentication Flow](#authentication-flow)
8. [Frontend Structure](#frontend-structure)
9. [Key Algorithms](#key-algorithms)
10. [External Integrations](#external-integrations)

---

## 🎯 Overview

**Swasth-Setu** is a comprehensive health and fitness tracking application that combines real-time health monitoring, AI-powered insights, gamification, and social engagement to help users maintain a healthy lifestyle.

### Problem Statement
- People struggle to maintain consistent health tracking habits
- Lack of personalized, actionable health insights
- No motivation system to encourage daily health activities
- Disconnected health data from various sources

### Solution
SwasthSetu addresses these challenges by providing:
- Unified health dashboard with real-time metrics
- AI-generated personalized health recommendations
- Gamification with points, levels, and leaderboards
- Seamless integration with fitness platforms (Strava)
- Smart notification system for health alerts

---

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         PRESENTATION LAYER                          │
│                        (Flutter Mobile App)                         │
│  ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌───────────┐           │
│  │ Dashboard │ │ Analytics │ │ AI Summary│ │Gamification│           │
│  │  Screen   │ │  Screen   │ │  Screen   │ │  Screen   │           │
│  └─────┬─────┘ └─────┬─────┘ └─────┬─────┘ └─────┬─────┘           │
│        │             │             │             │                  │
│  ┌─────┴─────────────┴─────────────┴─────────────┴─────────┐       │
│  │                    SERVICE LAYER                         │       │
│  │  ApiService | GamificationService | NotificationService  │       │
│  └────────────────────────────┬────────────────────────────┘       │
└───────────────────────────────┼─────────────────────────────────────┘
                                │
                         REST API (HTTP)
                         JWT Cookie Auth
                                │
┌───────────────────────────────┼─────────────────────────────────────┐
│                         BACKEND LAYER                               │
│                      (Node.js + Express)                            │
│  ┌────────────────────────────┴────────────────────────────┐       │
│  │                    ROUTE HANDLERS                        │       │
│  │  /auth | /health | /analytics | /gamification | /ai     │       │
│  └────────────────────────────┬────────────────────────────┘       │
│                               │                                     │
│  ┌────────────────────────────┴────────────────────────────┐       │
│  │                    CONTROLLERS                           │       │
│  │        (Business Logic & Request Processing)             │       │
│  └────────────────────────────┬────────────────────────────┘       │
│                               │                                     │
│  ┌────────────────────────────┴────────────────────────────┐       │
│  │                 MIDDLEWARE LAYER                         │       │
│  │              (Authentication & Validation)               │       │
│  └────────────────────────────┬────────────────────────────┘       │
└───────────────────────────────┼─────────────────────────────────────┘
                                │
┌───────────────────────────────┼─────────────────────────────────────┐
│                          DATA LAYER                                 │
│  ┌────────────────────────────┴────────────────────────────┐       │
│  │                  MongoDB (Mongoose ODM)                  │       │
│  │  ┌─────────┐ ┌─────────────┐ ┌───────────────────┐      │       │
│  │  │  User   │ │DailyHealthLog│ │GamificationProfile│      │       │
│  │  └─────────┘ └─────────────┘ └───────────────────┘      │       │
│  │  ┌─────────┐ ┌─────────────┐ ┌───────────────────┐      │       │
│  │  │  Goal   │ │MedicalProfile│ │    Activity      │      │       │
│  │  └─────────┘ └─────────────┘ └───────────────────┘      │       │
│  └─────────────────────────────────────────────────────────┘       │
└─────────────────────────────────────────────────────────────────────┘
                                │
┌───────────────────────────────┼─────────────────────────────────────┐
│                    EXTERNAL SERVICES                                │
│  ┌─────────────────┐    ┌─────────────────┐                        │
│  │   Strava API    │    │ Google Gemini   │                        │
│  │ (Activity Sync) │    │   (AI Insights) │                        │
│  └─────────────────┘    └─────────────────┘                        │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Tech Stack

### Frontend
| Technology | Purpose |
|------------|---------|
| **Flutter** | Cross-platform mobile framework |
| **Dart** | Programming language |
| **SharedPreferences** | Local storage & caching |
| **HTTP Package** | REST API communication |
| **Intl Package** | Internationalization & date formatting |

### Backend
| Technology | Purpose |
|------------|---------|
| **Node.js** | Runtime environment |
| **Express.js** | Web application framework |
| **MongoDB** | NoSQL database |
| **Mongoose** | MongoDB ODM |
| **JWT** | Authentication tokens |
| **bcrypt** | Password hashing |

### External Services
| Service | Purpose |
|---------|---------|
| **Strava API** | Fitness activity synchronization |
| **Google Gemini AI** | Health insights generation |

---

## ✨ Features

### 1. Health Dashboard 📊

**Real-time Health Score Calculation:**
```
Health Score = (Steps/StepsGoal × 40) + (Sleep/SleepGoal × 30) + (Distance/DistanceGoal × 30)
```

**Dynamic Health Remarks:**
| Score Range | Status | Color |
|-------------|--------|-------|
| 90-100 | Excellent Condition | Teal (#45A191) |
| 70-89 | Good Condition | Green (#4CAF50) |
| 50-69 | Fair Condition | Orange (#FFA726) |
| 30-49 | Poor Condition | Deep Orange (#FF7043) |
| 0-29 | Needs Attention | Red (#E53935) |

**Features:**
- Weekly calendar for date-based health viewing
- Customizable daily goals (steps, sleep, distance)
- Real-time data sync with backend
- Offline mode with cached data

### 2. Analytics Dashboard 📈

- **Timeframe Selection:** Today / Week / Month
- **Activity Level Charts:** Bar charts showing daily steps
- **Heart Rate Monitoring:** Trend visualization with resting HR calculation
- **Sleep Quality Tracking:** Duration and quality assessment
- **Hydration Tracker:** Manual water intake logging (2.5L - 4L goals)
- **Calorie & Distance Metrics**

### 3. AI-Powered Health Insights 🤖

**How it works:**
1. Aggregates last 7 days of health data
2. Sends to Google Gemini AI with structured prompt
3. Returns personalized insights in JSON format

**AI Response Structure:**
```json
{
  "summaryText": "Weekly health summary",
  "sleepAdvice": "Sleep improvement recommendation",
  "status": "Recovered | Improving | Needs Attention",
  "trend": "Positive | Neutral | Negative",
  "recommendations": [
    { "title": "...", "description": "..." }
  ]
}
```

### 4. Gamification System 🎮

**Points System:**
| Activity | XP Earned |
|----------|-----------|
| Daily activity logged | +10 XP |
| 8,000+ steps | +20 XP |
| 12,000+ steps | +10 XP (bonus) |
| 400+ calories burned | +20 XP |
| 7+ hours of sleep | +20 XP |

**Level Progression:**
- Level = Total Points ÷ 100 + 1
- Visual progress bar shows XP to next level

**Badges (12 Total):**
| Badge | Requirement |
|-------|-------------|
| First Steps | Complete 1,000 steps |
| Step Master | Reach 10,000 steps in a day |
| Marathon Walker | Walk 50,000 steps in a week |
| Sleep Champion | 8+ hours sleep for 7 days |
| Early Bird | Log activity before 7 AM |
| Calorie Crusher | Burn 500+ calories in a day |
| Consistency King | Log data for 30 days straight |
| Heart Healthy | Optimal heart rate for a week |
| Hydration Hero | Meet hydration goal for 5 days |
| Social Butterfly | Share progress with friends |
| Rising Star | Reach Level 5 |
| Health Champion | Reach Level 10 |

**Leaderboard:**
- Daily rankings based on XP earned
- Top 10 users displayed
- Gold/Silver/Bronze highlighting for top 3

### 5. Smart Notifications 🔔

| Alert Type | Trigger | Time Constraint |
|------------|---------|-----------------|
| Low Activity | Steps < 3,000 | Only after 6 PM |
| High Heart Rate | HR > 120 BPM (resting) | 2-hour cooldown |
| Abnormal Sleep | < 5 or > 10 hours | 24-hour cooldown |
| Daily Health Check | Scheduled reminder | 8 PM daily |

### 6. Strava Integration 🏃

- OAuth2 authentication flow
- Automatic activity sync on app open
- Supports: Running, Walking, Cycling, Swimming
- Data mapped to daily health logs

### 7. Multi-language Support 🌐

| Language | Code |
|----------|------|
| English | en |
| Hindi | hi |
| Marathi | mr |

---

## 🗄️ Database Schema

### User Model
```javascript
{
  name: String,
  email: String (unique, lowercase),
  password: String (hashed),
  age: Number,
  gender: "male" | "female" | "other",
  height: Number (cm),
  weight: Number (kg),
  mobile: String,
  strava: {
    accessToken: String,
    refreshToken: String,
    expiresAt: Number
  },
  role: String (default: "user")
}
```

### DailyHealthLog Model
```javascript
{
  userId: ObjectId (ref: User),
  date: String (YYYY-MM-DD),
  steps: Number,
  distance: Number (km),
  caloriesBurned: Number,
  heartRateAvg: Number,
  sleep: {
    duration: Number (hours),
    quality: "poor" | "average" | "good"
  },
  nutrition: {
    caloriesConsumed: Number,
    waterIntake: Number (liters)
  },
  mood: {
    moodLevel: Number (1-5),
    stressLevel: Number (1-5)
  },
  source: "google_fit" | "manual" | "strava"
}
// Index: { userId: 1, date: 1 } (unique)
```

### GamificationProfile Model
```javascript
{
  userId: ObjectId (ref: User),
  points: Number,
  dailyPoints: Number,
  level: Number,
  badges: Array,
  lastUpdatedDate: String (YYYY-MM-DD)
}
```

---

## 📡 API Documentation

### Authentication Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/register` | User registration |
| POST | `/api/auth/login` | User login (returns JWT cookie) |
| POST | `/api/auth/logout` | User logout |
| GET | `/api/auth/profile` | Get current user profile |

### Health Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/health/day/:date` | Get health data for specific date |
| POST | `/api/health/sync` | Sync daily health data |

### Analytics Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/analytics/weekly` | Get weekly aggregated stats |
| GET | `/api/analytics/monthly` | Get monthly aggregated stats |

### Gamification Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/gamification/profile` | Get user's gamification profile |
| POST | `/api/gamification/sync` | Calculate and sync daily points |
| GET | `/api/gamification/leaderboard/today` | Get today's top 10 |
| POST | `/api/gamification/reset` | Reset gamification (dev only) |

### AI Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/ai/summary` | Get AI-generated health insights |

### Strava Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/strava/auth` | Strava OAuth callback |
| POST | `/api/strava/sync` | Sync Strava activities |

---

## 🔐 Authentication Flow

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Flutter    │     │   Express    │     │   MongoDB    │
│    Client    │     │   Server     │     │   Database   │
└──────┬───────┘     └──────┬───────┘     └──────┬───────┘
       │                    │                    │
       │  POST /auth/login  │                    │
       │  {email, password} │                    │
       │───────────────────>│                    │
       │                    │   Find User        │
       │                    │───────────────────>│
       │                    │   User Document    │
       │                    │<───────────────────│
       │                    │                    │
       │                    │  Verify Password   │
       │                    │  (bcrypt.compare)  │
       │                    │                    │
       │                    │  Generate JWT      │
       │                    │  (24h expiry)      │
       │                    │                    │
       │  Set-Cookie: token │                    │
       │<───────────────────│                    │
       │                    │                    │
       │  Store in          │                    │
       │  SharedPreferences │                    │
       │                    │                    │
       │  GET /health/day   │                    │
       │  Cookie: token=jwt │                    │
       │───────────────────>│                    │
       │                    │                    │
       │                    │  authMiddleware    │
       │                    │  verify(token)     │
       │                    │  req.user = {id}   │
       │                    │                    │
       │                    │  Query by userId   │
       │                    │───────────────────>│
       │                    │  Health Data       │
       │                    │<───────────────────│
       │   JSON Response    │                    │
       │<───────────────────│                    │
       │                    │                    │
```

---

## 📱 Frontend Structure

```
client/lib/
├── main.dart                    # App entry point
├── services/
│   ├── api_service.dart         # REST API communication
│   ├── gamification_service.dart # Gamification API
│   └── notification_service.dart # Local notifications
└── screens/
    ├── splash_screen.dart       # App loading screen
    ├── login_screen.dart        # User authentication
    ├── registration_screen.dart # New user signup
    ├── dashboard/
    │   └── dashboard_screen.dart # Main health dashboard
    ├── Analytics/
    │   └── analytics_screen.dart # Health analytics
    ├── Ai_summary/
    │   └── summary_screen.dart  # AI health insights
    ├── gamification/
    │   └── gamification_screen.dart # Points, badges, leaderboard
    ├── History_page/
    │   └── history_page.dart    # Historical health data
    ├── profile_page/
    │   └── profile_page.dart    # User profile
    └── settings_page/
        └── settings_page.dart   # App settings
```

---

## 🧮 Key Algorithms

### Health Score Calculation
```dart
int calculateHealthScore(int steps, double sleep, int distance) {
  double score = 
    (steps / stepsGoal * 40) +     // 40% weight
    (sleep / sleepGoal * 30) +     // 30% weight
    (distance / distanceGoal * 30); // 30% weight
  return score.clamp(0, 100).toInt();
}
```

### Resting Heart Rate Estimation
```dart
int calculateRestingHeartRate(int avgHR) {
  double multiplier = 0.75; // Base: 75% of avg daily HR
  
  // Adjust for sleep quality
  if (sleepQuality == 'good') multiplier = 0.72;
  if (sleepQuality == 'bad') multiplier = 0.78;
  
  // Adjust for activity level
  if (steps > 8000) multiplier -= 0.02;
  if (steps < 3000) multiplier += 0.02;
  
  return (avgHR * multiplier).clamp(50, 100).round();
}
```

### Gamification Points Calculation
```javascript
let dailyPoints = 10; // Base activity points

if (steps >= 8000) dailyPoints += 20;
if (steps >= 12000) dailyPoints += 10;
if (caloriesBurned >= 400) dailyPoints += 20;
if (sleep.duration >= 7) dailyPoints += 20;

level = Math.floor(totalPoints / 100) + 1;
```

---

## 🔗 External Integrations

### Strava API Integration

**OAuth2 Flow:**
1. User clicks "Connect Strava" 
2. Redirect to Strava authorization page
3. User grants permission
4. Callback with authorization code
5. Exchange code for access/refresh tokens
6. Store tokens in User document

**Activity Sync:**
```javascript
// Fetch activities from Strava
GET https://www.strava.com/api/v3/athlete/activities
Authorization: Bearer {access_token}

// Map to DailyHealthLog
{
  steps: activity.distance / 0.75,  // Estimate from distance
  caloriesBurned: activity.calories,
  distance: activity.distance / 1000, // Convert to km
  source: "strava"
}
```

### Google Gemini AI Integration

**Request Flow:**
```javascript
const prompt = `
User health data (last 7 days):
- Average steps per day: ${avgSteps}
- Average sleep hours: ${avgSleep}

Return ONLY valid JSON with health insights...
`;

const response = await geminiModel.generateContent(prompt);
const insights = JSON.parse(response.text());
```

---

## 🚀 Getting Started

### Prerequisites
- Node.js v18+
- Flutter SDK 3.0+
- MongoDB Atlas account
- Strava API credentials
- Google Gemini API key

### Backend Setup
```bash
cd server
npm install
cp .env.example .env
# Configure environment variables
npm start
```

### Frontend Setup
```bash
cd client
flutter pub get
# Update API base URL in api_service.dart
flutter run
```

### Environment Variables
```env
PORT=4000
MONGODB_URI=mongodb+srv://...
JWT_SECRET=your-secret-key
STRAVA_CLIENT_ID=your-client-id
STRAVA_CLIENT_SECRET=your-secret
GEMINI_API_KEY=your-api-key
```

---

## 👥 Team - DataPirates

Built with ❤️ for HackCrypt Hackathon

---

## 📄 License

This project is licensed under the MIT License.
