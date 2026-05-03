/**
 * Tests for the getBriefingMetrics Cloud Function.
 * Verifies admin claim guard (A2) — uses request.auth.token.admin (not redundant verifyIdToken).
 * Mocks Firebase Admin SDK at the boundary (DIP).
 */

jest.mock('firebase-admin', () => ({
    initializeApp: jest.fn(),
    apps: [{}],
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

jest.mock('@google/generative-ai', () => ({
    GoogleGenerativeAI: jest.fn(),
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
    getMetricsForAnalysis: jest.fn().mockResolvedValue({
        totalGenerations: 5,
        averageLatencyMs: 1200,
    }),
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

describe('getBriefingMetrics', () => {
    test('rejects unauthenticated requests', async () => {
        const handler = functions.getBriefingMetrics.handler;
        const request = { auth: null, data: { daysBack: 7 } };

        await expect(handler(request)).rejects.toMatchObject({
            code: 'unauthenticated',
        });
    });

    test('rejects authenticated non-admin users', async () => {
        const handler = functions.getBriefingMetrics.handler;
        const request = {
            auth: { uid: 'regularUser', token: { admin: false } },
            data: { daysBack: 7 },
        };

        await expect(handler(request)).rejects.toMatchObject({
            code: 'permission-denied',
        });
    });

    test('allows admin claim users and returns metrics', async () => {
        const handler = functions.getBriefingMetrics.handler;
        const request = {
            auth: { uid: 'adminUser', token: { admin: true } },
            data: { daysBack: 7 },
        };

        const result = await handler(request);
        expect(result).toBeDefined();
        expect(result.period).toBe('Last 7 days');
    });
});
