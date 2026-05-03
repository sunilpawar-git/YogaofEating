/**
 * Tests for the generateDailyBriefing Cloud Function.
 * Verifies auth guard, happy path, and invalid-argument handling (D3).
 * Mocks Firebase Admin SDK and Gemini client at the boundary (DIP).
 */

jest.mock('firebase-admin', () => ({
    initializeApp: jest.fn(),
    apps: [{}],
    auth: jest.fn().mockReturnValue({ verifyIdToken: jest.fn() }),
    firestore: jest.fn().mockReturnValue({
        collection: jest.fn().mockReturnValue({
            doc: jest.fn().mockReturnValue({
                set: jest.fn().mockResolvedValue(undefined),
                get: jest.fn().mockResolvedValue({ exists: false }),
            }),
        }),
    }),
}));

jest.mock('@google/generative-ai', () => ({
    GoogleGenerativeAI: jest.fn().mockImplementation(() => ({
        getGenerativeModel: jest.fn().mockReturnValue({
            generateContent: jest.fn().mockResolvedValue({
                response: {
                    text: jest.fn().mockReturnValue(
                        JSON.stringify({
                            headline: 'Great start to the week!',
                            correlationCards: [],
                            nudge: { suggestion: 'Eat more vegetables', reasoning: 'Pattern analysis' },
                            weeklyTrend: null,
                        })
                    ),
                },
            }),
        }),
    })),
}));

jest.mock('firebase-functions/params', () => ({
    defineSecret: jest.fn().mockReturnValue({
        value: jest.fn().mockReturnValue('test-api-key'),
    }),
}));

jest.mock('../briefingPerformanceMonitor', () => ({
    logGenerationStart: jest.fn().mockResolvedValue(undefined),
    logGenerationError: jest.fn().mockResolvedValue(undefined),
    logGenerationSuccess: jest.fn().mockResolvedValue(undefined),
    logAPILatency: jest.fn().mockResolvedValue(undefined),
    logGenerationComplete: jest.fn().mockResolvedValue(undefined),
    getMetricsForAnalysis: jest.fn().mockResolvedValue({}),
}));

jest.mock('firebase-functions/v2/https', () => ({
    onCall: jest.fn().mockImplementation((optionsOrHandler, handler) => ({
        handler: handler || optionsOrHandler,
    })),
    HttpsError: class HttpsError extends Error {
        constructor(code, message) {
            super(message);
            this.code = code;
        }
    },
}));

const functions = require('../index');

const validUserData = Array.from({ length: 7 }, (_, i) => ({
    date: `Day ${i + 1}`,
    isToday: i === 6,
    meals: [{ items: ['rice', 'lentils'] }],
    averageHealthScore: 0.6,
}));

describe('generateDailyBriefing', () => {
    test('rejects unauthenticated calls', async () => {
        const handler = functions.generateDailyBriefing.handler;
        const request = { auth: null, data: { userData: validUserData } };

        await expect(handler(request)).rejects.toMatchObject({
            code: 'unauthenticated',
        });
    });

    test('rejects empty userData array', async () => {
        const handler = functions.generateDailyBriefing.handler;
        const request = {
            auth: { uid: 'user123', token: {} },
            data: { userData: [] },
        };

        await expect(handler(request)).rejects.toMatchObject({
            code: 'invalid-argument',
        });
    });

    test('returns structured briefing for authenticated user with valid data', async () => {
        const handler = functions.generateDailyBriefing.handler;
        const request = {
            auth: { uid: 'user123', token: {} },
            data: { userData: validUserData },
        };

        const result = await handler(request);
        expect(result).toBeDefined();
        expect(result.headline).toBeDefined();
    });
});
