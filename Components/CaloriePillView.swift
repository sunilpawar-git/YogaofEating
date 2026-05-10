import SwiftUI

// MARK: - CaloriePillView

/// A liquid-fill pill that shows calories consumed vs TDEE target.
///
/// Accepts `CaloriePillData` — a plain data value — so it is trivially testable
/// and never depends on `MainViewModel` directly (Principle of Least Privilege).
///
/// Usage:
/// ```swift
/// CaloriePillView(data: viewModel.caloriePillData, detailData: viewModel.calorieDetailData)
/// ```
struct CaloriePillView: View {
    let data: CaloriePillData
    /// Full detail data for the sheet. `nil` for historical (read-only) pills.
    var detailData: CalorieDetailData?
    /// When `false`, tap gesture and sheet are suppressed (read-only historical pill).
    var isTappable: Bool = true

    @State private var showDetail = false

    var body: some View {
        if self.data.isVisible {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background capsule
                    Capsule()
                        .fill(Color.white.opacity(0.12))

                    // Liquid fill (progress)
                    Capsule()
                        .fill(self.data.fillColor)
                        .frame(width: max(0, self.data.progressFraction * geo.size.width))
                        .animation(.easeInOut(duration: 0.4), value: self.data.progressFraction)

                    // Label
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(FontTheme.iconSmall)
                            .foregroundColor(AppTheme.CaloriePill.flameIcon)

                        Text(self.pillLabel)
                            .font(FontTheme.caption)
                            .foregroundColor(AppTheme.CaloriePill.textPrimary)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, AppTheme.CaloriePill.pillHorizontalPadding)
                }
                .onTapGesture {
                    if self.isTappable { self.showDetail = true }
                }
            }
            .frame(
                maxWidth: AppTheme.CaloriePill.pillMaxWidth,
                minHeight: AppTheme.CaloriePill.pillHeight,
                maxHeight: AppTheme.CaloriePill.pillHeight
            )
            .accessibilityLabel(self.accessibilityLabel)
            .accessibilityValue(self.pillLabel)
            .accessibilityAddTraits(self.isTappable ? .isButton : [])
            .sheet(isPresented: self.$showDetail) {
                if self.isTappable, let detailData = self.detailData {
                    CalorieDetailSheet(data: detailData)
                }
            }
        }
    }

    // MARK: - Private helpers

    private var pillLabel: String {
        if let target = self.data.formattedTDEE {
            Strings.CaloriePill.consumedOfTarget(
                consumed: self.data.formattedConsumed,
                target: target
            )
        } else {
            Strings.CaloriePill.consumedWithSetupPrompt(self.data.formattedConsumed)
        }
    }

    private var accessibilityLabel: String {
        if let tdee = self.data.formattedTDEE {
            Strings.CaloriePill.accessibilityLabel(
                consumed: self.data.formattedConsumed,
                tdee: tdee
            )
        } else {
            Strings.CaloriePill.accessibilityLabelConsumedOnly(consumed: self.data.formattedConsumed)
        }
    }
}

// MARK: - Preview

#Preview("On track") {
    ZStack {
        Color.black.ignoresSafeArea()
        CaloriePillView(data: CaloriePillData(consumed: 1250, tdee: 2250))
            .padding(.horizontal, 40)
    }
}

#Preview("Approaching goal") {
    ZStack {
        Color.black.ignoresSafeArea()
        CaloriePillView(data: CaloriePillData(consumed: 1700, tdee: 2000))
            .padding(.horizontal, 40)
    }
}

#Preview("Over goal") {
    ZStack {
        Color.black.ignoresSafeArea()
        CaloriePillView(data: CaloriePillData(consumed: 2300, tdee: 2000))
            .padding(.horizontal, 40)
    }
}

#Preview("No TDEE set") {
    ZStack {
        Color.black.ignoresSafeArea()
        CaloriePillView(data: CaloriePillData(consumed: 850, tdee: nil))
            .padding(.horizontal, 40)
    }
}

#Preview("Hidden (no data)") {
    ZStack {
        Color.black.ignoresSafeArea()
        CaloriePillView(data: CaloriePillData(consumed: 0, tdee: nil))
            .padding(.horizontal, 40)
        Text("(pill hidden)")
            .foregroundColor(.gray)
    }
}
