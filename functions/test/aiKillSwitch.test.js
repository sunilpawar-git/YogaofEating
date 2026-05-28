/**
 * Tests for the AI analysis kill switch via Firebase Remote Config.
 *
 * TDD Red phase: written BEFORE the kill switch is implemented in index.js.
 *
 * Design:
 *  - `getRemoteConfigBool(key, defaultValue)` reads a boolean flag from RC with
 *    a 5-minute per-instance cache. Fails open (returns defaultValue) on error.
 *  - `ai_analysis_enabled = false` causes all 4 Gemini-calling functions to
 *    return a graceful fallback without calling Gemini.
 *  - `_resetRcCacheForTesting()` is exported ONLY for test isolation.
 *
 * Security: the kill switch is read-only from the server; it cannot be set by
 * client callers. Auth guards are enforced before the kill switch check.
 */

// ── Mock setup ────────────────────────────────────────────────────────────────

let mockGetTemplate;

jest.mock('firebase-admin', () => {
    mockGetTemplate = jest.fn();
    return {
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
        remoteConfig: jest.fn().mockReturnValue({
            get getTemplate() { return mockGetTemplate; },
        }),
    };
});

jest.mock('@google/generative-ai', () => ({
    GoogleGenerativeAI: jest.fn().mockImplementation(() => ({
        getGenerativeModel: jest.fn().mockReturnValue({
            generateContent: jest.fn().mockResolvedValue({
                response: {
                    text: jest.fn().mockReturnValue(JSON.stringify({
                        healthScore: 0.8,
                        mood: 'serene',
                        sound: 'chime',
                        insight: 'Healthy meal.',
                        protein: 30,
                        carbs: 50,
                        fat: 15,
                        estimatedCalories: 455,
                    })),
                },
            }),
        }),
    })),
}));

jest.mock('firebase-functions/params', () => ({
    defineSecret: jest.fn().mockReturnValue({ value: jest.fn().mockReturnValue('test-api-key') }),
}));

jest.mock('../briefingPerformanceMonitor', () => ({
    logGenerationStart: jest.fn().mockResolvedValue(undefined),
    logGenerationError: jest.fn().mockResolvedValue(undefined),
    logGenerationSuccess: jest.fn().mockResolvedValue(undefined),
    getMetricsForAnalysis: jest.fn().mockResolvedValue({}),
}));

let capturedHandlers = {};
jest.mock('firebase-functions/v2/https', () => ({
    onCall: jest.fn().mockImplementation((optionsOrHandler, handler) => {
        const h = handler || optionsOrHandler;
        return { handler: h };
    }),
    HttpsError: class HttpsError extends Error {
        constructor(code, message) {
            super(message);
            this.code = code;
        }
    },
}));

// ── Load module ───────────────────────────────────────────────────────────────

let getRemoteConfigBool, _resetRcCacheForTesting, analyzeMeal, getMealInsight, generateInsight, generateDailyBriefing;

beforeEach(() => {
    jest.resetModules();

    // Fresh module load — required so the RC cache starts clean each test
    mockGetTemplate = jest.fn().mockResolvedValue({
        parameters: {
            ai_analysis_enabled: { defaultValue: { value: 'true' } },
        },
    });

    // Re-apply the admin mock with the fresh mockGetTemplate
    jest.doMock('firebase-admin', () => ({
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
        remoteConfig: jest.fn().mockReturnValue({ getTemplate: mockGetTemplate }),
    }));

    const mod = require('../index');
    getRemoteConfigBool = mod.getRemoteConfigBool;
    _resetRcCacheForTesting = mod._resetRcCacheForTesting;
    analyzeMeal = mod.analyzeMeal;
    getMealInsight = mod.getMealInsight;
    generateInsight = mod.generateInsight;
    generateDailyBriefing = mod.generateDailyBriefing;
});

// ── getRemoteConfigBool unit tests ────────────────────────────────────────────

describe('getRemoteConfigBool', () => {
    test('is exported as an async function', () => {
        expect(typeof getRemoteConfigBool).toBe('function');
    });

    test('returns true when Remote Config value is "true"', async () => {
        mockGetTemplate.mockResolvedValueOnce({
            parameters: { ai_analysis_enabled: { defaultValue: { value: 'true' } } },
        });
        _resetRcCacheForTesting();
        const result = await getRemoteConfigBool('ai_analysis_enabled', true);
        expect(result).toBe(true);
    });

    test('returns false when Remote Config value is "false"', async () => {
        mockGetTemplate.mockResolvedValueOnce({
            parameters: { ai_analysis_enabled: { defaultValue: { value: 'false' } } },
        });
        _resetRcCacheForTesting();
        const result = await getRemoteConfigBool('ai_analysis_enabled', true);
        expect(result).toBe(false);
    });

    test('returns defaultValue when key is absent from Remote Config', async () => {
        mockGetTemplate.mockResolvedValueOnce({ parameters: {} });
        _resetRcCacheForTesting();
        const result = await getRemoteConfigBool('ai_analysis_enabled', true);
        expect(result).toBe(true);
    });

    test('fails open: returns defaultValue when Remote Config fetch throws', async () => {
        mockGetTemplate.mockRejectedValueOnce(new Error('network timeout'));
        _resetRcCacheForTesting();
        const result = await getRemoteConfigBool('ai_analysis_enabled', true);
        expect(result).toBe(true);
    });

    test('fails open: returns false defaultValue when Remote Config fetch throws', async () => {
        mockGetTemplate.mockRejectedValueOnce(new Error('network timeout'));
        _resetRcCacheForTesting();
        const result = await getRemoteConfigBool('some_flag', false);
        expect(result).toBe(false);
    });

    test('caches result: calls getTemplate only once for repeated reads within TTL', async () => {
        mockGetTemplate.mockResolvedValue({
            parameters: { ai_analysis_enabled: { defaultValue: { value: 'true' } } },
        });
        _resetRcCacheForTesting();
        await getRemoteConfigBool('ai_analysis_enabled', true);
        await getRemoteConfigBool('ai_analysis_enabled', true);
        await getRemoteConfigBool('ai_analysis_enabled', true);
        expect(mockGetTemplate).toHaveBeenCalledTimes(1);
    });

    test('_resetRcCacheForTesting clears cache, causing next call to re-fetch', async () => {
        mockGetTemplate.mockResolvedValue({
            parameters: { ai_analysis_enabled: { defaultValue: { value: 'true' } } },
        });
        _resetRcCacheForTesting();
        await getRemoteConfigBool('ai_analysis_enabled', true);
        _resetRcCacheForTesting();
        await getRemoteConfigBool('ai_analysis_enabled', true);
        expect(mockGetTemplate).toHaveBeenCalledTimes(2);
    });
});

// ── analyzeMeal kill switch ───────────────────────────────────────────────────

describe('analyzeMeal kill switch', () => {
    const validRequest = {
        auth: { uid: 'user123', token: {} },
        data: { description: 'oats with banana and almonds' },
    };

    test('returns fallback without calling Gemini when ai_analysis_enabled is false', async () => {
        mockGetTemplate.mockResolvedValue({
            parameters: { ai_analysis_enabled: { defaultValue: { value: 'false' } } },
        });
        _resetRcCacheForTesting();
        const { GoogleGenerativeAI } = require('@google/generative-ai');
        const result = await analyzeMeal.handler(validRequest);

        expect(result.healthScore).toBe(0.5);
        expect(result.mood).toBe('neutral');
        expect(result.estimatedCalories).toBeNull();
        // Gemini must NOT have been called
        const mockInstance = GoogleGenerativeAI.mock.results[0]?.value;
        if (mockInstance) {
            expect(mockInstance.getGenerativeModel().generateContent).not.toHaveBeenCalled();
        }
    });

    test('proceeds with Gemini when ai_analysis_enabled is true', async () => {
        mockGetTemplate.mockResolvedValue({
            parameters: { ai_analysis_enabled: { defaultValue: { value: 'true' } } },
        });
        _resetRcCacheForTesting();
        const result = await analyzeMeal.handler(validRequest);
        // Real Gemini mock returns 0.8; kill switch fallback returns 0.5
        expect(result.healthScore).toBe(0.8);
    });

    test('proceeds with Gemini when ai_analysis_enabled key is absent (fail open)', async () => {
        mockGetTemplate.mockResolvedValue({ parameters: {} });
        _resetRcCacheForTesting();
        const result = await analyzeMeal.handler(validRequest);
        expect(result.healthScore).toBe(0.8);
    });
});

// ── getMealInsight kill switch ────────────────────────────────────────────────

describe('getMealInsight kill switch', () => {
    const validRequest = {
        auth: { uid: 'user123', token: {} },
        data: { mealItems: ['oats', 'banana'], mealType: 'breakfast', healthScore: 0.75 },
    };

    test('returns fallback when ai_analysis_enabled is false', async () => {
        mockGetTemplate.mockResolvedValue({
            parameters: { ai_analysis_enabled: { defaultValue: { value: 'false' } } },
        });
        _resetRcCacheForTesting();
        const result = await getMealInsight.handler(validRequest);
        expect(typeof result.summary).toBe('string');
        expect(result.summary.length).toBeGreaterThan(0);
        expect(Array.isArray(result.nutritionHighlights)).toBe(true);
    });
});

// ── generateInsight kill switch ───────────────────────────────────────────────

describe('generateInsight kill switch', () => {
    const validRequest = {
        auth: { uid: 'user123', token: {} },
        data: {
            userData: [{ date: '2026-05-28', isToday: true, meals: [], averageHealthScore: 0.7 }],
        },
    };

    test('throws unavailable when ai_analysis_enabled is false', async () => {
        mockGetTemplate.mockResolvedValue({
            parameters: { ai_analysis_enabled: { defaultValue: { value: 'false' } } },
        });
        _resetRcCacheForTesting();
        await expect(generateInsight.handler(validRequest))
            .rejects.toMatchObject({ code: 'unavailable' });
    });
});

// ── generateDailyBriefing kill switch ─────────────────────────────────────────

describe('generateDailyBriefing kill switch', () => {
    const validRequest = {
        auth: { uid: 'user123', token: {} },
        data: {
            userData: [{ date: '2026-05-28', isToday: true, meals: [], averageHealthScore: 0.7 }],
            nudgeHistory: [],
        },
    };

    test('throws unavailable when ai_analysis_enabled is false', async () => {
        mockGetTemplate.mockResolvedValue({
            parameters: { ai_analysis_enabled: { defaultValue: { value: 'false' } } },
        });
        _resetRcCacheForTesting();
        await expect(generateDailyBriefing.handler(validRequest))
            .rejects.toMatchObject({ code: 'unavailable' });
    });
});
