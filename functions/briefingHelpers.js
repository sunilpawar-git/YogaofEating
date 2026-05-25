/**
 * Pure helper functions for briefing generation.
 * No Firebase dependencies — fully unit-testable without mocks.
 */

const USER_INPUT_MAX_LENGTH = 50;
const CONFIDENCE_FLOOR = 0.6;
const HEADLINE_MAX_WORDS = 15;
const BRIEFING_LOOKBACK_DAYS = 7;

/**
 * General input sanitizer — replaces smart quotes and strips newlines.
 * Used for user-supplied meal/mood strings passed as data (not identity fields).
 */
function sanitizeInput(input, maxLength = 500) {
    if (typeof input !== 'string') return '';
    return input
        .replace(/["""\u201C\u201D]/g, "'")
        .replace(/\n/g, ' ')
        .slice(0, maxLength)
        .trim();
}

/**
 * Identity field sanitizer using an allowlist approach.
 * Strips characters outside [word chars, spaces, -.,']. Enforces max length.
 * NEVER log input — only pass through sanitizeUserInput for prompt serialization.
 */
function sanitizeUserInput(str, maxLength = USER_INPUT_MAX_LENGTH) {
    if (typeof str !== 'string') return '';
    return str
        .replace(/[^\w\s\-.,']/g, '')
        .trim()
        .slice(0, maxLength);
}

/**
 * Builds the Gemini coaching system preamble.
 * Injects name, activity level, and dietary goal when provided.
 * Never logs userName — only serializes via sanitizeUserInput into the prompt.
 */
function buildSystemPrompt(userContext) {
    if (!userContext) {
        return 'You are a compassionate wellness coach';
    }
    const parts = ['You are a compassionate wellness coach'];
    if (userContext.name) {
        const safeName = sanitizeUserInput(String(userContext.name), USER_INPUT_MAX_LENGTH);
        if (safeName) {
            parts.push(`coaching ${safeName}`);
        }
    }
    const extras = [];
    if (userContext.activityLevel) {
        extras.push(`activity level: ${sanitizeUserInput(String(userContext.activityLevel), USER_INPUT_MAX_LENGTH)}`);
    }
    if (userContext.dietaryGoal) {
        extras.push(`dietary goal: ${sanitizeUserInput(String(userContext.dietaryGoal), USER_INPUT_MAX_LENGTH)}`);
    }
    if (extras.length > 0) {
        parts.push(`(${extras.join(', ')})`);
    }
    return parts.join(' ');
}

/**
 * Builds a per-day text block for the briefing prompt.
 * Handles tri-state todo completion: "true" = done, "false" = not done, "unreviewed" = (pending).
 */
function buildDaySummary(day) {
    const safeDate = sanitizeInput(String(day.date || 'unknown'), 30);
    let summary = `**${safeDate}**:\n`;

    if (day.meals && day.meals.length > 0) {
        const items = day.meals
            .flatMap(m => m.items || [])
            .slice(0, 6)
            .map(item => sanitizeInput(String(item), 100))
            .join(', ');
        const avgScore = day.averageHealthScore
            ? Math.round(day.averageHealthScore * 100)
            : 50;
        summary += `  Meals: ${items || 'None logged'} (Score: ${avgScore}%)\n`;

        const timings = day.meals
            .map(m => {
                const t = sanitizeInput(String(m.time || ''), 10);
                const type = sanitizeInput(String(m.mealType || ''), 20);
                return t ? `${type} @ ${t}` : type;
            })
            .filter(Boolean)
            .join(', ');
        if (timings) summary += `  Timing: ${timings}\n`;
    }

    if (day.sleepQuality) {
        summary += `  Sleep (user): ${sanitizeInput(String(day.sleepQuality), 50)}\n`;
    }
    if (day.appleSleepData) {
        const a = day.appleSleepData;
        const dur = a.durationHours ? Number(a.durationHours).toFixed(1) + 'h' : 'N/A';
        const score = a.score !== undefined ? Math.round(Number(a.score)) + '%' : 'N/A';
        summary += `  Sleep (Apple Watch): Score ${score}, Duration ${dur}\n`;
    }

    if (day.feeling) {
        summary += `  Feeling: ${sanitizeInput(String(day.feeling), 100)}\n`;
    }

    // Tri-state todo tracking across both morningMindCheck and highlightData.todos arrays
    const mindCheckTodos = (day.morningMindCheck || []).filter(
        m => (m.category || '').toLowerCase().replace('-', '') === 'todo'
    );
    const highlightTodos = day.todos || [];
    const allTodos = [...mindCheckTodos, ...highlightTodos];

    if (allTodos.length > 0) {
        const done = allTodos.filter(t => t.isAccomplished === 'true').length;
        const pending = allTodos.filter(t => t.isAccomplished === 'unreviewed').length;
        if (pending > 0) {
            summary += `  Todos: ${done}/${allTodos.length} completed, ${pending} (pending)\n`;
        } else {
            summary += `  Todos: ${done}/${allTodos.length} completed\n`;
        }
    }

    if (day.morningThoughts) {
        summary += `  Morning thoughts: ${sanitizeInput(String(day.morningThoughts), 300)}\n`;
    }
    if (day.journalEntry) {
        summary += `  Journal: ${sanitizeInput(String(day.journalEntry), 300)}\n`;
    }

    return summary;
}

module.exports = {
    sanitizeInput,
    sanitizeUserInput,
    buildSystemPrompt,
    buildDaySummary,
    USER_INPUT_MAX_LENGTH,
    CONFIDENCE_FLOOR,
    HEADLINE_MAX_WORDS,
    BRIEFING_LOOKBACK_DAYS,
};
