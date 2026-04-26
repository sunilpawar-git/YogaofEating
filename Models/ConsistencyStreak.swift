import Foundation

struct ConsistencyStreak: Equatable {
    let current: Int
    let best: Int
    let todayLogged: Bool

    static let empty = ConsistencyStreak(
        current: 0, best: 0, todayLogged: false
    )
}
