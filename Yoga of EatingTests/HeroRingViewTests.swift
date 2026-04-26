import XCTest
@testable import Yoga_of_Eating

/// Unit tests for HeroRingView and shared RingArcSegment logic.
final class HeroRingViewTests: XCTestCase {
    // MARK: - Progress Display

    func test_heroRing_displaysPercentage() {
        let progress = DayModuleProgress(
            reflectProgress: 0.5,
            laserProgress: 0.5,
            highlightProgress: 0.5,
            energiseProgress: 0.5
        )
        let pct = Int(progress.overallProgress * 100)
        XCTAssertEqual(pct, 50)
    }

    func test_heroRing_fullProgress_showsHundred() {
        let progress = DayModuleProgress(
            reflectProgress: 1.0,
            laserProgress: 1.0,
            highlightProgress: 1.0,
            energiseProgress: 1.0
        )
        XCTAssertEqual(Int(progress.overallProgress * 100), 100)
    }

    func test_heroRing_emptyProgress_showsZero() {
        XCTAssertEqual(Int(DayModuleProgress.empty.overallProgress * 100), 0)
    }

    // MARK: - Avatar Emoji Matches Progress

    func test_heroRing_avatarEmoji_noProgress_neutral() {
        let emoji = HeroRingView.avatarEmoji(for: DayModuleProgress.empty)
        XCTAssertEqual(emoji, Strings.Home.avatarNeutral)
    }

    func test_heroRing_avatarEmoji_highProgress_serene() {
        let progress = DayModuleProgress(
            reflectProgress: 1.0,
            laserProgress: 0.8,
            highlightProgress: 0.7,
            energiseProgress: 0.9
        )
        let emoji = HeroRingView.avatarEmoji(for: progress)
        XCTAssertEqual(emoji, Strings.Home.avatarSerene)
    }

    func test_heroRing_avatarEmoji_lowProgress_overwhelmed() {
        let progress = DayModuleProgress(
            reflectProgress: 0.1,
            laserProgress: 0.0,
            highlightProgress: 0.0,
            energiseProgress: 0.1
        )
        let emoji = HeroRingView.avatarEmoji(for: progress)
        XCTAssertEqual(emoji, Strings.Home.avatarOverwhelmed)
    }

    // MARK: - Accessibility

    func test_heroRing_accessibilityLabel_includesAllModules() {
        let progress = DayModuleProgress(
            reflectProgress: 0.33,
            laserProgress: 0.66,
            highlightProgress: 1.0,
            energiseProgress: 0.0
        )
        let label = HeroRingView.accessibilityDescription(for: progress)
        XCTAssertTrue(label.contains("49"))
        XCTAssertTrue(label.contains("Reflect"))
        XCTAssertTrue(label.contains("Laser"))
        XCTAssertTrue(label.contains("Highlight"))
        XCTAssertTrue(label.contains("Energise"))
    }

    // MARK: - Module Colors from Theme

    func test_moduleColors_matchTheme() {
        XCTAssertEqual(DayModule.reflect.color, AppTheme.ModuleColors.reflect)
        XCTAssertEqual(DayModule.laser.color, AppTheme.ModuleColors.laser)
        XCTAssertEqual(DayModule.highlight.color, AppTheme.ModuleColors.highlight)
        XCTAssertEqual(DayModule.energise.color, AppTheme.ModuleColors.energise)
    }

    // MARK: - RingArcSegment Geometry

    func test_ringArcSegment_startAnglesAreSeparatedBy90() {
        let starts = RingArcSegment.startAngles
        XCTAssertEqual(starts.count, 4)
        XCTAssertEqual(starts[0], 0)
        XCTAssertEqual(starts[1], 90)
        XCTAssertEqual(starts[2], 180)
        XCTAssertEqual(starts[3], 270)
    }
}
