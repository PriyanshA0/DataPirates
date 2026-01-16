import { generateAISummary } from "../services/aiService.js";

export const testAI = async (req, res) => {
  try {
    const prompt = `
You are a health AI.
Say only: AI is working perfectly
`;

    const result = await generateAISummary(prompt);
    res.json({ success: true, result });
  } catch (err) {
    console.error(err.response?.data || err.message);
    res.status(500).json({ error: "AI failed" });
  }
};
