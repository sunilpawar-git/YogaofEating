/**
 * Firestore-backed per-user rate limiter for Cloud Functions.
 *
 * Uses daily windows (UTC midnight) so limits are intuitive and predictable.
 * The admin SDK bypasses Firestore Security Rules, so rate_limits documents
 * are writable only by Cloud Functions — never by clients.
 *
 * Limits are generous for a genuine daily-use meal journal but prevent
 * runaway cost from a compromised token or abusive script.
 */

const admin = require('firebase-admin');
const { HttpsError } = require('firebase-functions/v2/https');

/** Daily call limits per authenticated user, per function. */
const DAILY_LIMITS = {
    analyzeMeal: 150,          // 5 meals × up to 30 edits each
    getMealInsight: 100,
    generateInsight: 30,
    generateDailyBriefing: 15,
};

/**
 * Checks and increments the daily call counter for a user+operation pair.
 * Throws HttpsError('resource-exhausted') if the daily limit is exceeded.
 *
 * @param {string} userId    - Firebase Auth UID
 * @param {string} operation - Function name key (must match DAILY_LIMITS)
 */
async function checkRateLimit(userId, operation) {
    const limit = DAILY_LIMITS[operation];
    if (!limit) return; // No limit defined — allow through

    const db = admin.firestore();
    const todayKey = new Date().toISOString().slice(0, 10); // "YYYY-MM-DD" UTC
    const docRef = db.doc(`rate_limits/${userId}`);

    await db.runTransaction(async (t) => {
        const snap = await t.get(docRef);
        const data = snap.exists ? snap.data() : {};
        const opData = data[operation] || {};

        const count = opData.day === todayKey ? (opData.count || 0) : 0;

        if (count >= limit) {
            throw new HttpsError(
                'resource-exhausted',
                `Daily limit reached for ${operation}. Please try again tomorrow.`
            );
        }

        t.set(
            docRef,
            { [operation]: { day: todayKey, count: count + 1 } },
            { merge: true }
        );
    });
}

module.exports = { checkRateLimit, DAILY_LIMITS };
