import SwiftUI

/// Card body for the Laser (focus/execution) module.
/// Shows morning todos with check status and focus rating.
struct LaserCardBody: View {
    let dataSource: ModuleCardDataSource

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            if self.dataSource.cardMorningTodos.isEmpty {
                self.emptyState
            } else {
                self.todoList
            }

            self.focusRow
        }
    }
}

// MARK: - Subviews

private extension LaserCardBody {
    var emptyState: some View {
        Text(Strings.Home.noTodosYet)
            .font(.subheadline)
            .foregroundColor(.secondary)
    }

    var todoList: some View {
        ForEach(self.dataSource.cardMorningTodos.prefix(AppTheme.Card.maxVisibleTodos)) { entry in
            HStack(spacing: 6) {
                Image(systemName: self.checkIcon(for: entry))
                    .font(.caption)
                    .foregroundColor(self.checkColor(for: entry))
                Text(entry.text)
                    .font(.subheadline)
                    .lineLimit(1)
                    .foregroundColor(.primary)
            }
        }
    }

    var focusRow: some View {
        HStack(spacing: 4) {
            Image(systemName: "scope")
                .font(.caption)
            if let rating = self.dataSource.cardFocusRating {
                Text("\(rating)/3")
                    .font(.subheadline)
            } else {
                Text(Strings.Home.focusNotRated)
                    .font(.caption)
            }
        }
        .foregroundColor(.secondary)
    }

    func checkIcon(for entry: MindCheckEntry) -> String {
        if entry.isAccomplished == true {
            return "checkmark.circle.fill"
        }
        if entry.isAccomplished == false {
            return "xmark.circle"
        }
        return "circle"
    }

    func checkColor(for entry: MindCheckEntry) -> Color {
        if entry.isAccomplished == true { return .green }
        if entry.isAccomplished == false { return .red }
        return .secondary
    }
}
