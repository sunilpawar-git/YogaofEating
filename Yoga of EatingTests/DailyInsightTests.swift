// swiftlint:disable force_unwrapping
#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    /// Tests for DailyInsight model and InsightType enum
    /// Phase 1: TDD - Tests written before implementation
    @MainActor
    final class DailyInsightTests: XCTestCase {
        // MARK: - Properties

        var testDate: Date!

        // MARK: - Setup & Teardown

        override func setUp() {
            super.setUp()
            self.testDate = Date()
        }

        override func tearDown() {
            self.testDate = nil
            super.tearDown()
        }

        // MARK: - Tests: InsightType Enum

        func test_insightType_hasExpectedCases() {
            let allCases = InsightType.allCases
            XCTAssertGreaterThanOrEqual(allCases.count, 6, "InsightType should have at least 6 cases")
            XCTAssertTrue(allCases.contains(.foodSleep))
            XCTAssertTrue(allCases.contains(.mindsetFeeling))
            XCTAssertTrue(allCases.contains(.pattern))
            XCTAssertTrue(allCases.contains(.encouragement))
            XCTAssertTrue(allCases.contains(.intentAlignment))
            XCTAssertTrue(allCases.contains(.focusFood))
        }

        func test_insightType_rawValues_areCorrect() {
            XCTAssertEqual(InsightType.foodSleep.rawValue, "foodSleep")
            XCTAssertEqual(InsightType.mindsetFeeling.rawValue, "mindsetFeeling")
            XCTAssertEqual(InsightType.pattern.rawValue, "pattern")
            XCTAssertEqual(InsightType.encouragement.rawValue, "encouragement")
            XCTAssertEqual(InsightType.intentAlignment.rawValue, "intentAlignment")
            XCTAssertEqual(InsightType.focusFood.rawValue, "focusFood")
        }

        func test_insightType_codable_encodesAndDecodes() throws {
            // Test each type individually
            for type in InsightType.allCases {
                let encoder = JSONEncoder()
                let data = try encoder.encode(type)
                let decoder = JSONDecoder()
                let decoded = try decoder.decode(InsightType.self, from: data)

                XCTAssertEqual(decoded, type, "Failed for type: \(type)")
            }
        }

        func test_insightType_icon_returnsCorrectIcon() {
            XCTAssertEqual(InsightType.foodSleep.icon, "moon.zzz.fill")
            XCTAssertEqual(InsightType.mindsetFeeling.icon, "brain.head.profile")
            XCTAssertEqual(InsightType.pattern.icon, "chart.line.uptrend.xyaxis")
            XCTAssertEqual(InsightType.encouragement.icon, "sparkles")
            XCTAssertEqual(InsightType.intentAlignment.icon, "target")
            XCTAssertEqual(InsightType.focusFood.icon, "bolt.circle")
        }

        func test_insightType_displayName_returnsCorrectName() {
            XCTAssertEqual(InsightType.foodSleep.displayName, "Food & Sleep")
            XCTAssertEqual(InsightType.mindsetFeeling.displayName, "Mindset & Feeling")
            XCTAssertEqual(InsightType.pattern.displayName, "Pattern")
            XCTAssertEqual(InsightType.encouragement.displayName, "Encouragement")
            XCTAssertEqual(InsightType.intentAlignment.displayName, "Intent Alignment")
            XCTAssertEqual(InsightType.focusFood.displayName, "Focus & Food")
        }

        // MARK: - Tests: DailyInsight Initialization

        func test_dailyInsight_init_setsAllProperties() {
            // Arrange
            let id = UUID()
            let date = self.testDate!
            let insightText = "You slept better on days with lighter dinners."
            let insightType = InsightType.foodSleep
            let confidence = 0.85

            // Act
            let insight = DailyInsight(
                id: id,
                date: date,
                insightText: insightText,
                insightType: insightType,
                confidence: confidence,
                isViewed: false
            )

            // Assert
            XCTAssertEqual(insight.id, id)
            XCTAssertEqual(insight.date, date)
            XCTAssertEqual(insight.insightText, insightText)
            XCTAssertEqual(insight.insightType, insightType)
            XCTAssertEqual(insight.confidence, confidence)
            XCTAssertFalse(insight.isViewed)
        }

        func test_dailyInsight_isViewed_defaultsToFalse() {
            // Arrange & Act
            let insight = DailyInsight(
                id: UUID(),
                date: self.testDate,
                insightText: "Test insight",
                insightType: .pattern,
                confidence: 0.7,
                isViewed: false
            )

            // Assert
            XCTAssertFalse(insight.isViewed, "isViewed should default to false")
        }

        func test_dailyInsight_markAsViewed_updatesFlag() {
            // Arrange
            var insight = DailyInsight(
                id: UUID(),
                date: self.testDate,
                insightText: "Test insight",
                insightType: .pattern,
                confidence: 0.7,
                isViewed: false
            )

            // Act
            insight.markAsViewed()

            // Assert
            XCTAssertTrue(insight.isViewed, "isViewed should be true after marking as viewed")
        }

        // MARK: - Tests: DailyInsight Codable

        func test_dailyInsight_codable_encodesAndDecodes() throws {
            // Arrange
            let insight = DailyInsight(
                id: UUID(),
                date: self.testDate,
                insightText: "When you log gratitude in the morning, you feel calmer by evening.",
                insightType: .mindsetFeeling,
                confidence: 0.92,
                isViewed: false
            )

            // Act
            let encoder = JSONEncoder()
            let data = try encoder.encode(insight)
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(DailyInsight.self, from: data)

            // Assert
            XCTAssertEqual(decoded.id, insight.id)
            XCTAssertEqual(decoded.insightText, insight.insightText)
            XCTAssertEqual(decoded.insightType, insight.insightType)
            XCTAssertEqual(decoded.confidence, insight.confidence, accuracy: 0.001)
            XCTAssertEqual(decoded.isViewed, insight.isViewed)
            XCTAssertEqual(
                decoded.date.timeIntervalSince1970,
                insight.date.timeIntervalSince1970,
                accuracy: 0.001
            )
        }

        func test_dailyInsight_codable_withViewedTrue() throws {
            // Arrange
            let insight = DailyInsight(
                id: UUID(),
                date: self.testDate,
                insightText: "Test",
                insightType: .encouragement,
                confidence: 0.5,
                isViewed: true
            )

            // Act
            let encoder = JSONEncoder()
            let data = try encoder.encode(insight)
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(DailyInsight.self, from: data)

            // Assert
            XCTAssertTrue(decoded.isViewed)
        }

        // MARK: - Tests: DailyInsight Equatable

        func test_dailyInsight_equatable_returnsTrueForIdenticalInsights() {
            // Arrange
            let id = UUID()
            let date = self.testDate!
            let insight1 = DailyInsight(
                id: id,
                date: date,
                insightText: "Test",
                insightType: .pattern,
                confidence: 0.8,
                isViewed: false
            )
            let insight2 = DailyInsight(
                id: id,
                date: date,
                insightText: "Test",
                insightType: .pattern,
                confidence: 0.8,
                isViewed: false
            )

            // Assert
            XCTAssertEqual(insight1, insight2)
        }

        func test_dailyInsight_equatable_returnsFalseForDifferentIds() {
            // Arrange
            let insight1 = DailyInsight(
                id: UUID(),
                date: self.testDate,
                insightText: "Test",
                insightType: .pattern,
                confidence: 0.8,
                isViewed: false
            )
            let insight2 = DailyInsight(
                id: UUID(),
                date: self.testDate,
                insightText: "Test",
                insightType: .pattern,
                confidence: 0.8,
                isViewed: false
            )

            // Assert
            XCTAssertNotEqual(insight1, insight2)
        }

        // MARK: - Tests: Confidence Validation

        func test_dailyInsight_confidence_acceptsValidRange() {
            // Test minimum
            let minInsight = DailyInsight(
                id: UUID(),
                date: self.testDate,
                insightText: "Low confidence",
                insightType: .encouragement,
                confidence: 0.0,
                isViewed: false
            )
            XCTAssertEqual(minInsight.confidence, 0.0)

            // Test maximum
            let maxInsight = DailyInsight(
                id: UUID(),
                date: self.testDate,
                insightText: "High confidence",
                insightType: .pattern,
                confidence: 1.0,
                isViewed: false
            )
            XCTAssertEqual(maxInsight.confidence, 1.0)

            // Test middle
            let midInsight = DailyInsight(
                id: UUID(),
                date: self.testDate,
                insightText: "Medium confidence",
                insightType: .foodSleep,
                confidence: 0.5,
                isViewed: false
            )
            XCTAssertEqual(midInsight.confidence, 0.5)
        }

        // MARK: - Tests: Edge Cases

        func test_dailyInsight_withEmptyText_handlesCorrectly() throws {
            // Arrange
            let insight = DailyInsight(
                id: UUID(),
                date: self.testDate,
                insightText: "",
                insightType: .encouragement,
                confidence: 0.5,
                isViewed: false
            )

            // Act
            let encoder = JSONEncoder()
            let data = try encoder.encode(insight)
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(DailyInsight.self, from: data)

            // Assert
            XCTAssertEqual(decoded.insightText, "")
        }

        func test_dailyInsight_withSpecialCharacters_handlesCorrectly() throws {
            // Arrange
            let specialText = "You're doing great! 🌟 Keep it up! <test> & \"quotes\""
            let insight = DailyInsight(
                id: UUID(),
                date: self.testDate,
                insightText: specialText,
                insightType: .encouragement,
                confidence: 0.9,
                isViewed: false
            )

            // Act
            let encoder = JSONEncoder()
            let data = try encoder.encode(insight)
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(DailyInsight.self, from: data)

            // Assert
            XCTAssertEqual(decoded.insightText, specialText)
        }

        func test_dailyInsight_withLongText_handlesCorrectly() throws {
            // Arrange
            let longText = String(repeating: "This is an insight about your patterns. ", count: 10)
            let insight = DailyInsight(
                id: UUID(),
                date: self.testDate,
                insightText: longText,
                insightType: .pattern,
                confidence: 0.75,
                isViewed: false
            )

            // Act
            let encoder = JSONEncoder()
            let data = try encoder.encode(insight)
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(DailyInsight.self, from: data)

            // Assert
            XCTAssertEqual(decoded.insightText, longText)
        }

        // MARK: - Tests: Identifiable

        func test_dailyInsight_identifiable_conformance() {
            // Arrange
            let id = UUID()
            let insight = DailyInsight(
                id: id,
                date: self.testDate,
                insightText: "Test",
                insightType: .pattern,
                confidence: 0.8,
                isViewed: false
            )

            // Assert - Identifiable requires id property
            XCTAssertEqual(insight.id, id)
        }

        // MARK: - Tests: All InsightTypes Encode/Decode

        func test_dailyInsight_allTypes_encodeAndDecode() throws {
            for type in InsightType.allCases {
                let insight = DailyInsight(
                    id: UUID(),
                    date: self.testDate,
                    insightText: "Test for \(type)",
                    insightType: type,
                    confidence: 0.8,
                    isViewed: false
                )

                let encoder = JSONEncoder()
                let data = try encoder.encode(insight)
                let decoder = JSONDecoder()
                let decoded = try decoder.decode(DailyInsight.self, from: data)

                XCTAssertEqual(decoded.insightType, type, "Failed for type: \(type)")
            }
        }
    }
#endif
