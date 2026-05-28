/**
 * Tests for GEMINI_CONFIG — verifies SSOT model configuration.
 *
 * TDD Red phase: written BEFORE GEMINI_CONFIG is introduced in index.js.
 * These tests fail until the implementation lands in Phase 1 & 2.
 *
 * SRP: This file only tests the model config shape — no function logic tested here.
 * SSOT: All model IDs and generation configs must live in GEMINI_CONFIG; nowhere else.
 */

// ── Standard mock harness ─────────────────────────────────────────────────────

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
                response: { text: jest.fn().mockReturnValue('{}') },
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

// ── Load module under test ────────────────────────────────────────────────────

const { GEMINI_CONFIG } = require('../index');

// ── Tests ─────────────────────────────────────────────────────────────────────

describe('GEMINI_CONFIG', () => {
    test('is exported from index.js', () => {
        expect(GEMINI_CONFIG).toBeDefined();
        expect(typeof GEMINI_CONFIG).toBe('object');
    });

    test('has all required function-level keys', () => {
        expect(GEMINI_CONFIG).toHaveProperty('mealAnalysis');
        expect(GEMINI_CONFIG).toHaveProperty('mealInsight');
        expect(GEMINI_CONFIG).toHaveProperty('dailyInsight');
        expect(GEMINI_CONFIG).toHaveProperty('dailyBriefing');
    });

    // ── Model ID assertions (Phase 2: upgrade to gemini-2.5-flash) ─────────────

    test('mealAnalysis uses gemini-2.5-flash', () => {
        expect(GEMINI_CONFIG.mealAnalysis.modelId).toBe('gemini-2.5-flash');
    });

    test('mealInsight uses gemini-2.5-flash', () => {
        expect(GEMINI_CONFIG.mealInsight.modelId).toBe('gemini-2.5-flash');
    });

    test('dailyInsight uses gemini-2.5-flash', () => {
        expect(GEMINI_CONFIG.dailyInsight.modelId).toBe('gemini-2.5-flash');
    });

    test('dailyBriefing uses gemini-2.5-flash', () => {
        expect(GEMINI_CONFIG.dailyBriefing.modelId).toBe('gemini-2.5-flash');
    });

    // ── Generation config assertions (Phase 2: thinking budget) ────────────────

    test('mealAnalysis has thinkingBudget 0 (no reasoning for structured JSON task)', () => {
        const cfg = GEMINI_CONFIG.mealAnalysis.generationConfig;
        expect(cfg).toBeDefined();
        expect(cfg.thinkingConfig).toBeDefined();
        expect(cfg.thinkingConfig.thinkingBudget).toBe(0);
    });

    test('dailyBriefing has no thinkingBudget restriction (full reasoning for complex synthesis)', () => {
        const cfg = GEMINI_CONFIG.dailyBriefing.generationConfig;
        // null/undefined generationConfig OR no thinkingConfig means full thinking is enabled
        const forcesZeroThinking =
            cfg != null &&
            cfg.thinkingConfig != null &&
            cfg.thinkingConfig.thinkingBudget === 0;
        expect(forcesZeroThinking).toBe(false);
    });

    // ── Shape invariants ────────────────────────────────────────────────────────

    test('each config entry has a non-empty modelId string', () => {
        Object.entries(GEMINI_CONFIG).forEach(([key, cfg]) => {
            expect(typeof cfg.modelId).toBe('string');
            expect(cfg.modelId.length).toBeGreaterThan(0);
        });
    });

    test('each config entry has a generationConfig property (null is acceptable for defaults)', () => {
        Object.entries(GEMINI_CONFIG).forEach(([key, cfg]) => {
            // generationConfig must exist as a key (even if null means "use defaults")
            expect(Object.prototype.hasOwnProperty.call(cfg, 'generationConfig')).toBe(true);
        });
    });
});
