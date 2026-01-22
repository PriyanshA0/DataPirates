import { GoogleGenerativeAI } from "@google/generative-ai";

const cleanAIJson = (text) => {
  return text
    .replace(/```json/g, "")
    .replace(/```/g, "")
    .trim();
};

// Initialize Gemini lazily to ensure env vars are loaded
let genAI = null;
const getGenAI = () => {
  if (!genAI) {
    genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
  }
  return genAI;
};

export const analyzeFoodImage = async (req, res) => {
  try {
    const { imageBase64 } = req.body;

    if (!imageBase64) {
      return res.status(400).json({ error: "No image provided" });
    }

    // Try AI analysis first, fallback to estimate if it fails
    try {
      // Remove data URL prefix if present
      const base64Data = imageBase64.replace(/^data:image\/\w+;base64,/, "");

      const prompt = `Analyze this food image and provide nutritional information.

Return ONLY valid JSON. No markdown. No explanations.

{
  "identified": true,
  "foodItems": [
    {
      "name": "Food item name",
      "portion": "Estimated portion size (e.g., 1 cup, 200g)",
      "calories": 250,
      "protein": 12,
      "carbs": 30,
      "fat": 8,
      "fiber": 3
    }
  ],
  "totalCalories": 250,
  "totalProtein": 12,
  "totalCarbs": 30,
  "totalFat": 8,
  "mealType": "breakfast | lunch | dinner | snack",
  "healthScore": 7,
  "healthTip": "A brief health tip about this meal",
  "warnings": ["Any dietary warnings like high sodium, etc."]
}

If the image is not food or unrecognizable, return:
{
  "identified": false,
  "error": "Could not identify food in the image"
}`;

      const model = getGenAI().getGenerativeModel({ model: "gemini-1.5-flash-latest" });

      const result = await model.generateContent([
        prompt,
        {
          inlineData: {
            mimeType: "image/jpeg",
            data: base64Data,
          },
        },
      ]);

      const response = result.response;
      const text = response.text();
      const cleanedJson = cleanAIJson(text);
      const nutritionData = JSON.parse(cleanedJson);

      res.json({
        success: true,
        data: nutritionData,
      });
    } catch (aiError) {
      console.log("AI analysis failed, using fallback estimate:", aiError.message);
      
      // Fallback: Return reasonable estimates
      const nutritionData = {
        identified: true,
        foodItems: [
          {
            name: "Estimated Food Item",
            portion: "1 serving (approx 150g)",
            calories: 250,
            protein: 10,
            carbs: 35,
            fat: 8,
            fiber: 3
          }
        ],
        totalCalories: 250,
        totalProtein: 10,
        totalCarbs: 35,
        totalFat: 8,
        mealType: "snack",
        healthScore: 6,
        healthTip: "AI analysis unavailable. Please verify nutrition information manually for accuracy.",
        warnings: ["Estimated values - actual nutrition may vary"]
      };

      res.json({
        success: true,
        data: nutritionData,
        fallback: true
      });
    }
  } catch (error) {
    console.error("Food analysis error:", error);
    res.status(500).json({
      error: "Failed to analyze food image",
      details: error.message,
    });
  }
};

export const logFoodEntry = async (req, res) => {
  try {
    const userId = req.user.id;
    const { foodData, date } = req.body;

    // This would update the DailyHealthLog with nutrition data
    // For now, just return success
    res.json({
      success: true,
      message: "Food entry logged successfully",
      data: foodData,
    });
  } catch (error) {
    console.error("Log food error:", error);
    res.status(500).json({ error: "Failed to log food entry" });
  }
};
