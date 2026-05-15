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
            // Label drives the size; liquid fill lives in the background so GeometryReader
            // receives the already-resolved content size (not the available space).
            HStack(spacing: 2) {
                Text(Strings.CaloriePill.pillLeadingChevron)
                    .font(FontTheme.caption)
                    .foregroundColor(AppTheme.CaloriePill.textChevron)

                Text(self.pillLabel)
                    .font(FontTheme.caption)
                    .foregroundColor(AppTheme.CaloriePill.textPrimary)
                    .lineLimit(1)

                Text(Strings.CaloriePill.pillTrailingChevron)
                    .font(FontTheme.caption)
                    .foregroundColor(AppTheme.CaloriePill.textChevron)
            }
            .padding(.vertical, AppTheme.CaloriePill.pillVerticalPadding)
            .padding(.horizontal, AppTheme.CaloriePill.pillHorizontalPadding)
            .background {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(AppTheme.CaloriePill.pillBackground)
                        Capsule()
                            .fill(self.data.fillColor)
                            .frame(width: max(0, self.data.progressFraction * geo.size.width))
                            .animation(.easeInOut(duration: 0.4), value: self.data.progressFraction)
                    }
                }
            }
            .clipShape(Capsule())
            .onTapGesture {
                if self.isTappable { self.showDetail = true }
            }
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
    }
}

#Preview("Approaching goal") {
    ZStack {
        Color.black.ignoresSafeArea()
        CaloriePillView(data: CaloriePillData(consumed: 1700, tdee: 2000))
    }
}

#Preview("Over goal") {
    ZStack {
        Color.black.ignoresSafeArea()
        CaloriePillView(data: CaloriePillData(consumed: 2300, tdee: 2000))
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
