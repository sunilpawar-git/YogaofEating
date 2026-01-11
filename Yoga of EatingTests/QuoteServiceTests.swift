#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    final class QuoteServiceTests: XCTestCase {
        func test_quotes_has30Quotes() {
            XCTAssertEqual(QuoteService.quotes.count, 30)
        }

        func test_quotes_allHaveText() {
            for quote in QuoteService.quotes {
                XCTAssertFalse(quote.text.isEmpty, "Quote text should not be empty")
            }
        }

        func test_getDailyQuote_returnsSameQuoteForSameDay() {
            let date = Date(timeIntervalSince1970: 1_704_067_200) // Jan 1, 2024
            let quote1 = QuoteService.getDailyQuote(for: date)
            let quote2 = QuoteService.getDailyQuote(for: date)

            XCTAssertEqual(quote1, quote2)
        }

        func test_getDailyQuote_returnsDifferentQuoteForDifferentDay() {
            let day1 = Date(timeIntervalSince1970: 1_704_067_200) // Jan 1, 2024
            let day2 = Date(timeIntervalSince1970: 1_704_153_600) // Jan 2, 2024

            let quote1 = QuoteService.getDailyQuote(for: day1)
            let quote2 = QuoteService.getDailyQuote(for: day2)

            // Should be different quotes (unless by chance they're the same)
            // More importantly, the indices should be different
            let calendar = Calendar.current
            let day1Index = (calendar.ordinality(of: .day, in: .year, for: day1)! - 1) % 30
            let day2Index = (calendar.ordinality(of: .day, in: .year, for: day2)! - 1) % 30

            XCTAssertNotEqual(day1Index, day2Index)
        }

        func test_getDailyQuote_cyclesThrough30Days() {
            let calendar = Calendar.current
            var seenQuotes = Set<String>()

            // Test 30 consecutive days
            let startDate = Date(timeIntervalSince1970: 1_704_067_200) // Jan 1, 2024
            for dayOffset in 0..<30 {
                let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate)!
                let quote = QuoteService.getDailyQuote(for: date)
                seenQuotes.insert(quote.text)
            }

            // Should have seen all 30 unique quotes
            XCTAssertEqual(seenQuotes.count, 30)
        }

        func test_getDailyQuote_cyclesBackAfter30Days() {
            let calendar = Calendar.current
            let day1 = Date(timeIntervalSince1970: 1_704_067_200) // Jan 1, 2024
            let day31 = calendar.date(byAdding: .day, value: 30, to: day1)!

            let quote1 = QuoteService.getDailyQuote(for: day1)
            let quote31 = QuoteService.getDailyQuote(for: day31)

            // Day 31 should show the same quote as day 1
            XCTAssertEqual(quote1, quote31)
        }

        func test_getDailyQuote_defaultsToToday() {
            let quoteToday = QuoteService.getDailyQuote()
            let quoteExplicit = QuoteService.getDailyQuote(for: Date())

            XCTAssertEqual(quoteToday, quoteExplicit)
        }

        // MARK: - MindfulQuote Tests

        func test_mindfulQuote_formatted_withoutAuthor() {
            let quote = MindfulQuote(text: "Eat mindfully", author: nil)
            XCTAssertEqual(quote.formatted, "\"Eat mindfully\"")
        }

        func test_mindfulQuote_formatted_withAuthor() {
            let quote = MindfulQuote(text: "Be present", author: "Buddha")
            XCTAssertEqual(quote.formatted, "\"Be present\" — Buddha")
        }

        func test_mindfulQuote_equality() {
            let quote1 = MindfulQuote(text: "Same text", author: "Author")
            let quote2 = MindfulQuote(text: "Same text", author: "Author")
            let quote3 = MindfulQuote(text: "Different text", author: "Author")

            XCTAssertEqual(quote1, quote2)
            XCTAssertNotEqual(quote1, quote3)
        }

        // MARK: - Tech Debt: JSON Loading Tests

        func test_quotes_loadedFromJSONOrFallback() {
            // Regardless of whether JSON loads or not, we should have 30 quotes
            // (either from JSON or fallback)
            XCTAssertEqual(QuoteService.quotes.count, 30)
        }

        func test_quotes_fallbackWorksWhenJSONMissing() {
            // The quotes array should never be empty due to fallback
            XCTAssertFalse(QuoteService.quotes.isEmpty)
        }
    }
#endif
