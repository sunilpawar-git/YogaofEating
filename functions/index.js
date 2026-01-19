/**
 * Firebase Cloud Functions for Yoga of Eating
 * Analyzes meal descriptions and generates insights using Gemini AI
 */

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { GoogleGenerativeAI } = require("@google/generative-ai");
const { defineSecret } = require('firebase-functions/params');

// Define the API Key as a secret for security
const geminiApiKey = defineSecret('GEMINI_API_KEY');

/**
 * Analyzes a single meal description and provides a basic insight
 */
exports.analyzeMeal = onCall({ secrets: [geminiApiKey] }, async (request) => {
    // 1. Validate Input
    const description = request.data.description;
    if (!description || typeof description !== 'string') {
        throw new HttpsError('invalid-argument', 'The function must be called with a "description" string.');
    }

    // 2. Initialize Model with Key
    const genAI = new GoogleGenerativeAI(geminiApiKey.value());
    const model = genAI.getGenerativeModel({ model: "gemini-2.5-flash-lite" });

    // 3. Construct Prompt with basic insight
    const prompt = `
    Analyze the following meal description and return a purely JSON object (no markdown formatting) with:
    1. "healthScore": A double between 0.0 (unhealthy) and 1.0 (very healthy).
    2. "mood": One of "serene", "neutral", or "overwhelmed".
    3. "sound": A suggestion for a physiological sound (e.g., "chime", "thump", "tink", "heavy_thump").
    4. "insight": A brief 1-sentence summary of the meal's nutritional value (e.g., "High in protein, low in carbs - good for muscle building").

    Meal: "${description}"

    Example Response:
    {
      "healthScore": 0.85,
      "mood": "serene",
      "sound": "chime",
      "insight": "Rich in protein and healthy fats, this meal supports sustained energy."
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

        return {
            healthScore: data.healthScore ?? 0.5,
            mood: data.mood ?? "neutral",
            sound: data.sound ?? "tink",
            insight: data.insight ?? null
        };

    } catch (error) {
        console.error("AI Analysis Error:", error);
        // Return neutral fallback
        return {
            healthScore: 0.5,
            mood: "neutral",
            sound: "tink",
            insight: null
        };
    }
});

/**
 * Gets detailed meal insight on-demand (called when user taps score badge)
 * Provides comprehensive nutritional breakdown and personalized tips
 */
exports.getMealInsight = onCall({ secrets: [geminiApiKey] }, async (request) => {
    // 1. Validate Input
    const { mealItems, mealType, healthScore } = request.data;
    if (!mealItems || !Array.isArray(mealItems) || mealItems.length === 0) {
        throw new HttpsError('invalid-argument', 'The function must be called with "mealItems" array.');
    }

    // 2. Initialize Model with Key
    const genAI = new GoogleGenerativeAI(geminiApiKey.value());
    const model = genAI.getGenerativeModel({ model: "gemini-2.5-flash-lite" });

    // 3. Construct comprehensive prompt
    const mealDescription = mealItems.join(", ");
    const prompt = `
    You are a nutrition expert analyzing a meal. Provide a comprehensive but concise breakdown.

    Meal: ${mealDescription}
    Meal Type: ${mealType || "unspecified"}
    Current Health Score: ${healthScore ? Math.round(healthScore * 100) + "%" : "not scored"}

    Return a JSON object (no markdown) with:
    1. "summary": A 1-2 sentence overview of this meal's nutritional value (warm, encouraging tone)
    2. "nutritionHighlights": Array of 2-3 key nutritional points (e.g., ["High in protein (~25g)", "Good source of fiber", "Low in saturated fat"])
    3. "tip": One actionable health tip related to this meal (e.g., "Pair with leafy greens for more iron absorption")
    4. "category": One of "excellent", "good", "moderate", or "needs_improvement"

    Keep the response concise and user-friendly. Focus on what's good about the meal first.

    Example Response:
    {
      "summary": "This protein-rich meal provides sustained energy and supports muscle recovery.",
      "nutritionHighlights": ["High in protein (~30g)", "Contains healthy fats from olive oil", "Good fiber content"],
      "tip": "Adding a small side salad would boost vitamin intake.",
      "category": "good"
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

        return {
            summary: data.summary ?? "A balanced meal choice.",
            nutritionHighlights: data.nutritionHighlights ?? [],
            tip: data.tip ?? null,
            category: data.category ?? "moderate"
        };

    } catch (error) {
        console.error("Meal Insight Error:", error);
        // Return helpful fallback
        return {
            summary: "This meal contributes to your daily nutrition. Keep tracking to see patterns!",
            nutritionHighlights: [],
            tip: "Try to include a variety of food groups in each meal.",
            category: "moderate"
        };
    }
});

/**
 * Generates personalized insights from user's wellbeing data (last 1-3 days)
 * Uses Gemini AI to analyze patterns in meals, sleep, feelings, and mind checks
 */
exports.generateInsight = onCall({ secrets: [geminiApiKey] }, async (request) => {
    // 1. Validate Input
    const userData = request.data.userData;
    if (!userData || !Array.isArray(userData) || userData.length === 0) {
        throw new HttpsError('invalid-argument', 'The function must be called with a "userData" array containing daily snapshots.');
    }

    // 2. Initialize Model with Key
    const genAI = new GoogleGenerativeAI(geminiApiKey.value());
    const model = genAI.getGenerativeModel({ model: "gemini-2.5-flash-lite" });

    // 3. Identify which day is "today" (the insight date)
    const insightDate = request.data.insightDate || null;
    const todayDay = userData.find(day => day.isToday === true);
    const todaySleep = todayDay?.sleepQuality || null;
    const todayAppleSleep = todayDay?.appleSleepData || null;
    const todayDateName = todayDay?.date || insightDate || "today";

    // 4. Build data summary for prompt
    const dataSummary = userData.map(day => {
        const isToday = day.isToday === true;
        const dayLabel = isToday ? `**${day.date} (TODAY)**` : `**${day.date}**`;
        let summary = `${dayLabel}:\n`;
        
        // Meals
        if (day.meals && day.meals.length > 0) {
            const mealItems = day.meals.flatMap(m => m.items || []).slice(0, 5).join(", ");
            const avgScore = day.averageHealthScore ? Math.round(day.averageHealthScore * 100) : 50;
            summary += `  - Food: ${mealItems || 'Not logged'} (Health: ${avgScore}%)\n`;
        }
        
        // Sleep - highlight today's sleep (subjective user rating)
        if (day.sleepQuality) {
            const sleepLabel = isToday ? `  - Sleep (user-reported): ${day.sleepQuality} ⭐ (TODAY'S SLEEP)` : `  - Sleep (user-reported): ${day.sleepQuality}`;
            summary += `${sleepLabel}\n`;
        } else if (isToday) {
            summary += `  - Sleep (user-reported): Not logged yet\n`;
        }
        
        // Apple HealthKit sleep data (objective metrics from Apple Watch)
        if (day.appleSleepData) {
            const apple = day.appleSleepData;
            const durationHours = apple.durationHours ? apple.durationHours.toFixed(1) : 'N/A';
            const score = apple.score !== undefined ? Math.round(apple.score) + '%' : 'N/A';
            const efficiency = apple.efficiency ? Math.round(apple.efficiency) + '%' : 'N/A';
            const objectiveLabel = isToday 
                ? `  - Apple Watch Sleep ⌚ (OBJECTIVE): Score ${score}, Duration ${durationHours}h, Efficiency ${efficiency} ⭐`
                : `  - Apple Watch Sleep ⌚: Score ${score}, Duration ${durationHours}h, Efficiency ${efficiency}`;
            summary += `${objectiveLabel}\n`;
        }
        
        // Feeling
        if (day.feeling) {
            summary += `  - Feeling: ${day.feeling}\n`;
        }
        
        // Mind checks (Phase 4: include todo completion status)
        if (day.morningMindCheck && day.morningMindCheck.length > 0) {
            // Process todos with completion status
            const todos = day.morningMindCheck.filter(m => m.category === 'To-Do');
            if (todos.length > 0) {
                const completed = todos.filter(t => t.isAccomplished === true).length;
                summary += `  - Todos: ${completed}/${todos.length} completed\n`;
            }
            // Include other morning thoughts
            const otherThoughts = day.morningMindCheck.filter(m => m.category !== 'To-Do').map(m => m.text);
            if (otherThoughts.length > 0) {
                summary += `  - Morning thoughts: ${otherThoughts.slice(0, 3).join("; ")}\n`;
            }
        }
        
        if (day.eveningMindCheck && day.eveningMindCheck.length > 0) {
            const reflections = day.eveningMindCheck.map(m => m.text).slice(0, 3).join("; ");
            summary += `  - Evening reflections: ${reflections}\n`;
        }
        
        return summary;
    }).join("\n");

    // 5. Construct Prompt - explicitly instruct AI to consider today's sleep (both subjective and objective)
    let todayContext = '';
    
    if (todaySleep && todayAppleSleep) {
        // Both subjective and objective data available
        const appleScore = todayAppleSleep.score !== undefined ? Math.round(todayAppleSleep.score) + '%' : 'N/A';
        const appleDuration = todayAppleSleep.durationHours ? todayAppleSleep.durationHours.toFixed(1) + 'h' : 'N/A';
        todayContext = `IMPORTANT: Today (${todayDateName}) has BOTH sleep data sources:
- User-reported sleep quality: "${todaySleep}" (SUBJECTIVE - how the user FEELS they slept)
- Apple Watch metrics: Score ${appleScore}, Duration ${appleDuration} (OBJECTIVE - measured data)

Compare these two sources! If they differ (e.g., user says "poor" but Apple shows 80%), explore why the user might feel differently than what metrics show. This discrepancy can reveal important insights about perceived vs actual rest quality.`;
    } else if (todaySleep) {
        todayContext = `IMPORTANT: The user logged their sleep quality for ${todayDateName} as "${todaySleep}". This is TODAY's subjective sleep data and should be incorporated into your analysis. Look for connections between yesterday's food choices and TODAY's sleep quality.`;
    } else if (todayAppleSleep) {
        const appleScore = todayAppleSleep.score !== undefined ? Math.round(todayAppleSleep.score) + '%' : 'N/A';
        const appleDuration = todayAppleSleep.durationHours ? todayAppleSleep.durationHours.toFixed(1) + 'h' : 'N/A';
        todayContext = `IMPORTANT: Apple Watch recorded objective sleep metrics for ${todayDateName}: Score ${appleScore}, Duration ${appleDuration}. The user hasn't logged their subjective feeling yet, but you can still analyze how yesterday's food choices may have affected these objective metrics.`;
    } else {
        todayContext = `Note: Today's sleep quality has not been logged yet (neither subjective nor Apple Watch data available).`;
    }

    const prompt = `You are a compassionate wellness coach analyzing a user's food, sleep, todo completion, and mindset data.

${todayContext}

Here is the user's data from the last ${userData.length} day(s) (most recent first):

${dataSummary}

ANALYSIS GUIDELINES:
- When Apple Watch data is available, use it as OBJECTIVE truth for sleep duration and quality
- User-reported sleep quality reflects PERCEIVED rest (may differ from metrics due to dreams, stress, etc.)
- If both sources exist, note any discrepancies - they reveal important insights
- Example: "Your Apple Watch shows 7.5h of sleep with 85% efficiency, but you felt it was only 'poor' - this might indicate stress or vivid dreams affecting perceived rest quality"

Based on this data, generate ONE personalized insight that:
1. **MUST incorporate sleep data** (prioritize Apple Watch metrics when available for objective analysis)
2. Identifies a specific pattern or connection between:
   - Yesterday's food quality/timing and TODAY's sleep quality (both objective metrics and subjective feeling)
   - Discrepancies between Apple Watch metrics and user's perceived sleep quality
   - Food quality/timing and sleep patterns across days
   - Todo completion rate and end-of-day feeling
3. References specific days and metrics when relevant
4. Provides one actionable suggestion
5. Is warm, encouraging, and under 50 words

Return a JSON object (no markdown formatting) with:
- "insightText": The insight message (string, under 50 words)
- "insightType": One of "foodSleep", "mindsetFeeling", "pattern", or "encouragement"
- "confidence": A number between 0.0 and 1.0 indicating how confident you are in this insight

Example Response (with both data sources):
{
  "insightText": "Your Apple Watch shows solid 7.5h sleep with 85% efficiency, yet you rated it 'poor'. Yesterday's late dinner might have affected how rested you feel despite good metrics. Try finishing meals 3 hours before bed.",
  "insightType": "foodSleep",
  "confidence": 0.85
}`;

    try {
        // 5. Call AI
        const result = await model.generateContent(prompt);
        const response = await result.response;
        const text = response.text();

        // 6. Parse JSON
        const jsonString = text.replace(/```json/g, "").replace(/```/g, "").trim();
        const data = JSON.parse(jsonString);

        // Validate response structure
        if (!data.insightText || !data.insightType || data.confidence === undefined) {
            throw new Error("Invalid response structure from AI");
        }

        return {
            insightText: data.insightText,
            insightType: data.insightType,
            confidence: Math.min(1.0, Math.max(0.0, data.confidence))
        };

    } catch (error) {
        console.error("Insight Generation Error:", error);
        // Return encouraging fallback
        return {
            insightText: "Keep logging your meals and sleep to discover patterns in your wellbeing. Every day of data helps build a clearer picture!",
            insightType: "encouragement",
            confidence: 0.5
        };
    }
});
