import Foundation

/// Service responsible for the "Yoga of Eating" logic.
/// Adapts the Smiley's state based on meal choices.
protocol MealLogicProvider {
    func calculateHealthScore(for description: String) -> Double
    func calculateNextState(from currentState: SmileyState, healthScore: Double) -> SmileyState
}

class MealLogicService: MealLogicProvider {
    
    /// Calculates a health score (0.0 - 1.0) based on string description.
    /// MVP uses a simple keyword heuristic.
    func calculateHealthScore(for description: String) -> Double {
        let input = description.lowercased()
        
        let healthyKeywords = ["salad", "fruit", "avocado", "smoothie", "vegetable", "water", "organic", "green"]
        let unhealthyKeywords = ["burger", "pizza", "fries", "coke", "soda", "sugar", "fried", "cheese"]
        
        var score = 0.5 // Neutral base
        
        for word in healthyKeywords {
            if input.contains(word) { score += 0.1 }
        }
        
        for word in unhealthyKeywords {
            if input.contains(word) { score -= 0.1 }
        }
        
        return max(0.0, min(1.0, score))
    }
    
    /// Determines the next scale and mood for the Smiley.
    func calculateNextState(from currentState: SmileyState, healthScore: Double) -> SmileyState {
        var nextState = currentState
        
        // Bloat/Shrink logic
        // Healthy (score > 0.6) -> Shrink (to a limit)
        // Unhealthy (score < 0.4) -> Bloat (to a limit)
        if healthScore > 0.6 {
            nextState.scale = max(0.5, currentState.scale - 0.1)
            nextState.mood = .serene
        } else if healthScore < 0.4 {
            nextState.scale = min(2.5, currentState.scale + 0.2)
            nextState.mood = .overwhelmed
        } else {
            // Neutral/Average
            nextState.mood = .neutral
            // Scale stays relatively same but drifts toward 1.0
            if nextState.scale > 1.0 { nextState.scale -= 0.05 }
            else if nextState.scale < 1.0 { nextState.scale += 0.05 }
        }
        
        return nextState
    }
}
