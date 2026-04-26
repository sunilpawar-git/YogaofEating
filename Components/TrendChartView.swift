import Charts
import SwiftUI

struct TrendChartView: View {
    let points: [TrendPoint]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(Strings.Trends.title)
                    .font(.title2)
                    .fontWeight(.bold)

                if self.points.isEmpty {
                    Text(Strings.Trends.emptyState)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 40)
                } else {
                    self.bisChart
                    self.moduleChart
                    self.sleepChart
                }
            }
            .padding()
        }
    }

    private var bisChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Strings.Trends.bisTitle).font(.headline)
            Chart(self.points) { point in
                LineMark(
                    x: .value(Strings.Trends.axisDate, point.date),
                    y: .value(Strings.Trends.axisBIS, point.bis)
                )
                .foregroundStyle(Color.purple)
            }
            .frame(height: 180)
        }
    }

    private var moduleChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Strings.Trends.moduleTitle).font(.headline)
            Chart(self.points) { point in
                BarMark(
                    x: .value(Strings.Trends.axisDate, point.date),
                    y: .value(Strings.Trends.axisReflect, point.reflect)
                )
                .foregroundStyle(Color.purple)
                BarMark(
                    x: .value(Strings.Trends.axisDate, point.date),
                    y: .value(Strings.Trends.axisLaser, point.laser)
                )
                .foregroundStyle(Color.orange)
                BarMark(
                    x: .value(Strings.Trends.axisDate, point.date),
                    y: .value(Strings.Trends.axisHighlight, point.highlight)
                )
                .foregroundStyle(Color.teal)
                BarMark(
                    x: .value(Strings.Trends.axisDate, point.date),
                    y: .value(Strings.Trends.axisEnergise, point.energise)
                )
                .foregroundStyle(Color.green)
            }
            .frame(height: 220)
        }
    }

    private var sleepChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Strings.Trends.sleepTitle).font(.headline)
            Chart(self.points) { point in
                AreaMark(
                    x: .value(Strings.Trends.axisDate, point.date),
                    y: .value(Strings.Trends.axisSleep, point.sleepScore)
                )
                .foregroundStyle(Color.blue.opacity(0.35))
            }
            .frame(height: 180)
        }
    }
}
