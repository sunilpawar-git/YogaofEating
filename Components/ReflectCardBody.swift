import SwiftUI

/// Card body for the Reflect (morning) module.
/// Shows sleep quality badge, energy level, and daily intention.
struct ReflectCardBody: View {
    let dataSource: ModuleCardDataSource

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            if let sleep = self.dataSource.cardSleepQuality {
                self.sleepBadge(sleep)
            }

            if let energy = self.dataSource.cardEnergyLevel {
                self.energyRow(energy)
            }

            if let intention = self.dataSource.cardIntention {
                self.intentionDisplay(intention)
            } else {
                self.setIntentionButton
            }
        }
    }
}

// MARK: - Subviews

private extension ReflectCardBody {
    func sleepBadge(_ quality: SleepQuality) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "moon.fill")
                .font(.caption)
            Text(quality.displayName)
                .font(.subheadline)
        }
        .foregroundColor(AppTheme.ModuleColors.reflect)
    }

    func energyRow(_ level: Int) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "bolt.fill")
                .font(.caption)
            Text("\(level)/5")
                .font(.subheadline)
        }
        .foregroundColor(.secondary)
    }

    func intentionDisplay(_ text: String) -> some View {
        Text(text)
            .font(.body)
            .foregroundColor(.primary)
            .lineLimit(2)
    }

    var setIntentionButton: some View {
        Button {
            self.dataSource.triggerSetIntention()
        } label: {
            Label(Strings.Home.setIntentionPrompt, systemImage: "plus.circle")
                .font(.subheadline.weight(.medium))
                .foregroundColor(AppTheme.ModuleColors.reflect)
        }
    }
}
