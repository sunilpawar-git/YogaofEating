/**
 * Tests for the generateInsight Cloud Function.
 * Verifies auth guard (A1) and input validation.
 * Mocks Firebase Admin SDK and Gemini client at the boundary (DIP).
 */

// Mock firebase-admin before requiring functions
jest.mock('firebase-admin', () => ({
    initializeApp: jest.fn(),
    apps: [{}], // pretend already initialized
    auth: jest.fn().mockReturnValue({
        verifyIdToken: jest.fn(),
    }),
    firestore: jest.fn().mockReturnValue({
        collection: jest.fn().mockReturnValue({
            doc: jest.fn().mockReturnValue({
                set: jest.fn().mockResolvedValue(undefined),
                get: jest.fn().mockResolvedValue({ exists: false }),
            }),
        }),
    }),
}));

// Mock Gemini SDK
jest.mock('@google/generative-ai', () => ({
    GoogleGenerativeAI: jest.fn().mockImplementation(() => ({
        getGenerativeModel: jest.fn().mockReturnValue({
            generateContent: jest.fn().mockResolvedValue({
                response: {
                    text: jest.fn().mockReturnValue(
                        JSON.stringify({
                            insightText: 'Your sleep is better on salad days.',
                            insightType: 'foodSleep',
                            confidence: 0.8,
                        })
                    ),
                },
            }),
        }),
    })),
}));

// Mock firebase-functions params (secret)
jest.mock('firebase-functions/params', () => ({
    defineSecret: jest.fn().mockReturnValue({
        value: jest.fn().mockReturnValue('test-api-key'),
    }),
}));

// Mock the briefingPerformanceMonitor
jest.mock('../briefingPerformanceMonitor', () => ({
    logGenerationStart: jest.fn().mockResolvedValue(undefined),
    logGenerationError: jest.fn().mockResolvedValue(undefined),
    logGenerationSuccess: jest.fn().mockResolvedValue(undefined),
    getMetricsForAnalysis: jest.fn().mockResolvedValue({}),
}));

// Stub onCall to extract the handler function for direct unit testing
let capturedHandlers = {};
jest.mock('firebase-functions/v2/https', () => ({
    onCall: jest.fn().mockImplementation((optionsOrHandler, handler) => {
        return { handler: handler || optionsOrHandler };
    }),
    HttpsError: class HttpsError extends Error {
        constructor(code, message) {
            super(message);
            this.code = code;
        }
    },
}));

// Load index.js after all mocks are in place
const functions = require('../index');
const { HttpsError } = require('firebase-functions/v2/https');

// Helper: build a valid userData payload
const validUserData = [
    {
        date: 'Monday',
        isToday: true,
        meals: [{ items: ['salad', 'water'] }],
        averageHealthScore: 0.75,
    },
];

describe('generateInsight', () => {
    test('rejects unauthenticated calls with HttpsError unauthenticated', async () => {
        const handler = functions.generateInsight.handler;
        const request = { auth: null, data: { userData: validUserData } };

        await expect(handler(request)).rejects.toMatchObject({
            code: 'unauthenticated',
        });
    });

    test('rejects missing userData with HttpsError invalid-argument', async () => {
        const handler = functions.generateInsight.handler;
        const request = {
            auth: { uid: 'user123', token: {} },
            data: { userData: [] }, // empty array is invalid
        };

        await expect(handler(request)).rejects.toMatchObject({
            code: 'invalid-argument',
        });
    });

    test('rejects null userData with HttpsError invalid-argument', async () => {
        const handler = functions.generateInsight.handler;
        const request = {
            auth: { uid: 'user123', token: {} },
            data: {},
        };

        await expect(handler(request)).rejects.toMatchObject({
            code: 'invalid-argument',
        });
    });

    test('accepts authenticated calls with valid data', async () => {
        const handler = functions.generateInsight.handler;
        const request = {
            auth: { uid: 'user123', token: {} },
            data: { userData: validUserData },
        };

        const result = await handler(request);
        expect(result).toBeDefined();
    });
});
