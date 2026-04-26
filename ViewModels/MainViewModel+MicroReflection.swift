import Foundation

extension MainViewModel {
    func saveMicroReflection(
        mealId: UUID,
        preHunger: Int?,
        postSatisfaction: Int?
    ) {
        guard let index = meals.firstIndex(where: { $0.id == mealId })
        else { return }

        self.meals[index].preHunger = preHunger
        self.meals[index].postSatisfaction = postSatisfaction
        self.saveData()
    }
}
