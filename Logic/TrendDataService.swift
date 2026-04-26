import Foundation

struct TrendPoint: Equatable {
    let date: Date
    let bis: Double
    let sleepScore: Double
    let reflect: Double
    let laser: Double
    let highlight: Double
    let energise: Double
}

extension TrendPoint: Identifiable {
    var id: Date { self.date }
}

enum TrendDataService {
    static func buildTrendPoints(
        snapshots: [DailySmileySnapshot],
        days: Int
    ) -> [TrendPoint] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -(days - 1), to: Date()) ?? Date()
        let filtered = snapshots
            .filter { $0.date >= Calendar.current.startOfDay(for: cutoff) }
            .sorted { $0.date < $1.date }

        return filtered.map { snapshot in
            let module = DayModuleProgress.compute(from: snapshot)
            let bis = BodyIntelligenceService.compute(from: snapshot, sleepData: nil)
            let subjectiveSleep = self.sleepScore(from: snapshot)
            return TrendPoint(
                date: snapshot.date,
                bis: bis.value,
                sleepScore: subjectiveSleep,
                reflect: module.reflectProgress * 100,
                laser: module.laserProgress * 100,
                highlight: module.highlightProgress * 100,
                energise: module.energiseProgress * 100
            )
        }
    }

    private static func sleepScore(from snapshot: DailySmileySnapshot) -> Double {
        snapshot.reflection?.sleepQuality?.subjectiveScore ?? 0
    }
}
