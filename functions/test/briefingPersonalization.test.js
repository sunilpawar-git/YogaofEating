/**
 * Tests for Phase 4 — Cloud Function Personalization + Prompt Injection Defense.
 * Directly tests pure helper functions in briefingHelpers.js (no Firebase mocks needed).
 */

const {
    sanitizeUserInput,
    buildSystemPrompt,
    buildDaySummary,
    USER_INPUT_MAX_LENGTH,
} = require('../briefingHelpers');

describe('sanitizeUserInput', () => {
    test('strips characters outside the allowlist', () => {
        const input = 'Alex<br/>; DROP TABLE--{override}';
        const result = sanitizeUserInput(input);
        expect(result).not.toContain('<');
        expect(result).not.toContain('>');
        expect(result).not.toContain('{');
        expect(result).not.toContain('}');
        expect(result).not.toContain(';');
        expect(result).toContain('Alex');
    });

    test('enforces max length', () => {
        const longInput = 'a'.repeat(200);
        const result = sanitizeUserInput(longInput, USER_INPUT_MAX_LENGTH);
        expect(result.length).toBeLessThanOrEqual(USER_INPUT_MAX_LENGTH);
    });

    test('handles non-string input safely', () => {
        expect(sanitizeUserInput(null)).toBe('');
        expect(sanitizeUserInput(undefined)).toBe('');
        expect(sanitizeUserInput(42)).toBe('');
    });
});

describe('buildSystemPrompt', () => {
    test('withoutUserContext_usesGenericCoaching', () => {
        const result = buildSystemPrompt(null);
        expect(result).toContain('compassionate wellness coach');
        expect(result).not.toContain('coaching '); // no name prefix
    });

    test('withUserContext_promptContainsName', () => {
        const result = buildSystemPrompt({ name: 'Alex', activityLevel: 'Lightly Active' });
        expect(result).toContain('Alex');
    });

    test('withUserContext_promptContainsActivityLevel', () => {
        const result = buildSystemPrompt({ name: 'Alex', activityLevel: 'Moderately Active' });
        expect(result).toContain('Moderately Active');
    });

    test('withUserContext_promptContainsDietaryGoal', () => {
        const result = buildSystemPrompt({
            name: 'Alex',
            activityLevel: 'Moderately Active',
            dietaryGoal: 'Heart Health',
        });
        expect(result).toContain('Heart Health');
    });

    test('withEmptyName_omitsNameFromPrompt', () => {
        const result = buildSystemPrompt({ name: '', activityLevel: 'Sedentary' });
        expect(result).not.toMatch(/coaching\s+[A-Z]/); // no "coaching <Name>"
    });

    test('noSensitiveDataInConsoleLog', () => {
        const consoleSpy = jest.spyOn(console, 'log').mockImplementation(() => {});
        const consoleInfoSpy = jest.spyOn(console, 'info').mockImplementation(() => {});
        buildSystemPrompt({ name: 'SensitiveName', activityLevel: 'Moderately Active' });
        const loggedArgs = [...consoleSpy.mock.calls, ...consoleInfoSpy.mock.calls].flat().join(' ');
        expect(loggedArgs).not.toContain('SensitiveName');
        consoleSpy.mockRestore();
        consoleInfoSpy.mockRestore();
    });
});

describe('buildDaySummary', () => {
    test('unreviewedTodo_displayedAsPending_notFailed', () => {
        const day = {
            date: 'Monday',
            todos: [{ category: 'To-Do', text: 'Exercise', isAccomplished: 'unreviewed' }],
        };
        const result = buildDaySummary(day);
        expect(result).toContain('pending');
        expect(result).not.toContain('failed');
        // "0/1 completed" is acceptable — key is "pending" is visible
        expect(result).toMatch(/Todos:/);
    });

    test('accomplishedTodo_countedCorrectly', () => {
        const day = {
            date: 'Tuesday',
            todos: [
                { category: 'To-Do', text: 'Run', isAccomplished: 'true' },
                { category: 'To-Do', text: 'Meditate', isAccomplished: 'false' },
            ],
        };
        const result = buildDaySummary(day);
        expect(result).toContain('1/2 completed');
    });
});
