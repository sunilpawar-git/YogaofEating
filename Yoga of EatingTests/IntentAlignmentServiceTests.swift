// swiftlint:disable force_unwrapping
#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    @MainActor
    final class IntentAlignmentServiceTests: XCTestCase {
        // MARK: - Tests: No Alignment

        func test_alignmentHint_returnsNil_whenIntentionIsEmpty() {
            let result = IntentAlignmentService.alignmentHint(intention: "", mealItems: ["Pizza"])
            XCTAssertNil(result)
        }

        func test_alignmentHint_returnsNil_whenMealItemsAreEmpty() {
            let result = IntentAlignmentService.alignmentHint(intention: "Eat light", mealItems: [])
            XCTAssertNil(result)
        }

        func test_alignmentHint_returnsNil_whenNoKeywordsMatch() {
            let result = IntentAlignmentService.alignmentHint(
                intention: "Sleep early tonight",
                mealItems: ["Oatmeal", "Berries"]
            )
            XCTAssertNil(result, "Non-food intentions should return nil")
        }

        // MARK: - Tests: Positive Alignment

        func test_alignmentHint_detectsLightEatingAlignment() {
            let result = IntentAlignmentService.alignmentHint(
                intention: "Eat lighter meals today",
                mealItems: ["Salad", "Grilled chicken"]
            )
            XCTAssertNotNil(result)
            XCTAssertTrue(
                result!.contains("aligned") || result!.contains("Aligned"),
                "Should indicate positive alignment"
            )
        }

        func test_alignmentHint_detectsNoSugarAlignment() {
            let result = IntentAlignmentService.alignmentHint(
                intention: "No sugar today",
                mealItems: ["Eggs", "Toast", "Avocado"]
            )
            XCTAssertNotNil(result)
            XCTAssertTrue(result!.contains("aligned") || result!.contains("Aligned") || result!.contains("track"))
        }

        // MARK: - Tests: Misalignment

        func test_alignmentHint_detectsSugarMisalignment() {
            let result = IntentAlignmentService.alignmentHint(
                intention: "No sugar today",
                mealItems: ["Ice cream", "Cake"]
            )
            XCTAssertNotNil(result)
            XCTAssertTrue(
                result!.contains("nudge") || result!.contains("Nudge") || result!.contains("intention"),
                "Should indicate a gentle nudge"
            )
        }

        func test_alignmentHint_caseInsensitiveMatching() {
            let result = IntentAlignmentService.alignmentHint(
                intention: "EAT LIGHTER MEALS",
                mealItems: ["SALAD", "FRUITS"]
            )
            XCTAssertNotNil(result, "Should be case-insensitive")
        }

        func test_alignmentHint_detectsHydrationIntention() {
            let result = IntentAlignmentService.alignmentHint(
                intention: "Stay hydrated and drink more water",
                mealItems: ["Smoothie", "Soup"]
            )
            XCTAssertNotNil(result)
        }
    }
#endif
