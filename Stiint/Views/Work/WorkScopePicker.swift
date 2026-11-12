import SwiftUI

struct WorkScopePicker: View {
    @Binding var selection: WorkScope
    let organizations: [WorkOrganization]
    var identifier: String = "work.scope"

    private var activeOrganizations: [WorkOrganization] {
        organizations
            .filter { !$0.archived }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private var scopeTitle: String {
        if case .organization(let id) = selection,
           !activeOrganizations.contains(where: { $0.id == id }) {
            return "Unavailable organization"
        }
        return selection.title(in: activeOrganizations)
    }

    var body: some View {
        Menu {
            Button {
                selection = .allWork
            } label: {
                optionLabel("All Work", symbol: "tray.full", selected: selection == .allWork)
            }
            .accessibilityIdentifier("\(identifier).all")

            Button {
                selection = .unassigned
            } label: {
                optionLabel("Unassigned", symbol: "tray", selected: selection == .unassigned)
            }
            .accessibilityIdentifier("\(identifier).unassigned")

            if !activeOrganizations.isEmpty {
                Divider()
                ForEach(activeOrganizations, id: \.id) { organization in
                    let scope = WorkScope.organization(organization.id)
                    Button {
                        selection = scope
                    } label: {
                        optionLabel(
                            organization.name,
                            symbol: organization.sfSymbolName ?? "building.2",
                            selected: selection == scope
                        )
                    }
                    .accessibilityIdentifier("\(identifier).organization.\(organization.id.uuidString)")
                }
            }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                Text(scopeTitle)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
            }
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.thinMaterial, in: Capsule())
            .contentShape(Capsule())
        }
        .accessibilityLabel("Work scope, \(scopeTitle)")
        .accessibilityHint("Choose all work, unassigned tasks, or an organization")
        .accessibilityIdentifier(identifier)
        .onAppear(perform: normalizeSelection)
        .onChange(of: selection) { _, _ in
            normalizeSelection()
        }
        .onChange(of: activeOrganizations.map(\.id)) { _, _ in
            normalizeSelection()
        }
    }

    private func optionLabel(_ title: String, symbol: String, selected: Bool) -> some View {
        HStack {
            Label(title, systemImage: symbol)
            Spacer(minLength: 12)
            if selected {
                Image(systemName: "checkmark")
                    .fontWeight(.semibold)
            }
        }
        .contentShape(Rectangle())
    }

    private func normalizeSelection() {
        selection = selection.normalized(in: activeOrganizations)
    }
}
