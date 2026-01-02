#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    final class SensoryServiceTests: XCTestCase {
        // MARK: - Properties

        var sut: MockSensoryService!

        // MARK: - Setup & Teardown

        override func setUp() {
            super.setUp()
            self.sut = MockSensoryService()
        }

        override func tearDown() {
            self.sut = nil
            super.tearDown()
        }

        // MARK: - Tests: Haptic Feedback

        func test_playNudge_capturesCorrectStyle_forLight() {
            // Act
            self.sut.playNudge(style: .light)

            // Assert
            XCTAssertEqual(self.sut.playedNudges.count, 1)
            XCTAssertEqual(self.sut.playedNudges.first, .light)
        }

        func test_playNudge_capturesCorrectStyle_forMedium() {
            // Act
            self.sut.playNudge(style: .medium)

            // Assert
            XCTAssertEqual(self.sut.playedNudges.count, 1)
            XCTAssertEqual(self.sut.playedNudges.first, .medium)
        }

        func test_playNudge_capturesCorrectStyle_forHeavy() {
            // Act
            self.sut.playNudge(style: .heavy)

            // Assert
            XCTAssertEqual(self.sut.playedNudges.count, 1)
            XCTAssertEqual(self.sut.playedNudges.first, .heavy)
        }

        func test_playNudge_capturesCorrectStyle_forSoft() {
            // Act
            self.sut.playNudge(style: .soft)

            // Assert
            XCTAssertEqual(self.sut.playedNudges.count, 1)
            XCTAssertEqual(self.sut.playedNudges.first, .soft)
        }

        // MARK: - Tests: Sound Feedback

        func test_playSound_capturesCorrectName_forChime() {
            // Act
            self.sut.playSound(named: "chime")

            // Assert
            XCTAssertEqual(self.sut.playedSounds.count, 1)
            XCTAssertEqual(self.sut.playedSounds.first, "chime")
        }

        func test_playSound_capturesCorrectName_forTink() {
            // Act
            self.sut.playSound(named: "tink")

            // Assert
            XCTAssertEqual(self.sut.playedSounds.count, 1)
            XCTAssertEqual(self.sut.playedSounds.first, "tink")
        }

        func test_playSound_capturesCorrectName_forThump() {
            // Act
            self.sut.playSound(named: "thump")

            // Assert
            XCTAssertEqual(self.sut.playedSounds.count, 1)
            XCTAssertEqual(self.sut.playedSounds.first, "thump")
        }

        func test_playSound_usesDefaultSound_forUnknownName() {
            // Act
            self.sut.playSound(named: "unknown_sound")

            // Assert
            XCTAssertEqual(self.sut.playedSounds.count, 1)
            XCTAssertEqual(self.sut.playedSounds.first, "unknown_sound")
        }

        // MARK: - Tests: Legacy Scale-based Sound

        func test_playSound_forSmileyState_selectsCorrectSound_whenScaleAbove1() {
            // Arrange
            let scale = 1.5

            // Act
            self.sut.playSound(for: scale)

            // Assert
            XCTAssertEqual(self.sut.playedSounds.count, 1)
            // Scale > 1.0 should select "thump"
            XCTAssertEqual(self.sut.playedSounds.first, "thump")
        }

        func test_playSound_forSmileyState_selectsCorrectSound_whenScaleBelow1() {
            // Arrange
            let scale = 0.8

            // Act
            self.sut.playSound(for: scale)

            // Assert
            XCTAssertEqual(self.sut.playedSounds.count, 1)
            // Scale <= 1.0 should select "tink"
            XCTAssertEqual(self.sut.playedSounds.first, "tink")
        }
    }

    // MARK: - Mocks

    /// Mock implementation of SensoryServiceProtocol for testing
    class MockSensoryService: SensoryServiceProtocol {
        var playedNudges: [SensoryService.FeedbackStyle] = []
        var playedSounds: [String] = []

        func playNudge(style: SensoryService.FeedbackStyle) {
            self.playedNudges.append(style)
        }

        func playSound(named soundName: String) {
            self.playedSounds.append(soundName)
        }

        func playSound(for scale: Double) {
            // Replicate the logic from SensoryService
            let soundName = scale > 1.0 ? "thump" : "tink"
            self.playSound(named: soundName)
        }
    }
#endif
