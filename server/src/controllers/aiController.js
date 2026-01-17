import DailyHealthLog from "../models/DailyHealthLog.js";
import { generateAISummary } from "../services/aiService.js";

const cleanAIJson = (text) => {
  return text
    .replace(/```json/g, "")
    .replace(/```/g, "")
    .trim();
};

export const getAISummary = async (req, res) => {
  try {
    const userId = req.user.id;

    // 1️⃣ Fetch last 7 days
    const logs = await DailyHealthLog.find({ userId })
      .sort({ date: -1 })
      .limit(7);

    const avgSteps = Math.round(
      logs.reduce((sum, d) => sum + (d.steps || 0), 0) /
        Math.max(logs.length, 1)
    );

    const avgSleep = Number(
      (
        logs.reduce((sum, d) => sum + (d.sleep?.duration || 0), 0) /
        Math.max(logs.length, 1)
      ).toFixed(1)
    );

    // 2️⃣ Prompt
    const prompt = `
User health data (last 7 days):
- Average steps per day: ${avgSteps}
- Average sleep hours: ${avgSleep}

Return ONLY valid JSON. No markdown. No explanations.

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

    // 3️⃣ Call AI
    const aiRaw = await generateAISummary(prompt);

    // 4️⃣ Clean + Parse
    let aiData;
    try {
      const cleaned = cleanAIJson(aiRaw);
      aiData = JSON.parse(cleaned);
    } catch (err) {
      console.error("AI RAW RESPONSE:", aiRaw);
      return res.status(500).json({
        error: "AI returned invalid JSON",
        raw: aiRaw
      });
    }

    // 5️⃣ UI-ready response
    res.json({
      weeklyPulse: {
        summaryText: aiData.summaryText,
        sleepAdvice: aiData.sleepAdvice,
        updatedAt: new Date().toISOString()
      },
      keyInsights: {
        steps: avgSteps,
        avgSleep,
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
