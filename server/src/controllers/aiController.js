import DailyHealthLog from "../models/DailyHealthLog.js";
import { generateAISummary } from "../services/aiService.js";

export const getAISummary = async (req, res) => {
  try {
    const userId = req.user.id;

    // 1️⃣ Fetch last 7 days data
    const logs = await DailyHealthLog.find({ userId })
      .sort({ date: -1 })
      .limit(7);

    const avgSteps = Math.round(
      logs.reduce((sum, d) => sum + (d.steps || 0), 0) /
        Math.max(logs.length, 1)
    );

    const avgSleep =
      logs.reduce((sum, d) => sum + (d.sleepHours || 0), 0) /
      Math.max(logs.length, 1);

    // 2️⃣ Smart Prompt (frontend-driven)
    const prompt = `
User health data (last 7 days):
- Average steps per day: ${avgSteps}
- Average sleep hours: ${avgSleep}

Generate STRICT JSON in this format ONLY:

{
  "summaryText": "2 line weekly health summary",
  "sleepAdvice": "1 sleep improvement advice",
  "status": "Recovered | Improving | Needs Attention",
  "trend": "Positive | Neutral | Negative",
  "recommendations": [
    { "title": "Short title", "description": "Short description" },
    { "title": "Short title", "description": "Short description" }
  ]
}
`;

    // 3️⃣ Call Groq AI
    const aiText = await generateAISummary(prompt);

    // 4️⃣ Parse AI JSON safely
    let aiData;
    try {
      aiData = JSON.parse(aiText);
    } catch (err) {
      return res.status(500).json({
        error: "AI returned invalid JSON",
        raw: aiText
      });
    }

    // 5️⃣ Send UI‑READY response
    res.json({
      weeklyPulse: {
        summaryText: aiData.summaryText,
        sleepAdvice: aiData.sleepAdvice,
        updatedAt: new Date().toISOString()
      },
      keyInsights: {
        sleepChange: "+2hrs",
        steps: avgSteps,
        status: aiData.status,
        trend: aiData.trend
      },
      recommendations: aiData.recommendations
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "AI summary failed" });
  }
};
