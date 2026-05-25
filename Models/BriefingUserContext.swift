import Foundation

/// Compact personalization context sent to the Cloud Function with each briefing request.
/// Built once per lifecycle call from the user's health profile and auth service.
struct BriefingUserContext: Codable {
    // userName is user-controlled input — never logged, only serialised
    let userName: String?
    let activityLevel: ActivityLevel
    let dietaryGoal: DietaryGoal?

    /// Returns `nil` if no health profile exists — briefing still works without personalization.
    static func build(
        from profile: UserHealthProfile?,
        authService: (any AuthServiceProtocol)?
    ) -> BriefingUserContext? {
        guard let profile else { return nil }
        let name: String? = if let displayName = authService?.currentUser?.displayName, !displayName.isEmpty {
            displayName
        } else {
            nil
        }
        return BriefingUserContext(
            userName: name,
            activityLevel: profile.activityLevel,
            dietaryGoal: profile.dietaryGoal
        )
    }

    func toPayloadDict() -> [String: Any] {
        var dict: [String: Any] = ["activityLevel": self.activityLevel.displayName]
        if let name = self.userName {
            dict["name"] = name
        }
        if let goal = self.dietaryGoal {
            dict["dietaryGoal"] = goal.displayName
        }
        return dict
    }
}
