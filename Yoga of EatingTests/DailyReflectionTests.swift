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
            XCTAssertEqual(ReflectionFeeling.great.emoji, "😊")
            XCTAssertEqual(ReflectionFeeling.calm.emoji, "😌")
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
            XCTAssertNil(self.sut.sleepLoggedAt, "sleepLoggedAt should be nil by default")
            XCTAssertNil(self.sut.feelingLoggedAt, "feelingLoggedAt should be nil by default")
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

        // MARK: - Tests: Separate Timestamps (Phase 1 - New Model)

        func test_init_withSeparateTimestamps_setsPropertiesCorrectly() {
            // Arrange
            let sleepTime = Calendar.current.date(bySettingHour: 7, minute: 30, second: 0, of: self.testDate)!
            let feelingTime = Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: self.testDate)!

            // Act
            self.sut = DailyReflection(
                feeling: .calm,
                sleepQuality: .good,
                sleepLoggedAt: sleepTime,
                feelingLoggedAt: feelingTime,
                timestamp: self.testDate
            )

            // Assert
            XCTAssertEqual(self.sut.sleepLoggedAt, sleepTime)
            XCTAssertEqual(self.sut.feelingLoggedAt, feelingTime)
        }

        func test_init_withOnlySleepQuality_setsSleepLoggedAt() {
            // Arrange
            let sleepTime = Calendar.current.date(bySettingHour: 7, minute: 30, second: 0, of: self.testDate)!

            // Act
            self.sut = DailyReflection(
                sleepQuality: .good,
                sleepLoggedAt: sleepTime,
                timestamp: self.testDate
            )

            // Assert
            XCTAssertEqual(self.sut.sleepQuality, .good)
            XCTAssertEqual(self.sut.sleepLoggedAt, sleepTime)
            XCTAssertNil(self.sut.feeling)
            XCTAssertNil(self.sut.feelingLoggedAt)
        }

        func test_init_withOnlyFeeling_setsFeelingLoggedAt() {
            // Arrange
            let feelingTime = Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: self.testDate)!

            // Act
            self.sut = DailyReflection(
                feeling: .tired,
                feelingLoggedAt: feelingTime,
                timestamp: self.testDate
            )

            // Assert
            XCTAssertEqual(self.sut.feeling, .tired)
            XCTAssertEqual(self.sut.feelingLoggedAt, feelingTime)
            XCTAssertNil(self.sut.sleepQuality)
            XCTAssertNil(self.sut.sleepLoggedAt)
        }

        func test_codable_encodesAndDecodes_withSeparateTimestamps() throws {
            // Arrange
            let sleepTime = Calendar.current.date(bySettingHour: 7, minute: 30, second: 0, of: self.testDate)!
            let feelingTime = Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: self.testDate)!
            self.sut = DailyReflection(
                feeling: .calm,
                sleepQuality: .good,
                sleepLoggedAt: sleepTime,
                feelingLoggedAt: feelingTime,
                timestamp: self.testDate
            )

            // Act
            let encoder = JSONEncoder()
            let data = try encoder.encode(self.sut)
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(DailyReflection.self, from: data)

            // Assert
            XCTAssertNotNil(decoded.sleepLoggedAt)
            XCTAssertEqual(
                decoded.sleepLoggedAt!.timeIntervalSince1970,
                sleepTime.timeIntervalSince1970,
                accuracy: 0.001
            )
            XCTAssertNotNil(decoded.feelingLoggedAt)
            XCTAssertEqual(
                decoded.feelingLoggedAt!.timeIntervalSince1970,
                feelingTime.timeIntervalSince1970,
                accuracy: 0.001
            )
        }

        func test_codable_backwardCompatibility_withoutNewTimestampFields() throws {
            // Arrange - Legacy JSON without new timestamp fields
            let legacyJSON = """
            {
                "feeling": "calm",
                "sleepQuality": "good",
                "timestamp": \(self.testDate.timeIntervalSince1970)
            }
            """.data(using: .utf8)!

            // Act
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(DailyReflection.self, from: legacyJSON)

            // Assert
            XCTAssertEqual(decoded.feeling, .calm)
            XCTAssertEqual(decoded.sleepQuality, .good)
            XCTAssertNil(decoded.sleepLoggedAt, "Legacy data should have nil sleepLoggedAt")
            XCTAssertNil(decoded.feelingLoggedAt, "Legacy data should have nil feelingLoggedAt")
        }

        func test_hasSleepLogged_returnsTrueWhenSleepQualityExists() {
            // Arrange
            self.sut = DailyReflection(
                sleepQuality: .good,
                sleepLoggedAt: self.testDate,
                timestamp: self.testDate
            )

            // Assert
            XCTAssertTrue(self.sut.hasSleepLogged)
        }

        func test_hasSleepLogged_returnsFalseWhenNoSleepQuality() {
            // Arrange
            self.sut = DailyReflection(
                feeling: .calm,
                timestamp: self.testDate
            )

            // Assert
            XCTAssertFalse(self.sut.hasSleepLogged)
        }

        func test_hasFeelingLogged_returnsTrueWhenFeelingExists() {
            // Arrange
            self.sut = DailyReflection(
                feeling: .calm,
                feelingLoggedAt: self.testDate,
                timestamp: self.testDate
            )

            // Assert
            XCTAssertTrue(self.sut.hasFeelingLogged)
        }

        func test_hasFeelingLogged_returnsFalseWhenNoFeeling() {
            // Arrange
            self.sut = DailyReflection(
                sleepQuality: .good,
                timestamp: self.testDate
            )

            // Assert
            XCTAssertFalse(self.sut.hasFeelingLogged)
        }

        func test_updateSleepQuality_createsNewReflectionWithSleep() {
            // Arrange
            let sleepTime = self.testDate!

            // Act
            let reflection = DailyReflection.withSleepQuality(.great, at: sleepTime)

            // Assert
            XCTAssertEqual(reflection.sleepQuality, .great)
            XCTAssertEqual(reflection.sleepLoggedAt, sleepTime)
            XCTAssertNil(reflection.feeling)
        }

        func test_updateFeeling_createsNewReflectionWithFeeling() {
            // Arrange
            let feelingTime = self.testDate!

            // Act
            let reflection = DailyReflection.withFeeling(.tired, at: feelingTime)

            // Assert
            XCTAssertEqual(reflection.feeling, .tired)
            XCTAssertEqual(reflection.feelingLoggedAt, feelingTime)
            XCTAssertNil(reflection.sleepQuality)
        }

        func test_mergeReflections_combinesSleepAndFeeling() {
            // Arrange
            let sleepTime = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: self.testDate)!
            let feelingTime = Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: self.testDate)!

            let sleepReflection = DailyReflection.withSleepQuality(.good, at: sleepTime)
            let feelingReflection = DailyReflection.withFeeling(.calm, at: feelingTime)

            // Act
            let merged = sleepReflection.merging(with: feelingReflection)

            // Assert
            XCTAssertEqual(merged.sleepQuality, .good)
            XCTAssertEqual(merged.sleepLoggedAt, sleepTime)
            XCTAssertEqual(merged.feeling, .calm)
            XCTAssertEqual(merged.feelingLoggedAt, feelingTime)
        }
    }
#endif
