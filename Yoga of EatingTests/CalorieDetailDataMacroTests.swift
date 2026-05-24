#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    // Tests for MacroTotals aggregation in CalorieDetailData.
    // TDD: these tests were written before the production implementation.

    final class CalorieDetailDataMacroTests: XCTestCase {
        // MARK: - Helpers

        private func makeMeal(
            isAIAnalyzed: Bool = true,
            protein: Int? = nil,
            carbs: Int? = nil,
            fat: Int? = nil
        ) -> Meal {
            Meal(
                mealType: .lunch,
                items: ["test"],
                isAIAnalyzed: isAIAnalyzed,
                protein: protein,
                carbs: carbs,
                fat: fat
            )
        }

        private func makeDetail(meals: [Meal]) -> CalorieDetailData {
            CalorieDetailData(consumed: 0, tdee: nil, meals: meals)
        }

        // MARK: - macroTotals nil conditions

        func test_macroTotals_nilWhenNoMealsHaveMacros() {
            let meals = [makeMeal(), makeMeal()]
            let detail = self.makeDetail(meals: meals)
            XCTAssertNil(detail.macroTotals)
        }

        func test_macroTotals_nilWhenAllMealsAreAnalyzedButPreDateMacroFeature() {
            // Legacy meals: isAIAnalyzed=true but no macro fields
            let meals = [
                makeMeal(isAIAnalyzed: true, protein: nil, carbs: nil, fat: nil),
                makeMeal(isAIAnalyzed: true, protein: nil, carbs: nil, fat: nil)
            ]
            let detail = self.makeDetail(meals: meals)
            XCTAssertNil(detail.macroTotals, "Legacy meals without macros should yield nil macroTotals")
        }

        func test_macroTotals_nilWhenMealsArrayIsEmpty() {
            let detail = self.makeDetail(meals: [])
            XCTAssertNil(detail.macroTotals)
        }

        // MARK: - macroTotals summation

        func test_macroTotals_sumsOnlyMealsWithMacros() {
            let withMacros = self.makeMeal(isAIAnalyzed: true, protein: 30, carbs: 50, fat: 10)
            let legacy = self.makeMeal(isAIAnalyzed: true, protein: nil, carbs: nil, fat: nil)
            let detail = self.makeDetail(meals: [withMacros, legacy])

            XCTAssertEqual(detail.macroTotals?.protein, 30)
            XCTAssertEqual(detail.macroTotals?.carbs, 50)
            XCTAssertEqual(detail.macroTotals?.fat, 10)
        }

        func test_macroTotals_sumsMultipleMacroMeals() {
            let meal1 = self.makeMeal(isAIAnalyzed: true, protein: 30, carbs: 50, fat: 10)
            let meal2 = self.makeMeal(isAIAnalyzed: true, protein: 20, carbs: 80, fat: 5)
            let detail = self.makeDetail(meals: [meal1, meal2])

            XCTAssertEqual(detail.macroTotals?.protein, 50)
            XCTAssertEqual(detail.macroTotals?.carbs, 130)
            XCTAssertEqual(detail.macroTotals?.fat, 15)
        }

        func test_macroTotals_includesZeroMacroMeals() {
            // Black coffee: protein:0, carbs:0, fat:0 — hasCompleteMacros is true, must be summed
            let coffee = self.makeMeal(isAIAnalyzed: true, protein: 0, carbs: 0, fat: 0)
            let meal = self.makeMeal(isAIAnalyzed: true, protein: 30, carbs: 50, fat: 10)
            let detail = self.makeDetail(meals: [coffee, meal])

            XCTAssertNotNil(detail.macroTotals, "Zero-macro meal (e.g. black coffee) must still contribute")
            // Sum = coffee (0+0+0) + meal (30+50+10) — coffee zeros must be included, not silently dropped
            XCTAssertEqual(detail.macroTotals?.protein, 0 + 30)
            XCTAssertEqual(detail.macroTotals?.carbs, 0 + 50)
            XCTAssertEqual(detail.macroTotals?.fat, 0 + 10)
        }

        // MARK: - isPartial semantics

        func test_macroTotals_isPartialTrueWhenUnanalyzedMealsExist() {
            let analyzed = self.makeMeal(isAIAnalyzed: true, protein: 30, carbs: 50, fat: 10)
            let pending = self.makeMeal(isAIAnalyzed: false)
            let detail = self.makeDetail(meals: [analyzed, pending])

            XCTAssertTrue(detail.macroTotals?.isPartial == true, "Unanalyzed meals must set isPartial")
        }

        func test_macroTotals_isPartialFalseWhenAllMealsAreAnalyzed() {
            let meal1 = self.makeMeal(isAIAnalyzed: true, protein: 30, carbs: 50, fat: 10)
            let meal2 = self.makeMeal(isAIAnalyzed: true, protein: 20, carbs: 40, fat: 8)
            let detail = self.makeDetail(meals: [meal1, meal2])

            XCTAssertFalse(detail.macroTotals?.isPartial == true)
        }

        func test_macroTotals_isPartialFalseWhenLegacyMealsLackMacros() {
            // Legacy meals are excluded silently — they must NOT set isPartial
            let withMacros = self.makeMeal(isAIAnalyzed: true, protein: 30, carbs: 50, fat: 10)
            let legacy = self.makeMeal(isAIAnalyzed: true, protein: nil, carbs: nil, fat: nil)
            let detail = self.makeDetail(meals: [withMacros, legacy])

            XCTAssertFalse(
                detail.macroTotals?.isPartial == true,
                "Legacy analyzed meals without macros must NOT set isPartial"
            )
        }

        func test_macroTotals_nilWhenAllMealsUnanalyzed() {
            // No meals have been analyzed yet — macroTotals must be nil, NOT a partial total
            let meals = [
                self.makeMeal(isAIAnalyzed: false),
                self.makeMeal(isAIAnalyzed: false)
            ]
            XCTAssertNil(
                self.makeDetail(meals: meals).macroTotals,
                "All-unanalyzed day must yield nil macroTotals, not a partial total"
            )
        }

        // MARK: - Equatable

        func test_macroTotals_equatable() {
            let a = MacroTotals(protein: 30, carbs: 50, fat: 10, isPartial: false)
            let b = MacroTotals(protein: 30, carbs: 50, fat: 10, isPartial: false)
            XCTAssertEqual(a, b)
        }

        func test_macroTotals_notEqualWhenPartialDiffers() {
            let a = MacroTotals(protein: 30, carbs: 50, fat: 10, isPartial: false)
            let b = MacroTotals(protein: 30, carbs: 50, fat: 10, isPartial: true)
            XCTAssertNotEqual(a, b)
        }
    }

#endif
