#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    @MainActor
    final class InputValidationTests: XCTestCase {
        // MARK: - Meal Description Validation

        func test_mealDescription_emptyStringIsRejected() {
            let result = InputValidator.validateMealDescription("")
            XCTAssertThrowsError(try result.get())
        }

        func test_mealDescription_whitespaceOnlyIsRejected() {
            let result = InputValidator.validateMealDescription("   \n  \t  ")
            XCTAssertThrowsError(try result.get())
        }

        func test_mealDescription_exceedingMaxLengthIsRejected() {
            let tooLong = String(repeating: "x", count: InputValidator.mealDescriptionMaxLength + 1)
            let result = InputValidator.validateMealDescription(tooLong)
            XCTAssertThrowsError(try result.get())
        }

        func test_mealDescription_exactlyAtMaxLengthPasses() {
            let exactMax = String(repeating: "x", count: InputValidator.mealDescriptionMaxLength)
            let result = InputValidator.validateMealDescription(exactMax)
            XCTAssertNoThrow(try result.get())
        }

        func test_mealDescription_validInputPasses() {
            let valid = "Grilled chicken with vegetables"
            let result = InputValidator.validateMealDescription(valid)
            XCTAssertEqual(try result.get(), valid)
        }

        func test_mealDescription_whitespaceIsTrimmed() {
            let padded = "  grilled chicken  "
            let result = InputValidator.validateMealDescription(padded)
            XCTAssertEqual(try result.get(), "grilled chicken")
        }

        func test_mealDescription_sqlInjectionIsDetected() {
            let sqlInjection = "'; DROP TABLE meals; --"
            let result = InputValidator.validateMealDescription(sqlInjection)
            XCTAssertThrowsError(try result.get())
        }

        func test_mealDescription_deleteFromInjectionIsDetected() {
            let injection = "anything DELETE FROM users WHERE 1=1"
            let result = InputValidator.validateMealDescription(injection)
            XCTAssertThrowsError(try result.get())
        }

        func test_mealDescription_insertIntoInjectionIsDetected() {
            let injection = "INSERT INTO admin VALUES (1, 'hacker')"
            let result = InputValidator.validateMealDescription(injection)
            XCTAssertThrowsError(try result.get())
        }

        func test_mealDescription_commandSubstitutionIsDetected() {
            let injection = "$(rm -rf /)"
            let result = InputValidator.validateMealDescription(injection)
            XCTAssertThrowsError(try result.get())
        }

        func test_mealDescription_commandSubstitutionBracesIsDetected() {
            let injection = "${IFS}cat${IFS}/etc/passwd"
            let result = InputValidator.validateMealDescription(injection)
            XCTAssertThrowsError(try result.get())
        }

        func test_mealDescription_shellScriptIsDetected() {
            let injection = "#!/bin/bash\nrm -rf /"
            let result = InputValidator.validateMealDescription(injection)
            XCTAssertThrowsError(try result.get())
        }

        func test_mealDescription_xssScriptTagIsDetected() {
            let xss = "<script>alert('hacked')</script>"
            let result = InputValidator.validateMealDescription(xss)
            XCTAssertThrowsError(try result.get())
        }

        func test_mealDescription_xssJavaScriptProtocolIsDetected() {
            let xss = "javascript:void(0)"
            let result = InputValidator.validateMealDescription(xss)
            XCTAssertThrowsError(try result.get())
        }

        func test_mealDescription_evalIsDetected() {
            let injection = "eval(maliciousCode)"
            let result = InputValidator.validateMealDescription(injection)
            XCTAssertThrowsError(try result.get())
        }

        func test_mealDescription_execIsDetected() {
            let injection = "exec(command)"
            let result = InputValidator.validateMealDescription(injection)
            XCTAssertThrowsError(try result.get())
        }

        func test_mealDescription_controlCharactersAreRemoved() {
            let withControl = "salad\0\u{0001}\u{001F}"
            let result = InputValidator.validateMealDescription(withControl)
            do {
                let sanitized = try result.get()
                XCTAssertEqual(sanitized, "salad")
            } catch {
                XCTFail("Should not have thrown: \(error)")
            }
        }

        func test_mealDescription_nullByteIsRemoved() {
            let withNull = "chicken\0with\0rice"
            let result = InputValidator.validateMealDescription(withNull)
            do {
                let sanitized = try result.get()
                XCTAssertEqual(sanitized, "chickenwithrice")
            } catch {
                XCTFail("Should not have thrown: \(error)")
            }
        }

        // MARK: - Journal Entry Validation

        func test_journalEntry_emptyStringIsRejected() {
            let result = InputValidator.validateJournalEntry("")
            XCTAssertThrowsError(try result.get())
        }

        func test_journalEntry_whitespaceOnlyIsRejected() {
            let result = InputValidator.validateJournalEntry("   \n\n\t")
            XCTAssertThrowsError(try result.get())
        }

        func test_journalEntry_exceedingMaxLengthIsRejected() {
            let tooLong = String(repeating: "x", count: InputValidator.journalEntryMaxLength + 1)
            let result = InputValidator.validateJournalEntry(tooLong)
            XCTAssertThrowsError(try result.get())
        }

        func test_journalEntry_validInputPasses() {
            let valid = "Today was a good day. I had a healthy breakfast and exercised."
            let result = InputValidator.validateJournalEntry(valid)
            XCTAssertEqual(try result.get(), valid)
        }

        func test_journalEntry_whitespaceIsTrimmed() {
            let padded = "\n\n  journal entry  \n\n"
            let result = InputValidator.validateJournalEntry(padded)
            XCTAssertEqual(try result.get(), "journal entry")
        }

        func test_journalEntry_sqlInjectionIsDetected() {
            let injection = "'; DROP TABLE reflections; --"
            let result = InputValidator.validateJournalEntry(injection)
            XCTAssertThrowsError(try result.get())
        }

        func test_journalEntry_commandInjectionIsDetected() {
            let injection = "My day $(malicious_command)"
            let result = InputValidator.validateJournalEntry(injection)
            XCTAssertThrowsError(try result.get())
        }

        // MARK: - Sleep Notes Validation

        func test_sleepNotes_emptyStringPasses() {
            let result = InputValidator.validateSleepNotes("")
            XCTAssertNoThrow(try result.get())
        }

        func test_sleepNotes_whitespaceOnlyBecomesEmpty() {
            let result = InputValidator.validateSleepNotes("   \n  \t  ")
            XCTAssertEqual(try result.get(), "")
        }

        func test_sleepNotes_exceedingMaxLengthIsRejected() {
            let tooLong = String(repeating: "x", count: InputValidator.sleepNotesMaxLength + 1)
            let result = InputValidator.validateSleepNotes(tooLong)
            XCTAssertThrowsError(try result.get())
        }

        func test_sleepNotes_validInputPasses() {
            let valid = "Slept well, felt refreshed"
            let result = InputValidator.validateSleepNotes(valid)
            XCTAssertEqual(try result.get(), valid)
        }

        func test_sleepNotes_whitespaceIsTrimmed() {
            let padded = "  good sleep  "
            let result = InputValidator.validateSleepNotes(padded)
            XCTAssertEqual(try result.get(), "good sleep")
        }

        func test_sleepNotes_sqlInjectionIsDetected() {
            let injection = "Bad sleep'; DELETE FROM sleep_data; --"
            let result = InputValidator.validateSleepNotes(injection)
            XCTAssertThrowsError(try result.get())
        }

        // MARK: - Morning Thoughts Validation

        func test_morningThoughts_emptyStringPasses() {
            let result = InputValidator.validateMorningThoughts("")
            XCTAssertNoThrow(try result.get())
        }

        func test_morningThoughts_whitespaceOnlyBecomesEmpty() {
            let result = InputValidator.validateMorningThoughts("  \n\n  ")
            XCTAssertEqual(try result.get(), "")
        }

        func test_morningThoughts_exceedingMaxLengthIsRejected() {
            let tooLong = String(repeating: "x", count: InputValidator.morningThoughtsMaxLength + 1)
            let result = InputValidator.validateMorningThoughts(tooLong)
            XCTAssertThrowsError(try result.get())
        }

        func test_morningThoughts_validInputPasses() {
            let valid = "Today I want to focus on my health and be mindful."
            let result = InputValidator.validateMorningThoughts(valid)
            XCTAssertEqual(try result.get(), valid)
        }

        func test_morningThoughts_whitespaceIsTrimmed() {
            let padded = "  \n  morning thoughts  \n  "
            let result = InputValidator.validateMorningThoughts(padded)
            XCTAssertEqual(try result.get(), "morning thoughts")
        }

        // MARK: - To-Do Item Validation

        func test_todoItem_emptyStringIsRejected() {
            let result = InputValidator.validateTodoItem("")
            XCTAssertThrowsError(try result.get())
        }

        func test_todoItem_whitespaceOnlyIsRejected() {
            let result = InputValidator.validateTodoItem("   \t\n")
            XCTAssertThrowsError(try result.get())
        }

        func test_todoItem_exceedingMaxLengthIsRejected() {
            let tooLong = String(repeating: "x", count: InputValidator.todoItemMaxLength + 1)
            let result = InputValidator.validateTodoItem(tooLong)
            XCTAssertThrowsError(try result.get())
        }

        func test_todoItem_validInputPasses() {
            let valid = "Exercise for 30 minutes"
            let result = InputValidator.validateTodoItem(valid)
            XCTAssertEqual(try result.get(), valid)
        }

        func test_todoItem_whitespaceIsTrimmed() {
            let padded = "  buy groceries  "
            let result = InputValidator.validateTodoItem(padded)
            XCTAssertEqual(try result.get(), "buy groceries")
        }

        func test_todoItem_shortValidInputPasses() {
            let short = "Run"
            let result = InputValidator.validateTodoItem(short)
            XCTAssertEqual(try result.get(), "Run")
        }

        func test_todoItem_sqlInjectionIsDetected() {
            let injection = "task'; DROP TABLE todos; --"
            let result = InputValidator.validateTodoItem(injection)
            XCTAssertThrowsError(try result.get())
        }

        // MARK: - Common Pattern Detection

        func test_caseInsensitiveSqlPatternDetection() {
            let lower = "drop table users"
            let result = InputValidator.validateMealDescription(lower)
            XCTAssertThrowsError(try result.get())
        }

        func test_caseInsensitiveSqlPatternWithMixedCase() {
            let mixed = "DroP TaBle meals"
            let result = InputValidator.validateMealDescription(mixed)
            XCTAssertThrowsError(try result.get())
        }

        func test_multipleControlCharactersAreRemoved() {
            let input = "test\0\u{0001}\u{001F}data"
            let result = InputValidator.validateMealDescription(input)
            do {
                let sanitized = try result.get()
                XCTAssertEqual(sanitized, "testdata")
            } catch {
                XCTFail("Should not have thrown: \(error)")
            }
        }

        // MARK: - XSS Pattern Refinement (Phase 3)

        func test_comparisonOperatorLessThanWithNumber() {
            let input = "< 100g"
            let result = InputValidator.validateMealDescription(input)
            XCTAssertEqual(try result.get(), input)
        }

        func test_comparisonOperatorGreaterThanWithNumber() {
            let input = "> 5 servings"
            let result = InputValidator.validateMealDescription(input)
            XCTAssertEqual(try result.get(), input)
        }

        func test_comparisonOperatorInContext() {
            let input = "Protein > fat, < 100g total"
            let result = InputValidator.validateMealDescription(input)
            XCTAssertEqual(try result.get(), input)
        }

        func test_htmlScriptTagIsStillDetected() {
            let input = "<script>alert('xss')</script>"
            let result = InputValidator.validateMealDescription(input)
            XCTAssertThrowsError(try result.get())
        }

        func test_htmlImgTagIsDetected() {
            let input = "Food <img src=x onerror=alert('xss')>"
            let result = InputValidator.validateMealDescription(input)
            XCTAssertThrowsError(try result.get())
        }

        func test_htmlIframeTagIsDetected() {
            let input = "<iframe src='malicious'></iframe>"
            let result = InputValidator.validateMealDescription(input)
            XCTAssertThrowsError(try result.get())
        }

        func test_onclickEventHandlerIsDetected() {
            let input = "Click me onclick=alert('xss')"
            let result = InputValidator.validateMealDescription(input)
            XCTAssertThrowsError(try result.get())
        }

        func test_onmouseoverEventHandlerIsDetected() {
            let input = "Hover here onmouseover=maliciousFunction()"
            let result = InputValidator.validateMealDescription(input)
            XCTAssertThrowsError(try result.get())
        }

        // MARK: - Edge Cases

        func test_validInputWithNumbers() {
            let input = "Ate 2 apples and 3 bananas"
            let result = InputValidator.validateMealDescription(input)
            XCTAssertEqual(try result.get(), input)
        }

        func test_validInputWithSpecialCharacters() {
            let input = "Coffee & toast @ 8:30 AM"
            let result = InputValidator.validateMealDescription(input)
            XCTAssertEqual(try result.get(), input)
        }

        func test_validInputWithEmojis() {
            let input = "Salad 🥗 with 🍅 tomatoes"
            let result = InputValidator.validateMealDescription(input)
            XCTAssertEqual(try result.get(), input)
        }

        func test_validInputWithNewlines() {
            let input = "Breakfast:\nOatmeal\nFruit"
            let result = InputValidator.validateJournalEntry(input)
            XCTAssertEqual(try result.get(), input)
        }

        // MARK: - Error Message Content

        func test_emptyStringError_describesMissingInput() {
            let result = InputValidator.validateMealDescription("")
            do {
                _ = try result.get()
                XCTFail("Should have thrown error")
            } catch {
                XCTAssertTrue(error.localizedDescription.contains("empty") ||
                    error.localizedDescription.contains("required") ||
                    error.localizedDescription.contains("Empty"))
            }
        }

        func test_lengthError_describesLimitExceeded() {
            let tooLong = String(repeating: "x", count: InputValidator.mealDescriptionMaxLength + 1)
            let result = InputValidator.validateMealDescription(tooLong)
            do {
                _ = try result.get()
                XCTFail("Should have thrown error")
            } catch {
                XCTAssertTrue(error.localizedDescription.contains("exceeds") ||
                    error.localizedDescription.contains("limit") ||
                    error.localizedDescription.contains("length"))
            }
        }

        func test_suspiciousPatternError_describesMaliciousContent() {
            let result = InputValidator.validateMealDescription("<script>alert('xss')</script>")
            do {
                _ = try result.get()
                XCTFail("Should have thrown error")
            } catch {
                XCTAssertTrue(error.localizedDescription.contains("invalid") ||
                    error.localizedDescription.contains("character") ||
                    error.localizedDescription.contains("suspicious"))
            }
        }
    }

    // MARK: - Helper for XCTAssertNoThrow

    extension InputValidationTests {
        func XCTAssertNoThrow(
            _ expression: @autoclosure () throws -> some Any,
            _ message: @autoclosure () -> String = ""
        ) {
            do {
                _ = try expression()
            } catch {
                XCTFail("Expected no throw, but caught: \(error). \(message())")
            }
        }

        // MARK: - Phase B RED: Control character allowlist hardening

        /// Tab characters (0x09) serve no purpose in food descriptions and must be stripped.
        /// Current bug: isControl explicitly allows 0x09, so tabs survive sanitisation.
        func test_mealDescription_tabCharacter_isStripped() throws {
            let withTab = "salad\tand\tdressing"
            let sanitized = try InputValidator.validateMealDescription(withTab).get()
            XCTAssertFalse(
                sanitized.contains("\t"),
                "Tab characters must be removed from sanitised meal descriptions"
            )
        }

        /// Carriage return (0x0d) must be stripped — only LF (0x0a) is used internally for item splitting.
        func test_mealDescription_carriageReturn_isStripped() throws {
            let withCR = "salad\rdressing"
            let sanitized = try InputValidator.validateMealDescription(withCR).get()
            XCTAssertFalse(
                sanitized.contains("\r"),
                "Carriage returns must be removed from sanitised meal descriptions"
            )
        }

        /// sanitizeMealItems must strip tab characters from individual items.
        func test_sanitizeMealItems_stripsTabsFromItems() {
            let items = ["salad\twith\ttabs", "water"]
            let sanitized = InputValidator.sanitizeMealItems(items)
            XCTAssertFalse(
                sanitized.joined().contains("\t"),
                "sanitizeMealItems must strip tab characters"
            )
        }

        // MARK: - Phase 6 RED: Word-boundary false-positive fixes

        /// "Evaluated" contains "EVAL" — bare substring match incorrectly blocks common English words.
        func test_mealDescription_evaluatedIsValid() {
            let result = InputValidator.validateMealDescription("I evaluated my meal plan")
            self.XCTAssertNoThrow(try result.get(), "Common English word 'evaluated' must not be rejected")
        }

        /// "Systematic" contains "SYSTEM" — bare substring match blocks legitimate food context.
        func test_mealDescription_systematicFastingIsValid() {
            let result = InputValidator.validateMealDescription("Systematic fasting approach")
            self.XCTAssertNoThrow(try result.get(), "Common English word 'systematic' must not be rejected")
        }

        /// "Executive" contains "EXEC" — bare substring match false-positive.
        func test_mealDescription_executiveLunchIsValid() {
            let result = InputValidator.validateMealDescription("Executive lunch meeting")
            self.XCTAssertNoThrow(try result.get(), "Common English word 'executive' must not be rejected")
        }

        /// "Delete from my diet" — natural English phrase, not SQL injection.
        func test_mealDescription_deleteFromNaturalSentenceIsValid() {
            let result = InputValidator.validateMealDescription("I want to delete junk food from my diet")
            self.XCTAssertNoThrow(try result.get(), "Natural sentence with 'delete from' must not be rejected")
        }

        // Real injections must still be blocked (regression guard):

        func test_mealDescription_realSqlDropTableIsStillBlocked() {
            let result = InputValidator.validateMealDescription("'; DROP TABLE meals; --")
            XCTAssertThrowsError(try result.get(), "SQL DROP TABLE injection must still be blocked")
        }

        func test_mealDescription_realCodeExecInjectionIsStillBlocked() {
            let result = InputValidator.validateMealDescription("SYSTEM('rm -rf /')")
            XCTAssertThrowsError(try result.get(), "SYSTEM() call injection must still be blocked")
        }

        func test_mealDescription_evalCallInjectionIsStillBlocked() {
            let result = InputValidator.validateMealDescription("eval(maliciousCode)")
            XCTAssertThrowsError(try result.get(), "eval() call injection must still be blocked")
        }
    }
#endif
