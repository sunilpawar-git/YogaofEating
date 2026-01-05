// swiftlint:disable force_unwrapping file_length
#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    /// Tests for DailyReflection model and related enums
    /// Phase 1: TDD - Tests written before implementation
    @MainActor
    final class DailyReflectionTests: XCTestCase {
        // MARK: - Properties

        var sut: DailyReflection!
        var testDate: Date!

        // MARK: - Setup & Teardown

        override func setUp() {
            super.setUp()
            self.testDate = Date()
        }

        override func tearDown() {
            self.sut = nil
            self.testDate = nil
            super.tearDown()
        }

        // MARK: - Tests: ReflectionFeeling Enum

        func test_reflectionFeeling_hasAllExpectedCases() {
            // Assert all 5 feeling cases exist
            let allCases = ReflectionFeeling.allCases
            XCTAssertEqual(allCases.count, 5, "ReflectionFeeling should have exactly 5 cases")
            XCTAssertTrue(allCases.contains(.great))
            XCTAssertTrue(allCases.contains(.calm))
            XCTAssertTrue(allCases.contains(.ok))
            XCTAssertTrue(allCases.contains(.tired))
            XCTAssertTrue(allCases.contains(.heavy))
        }

        func test_reflectionFeeling_rawValues_areCorrect() {
            XCTAssertEqual(ReflectionFeeling.great.rawValue, "great")
            XCTAssertEqual(ReflectionFeeling.calm.rawValue, "calm")
            XCTAssertEqual(ReflectionFeeling.ok.rawValue, "ok")
            XCTAssertEqual(ReflectionFeeling.tired.rawValue, "tired")
            XCTAssertEqual(ReflectionFeeling.heavy.rawValue, "heavy")
        }

        func test_reflectionFeeling_emoji_returnsCorrectEmoji() {
            XCTAssertEqual(ReflectionFeeling.great.emoji, "😴")
            XCTAssertEqual(ReflectionFeeling.calm.emoji, "😊")
            XCTAssertEqual(ReflectionFeeling.ok.emoji, "😐")
            XCTAssertEqual(ReflectionFeeling.tired.emoji, "🥱")
            XCTAssertEqual(ReflectionFeeling.heavy.emoji, "😣")
        }

        func test_reflectionFeeling_displayName_returnsCorrectName() {
            XCTAssertEqual(ReflectionFeeling.great.displayName, "Great")
            XCTAssertEqual(ReflectionFeeling.calm.displayName, "Calm")
            XCTAssertEqual(ReflectionFeeling.ok.displayName, "Ok")
            XCTAssertEqual(ReflectionFeeling.tired.displayName, "Tired")
            XCTAssertEqual(ReflectionFeeling.heavy.displayName, "Heavy")
        }

        func test_reflectionFeeling_codable_encodesAndDecodes() throws {
            // Arrange
            let feeling = ReflectionFeeling.calm

            // Act
            let encoder = JSONEncoder()
            let data = try encoder.encode(feeling)
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(ReflectionFeeling.self, from: data)

            // Assert
            XCTAssertEqual(decoded, feeling)
        }

        // MARK: - Tests: SleepQuality Enum

        func test_sleepQuality_hasAllExpectedCases() {
            // Assert all 4 sleep quality cases exist
            let allCases = SleepQuality.allCases
            XCTAssertEqual(allCases.count, 4, "SleepQuality should have exactly 4 cases")
            XCTAssertTrue(allCases.contains(.great))
            XCTAssertTrue(allCases.contains(.good))
            XCTAssertTrue(allCases.contains(.poor))
            XCTAssertTrue(allCases.contains(.terrible))
        }

        func test_sleepQuality_rawValues_areCorrect() {
            XCTAssertEqual(SleepQuality.great.rawValue, "great")
            XCTAssertEqual(SleepQuality.good.rawValue, "good")
            XCTAssertEqual(SleepQuality.poor.rawValue, "poor")
            XCTAssertEqual(SleepQuality.terrible.rawValue, "terrible")
        }

        func test_sleepQuality_emoji_returnsCorrectEmoji() {
            XCTAssertEqual(SleepQuality.great.emoji, "😴")
            XCTAssertEqual(SleepQuality.good.emoji, "🙂")
            XCTAssertEqual(SleepQuality.poor.emoji, "😕")
            XCTAssertEqual(SleepQuality.terrible.emoji, "😫")
        }

        func test_sleepQuality_displayName_returnsCorrectName() {
            XCTAssertEqual(SleepQuality.great.displayName, "Great")
            XCTAssertEqual(SleepQuality.good.displayName, "Good")
            XCTAssertEqual(SleepQuality.poor.displayName, "Poor")
            XCTAssertEqual(SleepQuality.terrible.displayName, "Terrible")
        }

        func test_sleepQuality_codable_encodesAndDecodes() throws {
            // Arrange
            let quality = SleepQuality.good

            // Act
            let encoder = JSONEncoder()
            let data = try encoder.encode(quality)
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(SleepQuality.self, from: data)

            // Assert
            XCTAssertEqual(decoded, quality)
        }

        // MARK: - Tests: DailyReflection Initialization

        func test_init_withAllParameters_setsPropertiesCorrectly() {
            // Arrange & Act
            self.sut = DailyReflection(
                feeling: .calm,
                sleepQuality: .good,
                note: "Felt balanced today",
                timestamp: self.testDate
            )

            // Assert
            XCTAssertEqual(self.sut.feeling, .calm)
            XCTAssertEqual(self.sut.sleepQuality, .good)
            XCTAssertEqual(self.sut.note, "Felt balanced today")
            XCTAssertEqual(self.sut.timestamp, self.testDate)
        }

        func test_init_withMinimalParameters_setsDefaults() {
            // Arrange & Act
            self.sut = DailyReflection(feeling: .ok)

            // Assert
            XCTAssertEqual(self.sut.feeling, .ok)
            XCTAssertNil(self.sut.sleepQuality, "Sleep quality should be nil by default")
            XCTAssertNil(self.sut.note, "Note should be nil by default")
            XCTAssertNotNil(self.sut.timestamp, "Timestamp should have a default value")
        }

        func test_init_withNilOptionals_acceptsNilValues() {
            // Arrange & Act
            self.sut = DailyReflection(
                feeling: .great,
                sleepQuality: nil,
                note: nil,
                timestamp: self.testDate
            )

            // Assert
            XCTAssertEqual(self.sut.feeling, .great)
            XCTAssertNil(self.sut.sleepQuality)
            XCTAssertNil(self.sut.note)
        }

        func test_init_withEmptyNote_treatsAsEmptyString() {
            // Arrange & Act
            self.sut = DailyReflection(
                feeling: .tired,
                sleepQuality: .poor,
                note: "",
                timestamp: self.testDate
            )

            // Assert
            XCTAssertEqual(self.sut.note, "")
        }

        // MARK: - Tests: DailyReflection Codable

        func test_codable_encodesAndDecodes_withAllProperties() throws {
            // Arrange
            self.sut = DailyReflection(
                feeling: .heavy,
                sleepQuality: .terrible,
                note: "Overate today",
                timestamp: self.testDate
            )

            // Act
            let encoder = JSONEncoder()
            let data = try encoder.encode(self.sut)
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(DailyReflection.self, from: data)

            // Assert
            XCTAssertEqual(decoded.feeling, self.sut.feeling)
            XCTAssertEqual(decoded.sleepQuality, self.sut.sleepQuality)
            XCTAssertEqual(decoded.note, self.sut.note)
            XCTAssertEqual(
                decoded.timestamp.timeIntervalSince1970,
                self.sut.timestamp.timeIntervalSince1970,
                accuracy: 0.001
            )
        }

        func test_codable_encodesAndDecodes_withNilOptionals() throws {
            // Arrange
            self.sut = DailyReflection(
                feeling: .calm,
                sleepQuality: nil,
                note: nil,
                timestamp: self.testDate
            )

            // Act
            let encoder = JSONEncoder()
            let data = try encoder.encode(self.sut)
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(DailyReflection.self, from: data)

            // Assert
            XCTAssertEqual(decoded.feeling, .calm)
            XCTAssertNil(decoded.sleepQuality)
            XCTAssertNil(decoded.note)
        }

        func test_codable_decodesLegacyData_withoutOptionalFields() throws {
            // Arrange - Simulate legacy JSON without optional fields
            let legacyJSON = """
            {
                "feeling": "ok",
                "timestamp": \(self.testDate.timeIntervalSince1970)
            }
            """.data(using: .utf8)!

            // Act
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(DailyReflection.self, from: legacyJSON)

            // Assert
            XCTAssertEqual(decoded.feeling, .ok)
            XCTAssertNil(decoded.sleepQuality)
            XCTAssertNil(decoded.note)
        }

        // MARK: - Tests: DailyReflection Equatable

        func test_equatable_returnsTrueForIdenticalReflections() {
            // Arrange
            let reflection1 = DailyReflection(
                feeling: .calm,
                sleepQuality: .good,
                note: "Test",
                timestamp: self.testDate
            )
            let reflection2 = DailyReflection(
                feeling: .calm,
                sleepQuality: .good,
                note: "Test",
                timestamp: self.testDate
            )

            // Assert
            XCTAssertEqual(reflection1, reflection2)
        }

        func test_equatable_returnsFalseForDifferentFeelings() {
            // Arrange
            let reflection1 = DailyReflection(feeling: .calm, timestamp: self.testDate)
            let reflection2 = DailyReflection(feeling: .tired, timestamp: self.testDate)

            // Assert
            XCTAssertNotEqual(reflection1, reflection2)
        }

        // MARK: - Tests: DailySmileySnapshot with Reflection (Backward Compatibility)

        func test_snapshot_withReflection_encodesAndDecodes() throws {
            // Arrange
            let reflection = DailyReflection(
                feeling: .great,
                sleepQuality: .great,
                note: "Perfect day!",
                timestamp: self.testDate
            )
            let snapshot = DailySmileySnapshot(
                id: UUID(),
                date: self.testDate,
                smileyState: SmileyState(scale: 1.0, mood: .serene),
                meals: [],
                mealCount: 0,
                averageHealthScore: 0.8,
                reflection: reflection
            )

            // Act
            let encoder = JSONEncoder()
            let data = try encoder.encode(snapshot)
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(DailySmileySnapshot.self, from: data)

            // Assert
            XCTAssertNotNil(decoded.reflection)
            XCTAssertEqual(decoded.reflection?.feeling, .great)
            XCTAssertEqual(decoded.reflection?.sleepQuality, .great)
            XCTAssertEqual(decoded.reflection?.note, "Perfect day!")
        }

        func test_snapshot_withoutReflection_decodesWithNilReflection() throws {
            // Arrange - Legacy snapshot JSON without reflection field
            let snapshotId = UUID()
            let legacyJSON = """
            {
                "id": "\(snapshotId.uuidString)",
                "date": \(self.testDate.timeIntervalSince1970),
                "smileyState": {"scale": 1.0, "mood": "neutral"},
                "meals": [],
                "mealCount": 0,
                "averageHealthScore": 0.5
            }
            """.data(using: .utf8)!

            // Act
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(DailySmileySnapshot.self, from: legacyJSON)

            // Assert
            XCTAssertNil(decoded.reflection, "Legacy snapshot should have nil reflection")
            XCTAssertEqual(decoded.id, snapshotId)
            XCTAssertEqual(decoded.mealCount, 0)
        }

        func test_snapshot_reflectionIsOptional_defaultsToNil() {
            // Arrange & Act
            let snapshot = DailySmileySnapshot(
                id: UUID(),
                date: self.testDate,
                smileyState: SmileyState(scale: 1.0, mood: .neutral),
                meals: [],
                mealCount: 0,
                averageHealthScore: 0.5
            )

            // Assert
            XCTAssertNil(snapshot.reflection, "Reflection should default to nil")
        }

        // MARK: - Tests: Edge Cases

        func test_reflection_withVeryLongNote_handlesCorrectly() throws {
            // Arrange
            let longNote = String(repeating: "This is a test note. ", count: 100)
            self.sut = DailyReflection(
                feeling: .ok,
                sleepQuality: .good,
                note: longNote,
                timestamp: self.testDate
            )

            // Act
            let encoder = JSONEncoder()
            let data = try encoder.encode(self.sut)
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(DailyReflection.self, from: data)

            // Assert
            XCTAssertEqual(decoded.note, longNote)
        }

        func test_reflection_withSpecialCharactersInNote_handlesCorrectly() throws {
            // Arrange
            let specialNote = "Felt 😊 today! 🎉 Special chars: <>&\"'日本語"
            self.sut = DailyReflection(
                feeling: .great,
                note: specialNote,
                timestamp: self.testDate
            )

            // Act
            let encoder = JSONEncoder()
            let data = try encoder.encode(self.sut)
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(DailyReflection.self, from: data)

            // Assert
            XCTAssertEqual(decoded.note, specialNote)
        }

        func test_allFeelingCases_encodeAndDecode() throws {
            // Test each feeling case individually
            for feeling in ReflectionFeeling.allCases {
                let reflection = DailyReflection(feeling: feeling, timestamp: self.testDate)

                let encoder = JSONEncoder()
                let data = try encoder.encode(reflection)
                let decoder = JSONDecoder()
                let decoded = try decoder.decode(DailyReflection.self, from: data)

                XCTAssertEqual(decoded.feeling, feeling, "Failed for feeling: \(feeling)")
            }
        }

        func test_allSleepQualityCases_encodeAndDecode() throws {
            // Test each sleep quality case individually
            for quality in SleepQuality.allCases {
                let reflection = DailyReflection(
                    feeling: .ok,
                    sleepQuality: quality,
                    timestamp: self.testDate
                )

                let encoder = JSONEncoder()
                let data = try encoder.encode(reflection)
                let decoder = JSONDecoder()
                let decoded = try decoder.decode(DailyReflection.self, from: data)

                XCTAssertEqual(decoded.sleepQuality, quality, "Failed for quality: \(quality)")
            }
        }
    }
#endif
