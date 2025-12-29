/**
 * Firebase Cloud Function for Yoga of Eating
 * Analyzes meal descriptions using Gemini AI
 */

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { GoogleGenerativeAI } = require("@google/generative-ai");
const { defineSecret } = require('firebase-functions/params');

// Define the API Key as a secret for security
const geminiApiKey = defineSecret('GEMINI_API_KEY');

exports.analyzeMeal = onCall({ secrets: [geminiApiKey] }, async (request) => {
    // 1. Validate Input
    const description = request.data.description;
    if (!description || typeof description !== 'string') {
        throw new HttpsError('invalid-argument', 'The function must be called with a "description" string.');
    }

    // 2. Initialize Model with Key
    const genAI = new GoogleGenerativeAI(geminiApiKey.value());
    const model = genAI.getGenerativeModel({ model: "gemini-2.5-flash-lite" });

    // 3. Construct Prompt
    const prompt = `
    Analyze the following meal description and return a purely JSON object (no markdown formatting) with:
    1. "healthScore": A double between 0.0 (unhealthy) and 1.0 (very healthy).
    2. "mood": One of "serene", "neutral", or "overwhelmed".
    3. "sound": A suggestion for a physiological sound (e.g., "chime", "thump", "tink", "heavy_thump").

    Meal: "${description}"

    Example Response:
    {
      "healthScore": 0.85,
      "mood": "serene",
      "sound": "chime"
    }
    `;

    try {
        // 4. Call AI
        const result = await model.generateContent(prompt);
        const response = await result.response;
        const text = response.text();

        // 5. Parse JSON
        const jsonString = text.replace(/```json/g, "").replace(/```/g, "").trim();
        const data = JSON.parse(jsonString);

        return data;

    } catch (error) {
        console.error("AI Analysis Error:", error);
        // Return neutral fallback
        return {
            healthScore: 0.5,
            mood: "neutral",
            sound: "tink"
        };
    }
});
