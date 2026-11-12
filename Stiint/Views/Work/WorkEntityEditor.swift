import CoreLocation
import SwiftData
import SwiftUI

struct WorkEditorRequest: Identifiable {
    let id = UUID()
    let kind: WorkEntityKind
    let entityID: UUID?
    let defaultParent: WorkParent?

    init(kind: WorkEntityKind, entityID: UUID? = nil, defaultParent: WorkParent? = nil) {
        self.kind = kind
        self.entityID = entityID
        self.defaultParent = defaultParent
    }
}

private enum AppearanceMode: Equatable {
    case inherit
    case custom
}

private enum WorkEditorAlert: Identifiable {
    case saveError(String)
    case automation

    var id: String {
        switch self {
        case .saveError: "saveError"
        case .automation: "automation"
        }
    }
}

private struct ParentAppearanceSource {
    let name: String
    let colorHex: String?
    let symbolName: String?
}

private struct ParentChoice: Identifiable {
    let parent: WorkParent
    let title: String

    var id: String {
        "\(parent.kind.rawValue).\(parent.id.uuidString)"
    }
}

private struct WorkIconChoice: Identifiable {
    let name: String
    let title: String

    var id: String { name }
}

private struct WorkColorChoice: Identifiable {
    let name: String
    let hex: String

    var id: String { hex }
}

private struct WorkColorChooser: View {
    @Binding var mode: AppearanceMode
    @Binding var color: Color

    let inheritedColorHex: String
    let inheritedSourceName: String?

    private let columns = [GridItem(.adaptive(minimum: 64), spacing: 12)]
    private let colors = [
        WorkColorChoice(name: "Blue", hex: "#3478F6"),
        WorkColorChoice(name: "Teal", hex: "#20A89A"),
        WorkColorChoice(name: "Green", hex: "#32A852"),
        WorkColorChoice(name: "Yellow", hex: "#E0A91B"),
        WorkColorChoice(name: "Orange", hex: "#EE7A27"),
        WorkColorChoice(name: "Red", hex: "#E34B4B"),
        WorkColorChoice(name: "Pink", hex: "#D64A91"),
        WorkColorChoice(name: "Purple", hex: "#8959D5"),
        WorkColorChoice(name: "Indigo", hex: "#535AC8"),
        WorkColorChoice(name: "Gray", hex: "#77808C")
    ]

    private var inheritedLabel: String {
        if let inheritedSourceName { return "Use \(inheritedSourceName)'s color" }
        return "Use default color"
    }

    var body: some View {
        Form {
            Section {
                Button {
                    mode = .inherit
                } label: {
                    HStack {
                        Label(inheritedLabel, systemImage: "arrow.uturn.backward")
                        Spacer()
                        if mode == .inherit {
                            Image(systemName: "checkmark")
                                .fontWeight(.semibold)
                                .foregroundStyle(.tint)
                        }
                        Circle()
                            .fill(Color(hex: inheritedColorHex))
                            .frame(width: 20, height: 20)
                            .overlay(Circle().strokeBorder(.primary.opacity(0.12), lineWidth: 1))
                            .accessibilityHidden(true)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("work.appearance.color.source")
            }

            Section("Colors") {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(colors) { choice in
                        let isSelected = mode == .custom && color.toHex() == choice.hex
                        Button {
                            color = Color(hex: choice.hex)
                            mode = .custom
                        } label: {
                            VStack(spacing: 7) {
                                Circle()
                                    .fill(Color(hex: choice.hex))
                                    .frame(width: 34, height: 34)
                                    .overlay {
                                        if isSelected {
                                            Image(systemName: "checkmark")
                                                .font(.caption.weight(.bold))
                                                .foregroundStyle(.white)
                                        }
                                    }
                                Text(choice.name)
                                    .font(.caption)
                                    .foregroundStyle(.primary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 5)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(choice.name)
                        .accessibilityAddTraits(isSelected ? .isSelected : [])
                    }
                }
                .padding(.vertical, 4)

                ColorPicker(
                    "Choose another color",
                    selection: Binding(
                        get: { color },
                        set: { newColor in
                            color = newColor
                            mode = .custom
                        }
                    ),
                    supportsOpacity: false
                )
                .accessibilityIdentifier("work.appearance.color.custom")
            }
        }
        .navigationTitle("Color")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct WorkIconChooser: View {
    @Binding var mode: AppearanceMode
    @Binding var symbolName: String

    let inheritedSourceName: String?
    let choices: [WorkIconChoice]

    private let columns = [GridItem(.adaptive(minimum: 88), spacing: 12)]

    private var inheritedLabel: String {
        if let inheritedSourceName { return "Use \(inheritedSourceName)'s icon" }
        return "Use default icon"
    }

    var body: some View {
        Form {
            Section {
                Button {
                    mode = .inherit
                } label: {
                    HStack {
                        Label(inheritedLabel, systemImage: "arrow.uturn.backward")
                        Spacer()
                        if mode == .inherit {
                            Image(systemName: "checkmark")
                                .fontWeight(.semibold)
                                .foregroundStyle(.tint)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("work.appearance.icon.source")
            }

            Section("Icons") {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(choices) { choice in
                        let isSelected = mode == .custom && symbolName == choice.name
                        Button {
                            symbolName = choice.name
                            mode = .custom
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: choice.name)
                                    .font(.title3)
                                    .frame(height: 28)
                                Text(choice.title)
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                            }
                            .frame(maxWidth: .infinity, minHeight: 68)
                            .padding(6)
                            .background {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(isSelected ? Color.accentColor.opacity(0.13) : Color.clear)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(choice.title)
                        .accessibilityAddTraits(isSelected ? .isSelected : [])
                        .accessibilityIdentifier("work.appearance.icon.custom.\(choice.name)")
                    }
                }
                .padding(.vertical, 4)
                .accessibilityIdentifier("work.appearance.icon.custom")
            }
        }
        .navigationTitle("Icon")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct WorkEntityEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \WorkOrganization.name) private var organizations: [WorkOrganization]
    @Query(sort: \WorkClient.name) private var clients: [WorkClient]
    @Query(sort: \WorkProject.name) private var projects: [WorkProject]
    @Query private var tasks: [ActivityItem]

    let request: WorkEditorRequest
    var onTaskCreated: ((UUID) -> Void)? = nil

    @State private var name = ""
    @State private var didLoadValues = false
    @State private var selectedParent: WorkParent?
    @State private var colorMode = AppearanceMode.inherit
    @State private var iconMode = AppearanceMode.inherit
    @State private var customColor = Color(hex: WorkHierarchy.defaultColorHex)
    @State private var customSymbolName = WorkHierarchy.defaultSymbolName
    @State private var weekdays: Set<Weekday> = Set(Weekday.allCases)
    @State private var storeLocation = false
    @State private var showDayPicker = false
    @State private var isSaving = false
    @State private var activeAlert: WorkEditorAlert?

    private let locationHandler = LocationHandler()

    private let symbols = [
        WorkIconChoice(name: "book.fill", title: "Reading"),
        WorkIconChoice(name: "briefcase.fill", title: "Work"),
        WorkIconChoice(name: "building.2.fill", title: "Organization"),
        WorkIconChoice(name: "person.2.fill", title: "Clients"),
        WorkIconChoice(name: "folder.fill", title: "Project"),
        WorkIconChoice(name: "checkmark.circle.fill", title: "Task"),
        WorkIconChoice(name: "desktopcomputer", title: "Computer"),
        WorkIconChoice(name: "hammer.fill", title: "Tools"),
        WorkIconChoice(name: "pencil.and.outline", title: "Writing"),
        WorkIconChoice(name: "phone.fill", title: "Calls"),
        WorkIconChoice(name: "house.fill", title: "Home"),
        WorkIconChoice(name: "star.fill", title: "Favorite"),
        WorkIconChoice(name: "wrench.and.screwdriver.fill", title: "Maintenance"),
        WorkIconChoice(name: "cart.fill", title: "Shopping"),
        WorkIconChoice(name: "figure.run", title: "Exercise"),
        WorkIconChoice(name: "heart.fill", title: "Health")
    ]

    private var isNew: Bool { request.entityID == nil }
    private var isTask: Bool { request.kind == .task }
    private var title: String {
        let action = isNew ? "New" : "Edit"
        return switch request.kind {
        case .organization: "\(action) Organization"
        case .client: "\(action) Client"
        case .project: "\(action) Project"
        case .task: "\(action) Task"
        }
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !isSaving && parentIsAvailable
    }

    private var parentIsAvailable: Bool {
        switch request.kind {
        case .organization:
            return true
        case .client:
            guard case .organization(let id) = selectedParent else { return false }
            return organizations.contains { $0.id == id && !$0.archived }
        case .project:
            guard case .client(let id) = selectedParent else { return false }
            return availableClients.contains { $0.id == id }
        case .task:
            guard let selectedParent else { return true }
            switch selectedParent {
            case .organization(let id):
                return organizations.contains { $0.id == id && !$0.archived }
            case .client(let id):
                return availableClients.contains { $0.id == id }
            case .project(let id):
                return availableProjects.contains { $0.id == id }
            }
        }
    }

    private var activeOrganizations: [WorkOrganization] {
        organizations.filter { !$0.archived }
    }

    private var activeOrganizationIDs: Set<UUID> {
        Set(activeOrganizations.map(\.id))
    }

    private var availableClients: [WorkClient] {
        clients.filter { client in
            guard !client.archived, let organizationID = client.organizationID else { return false }
            return activeOrganizationIDs.contains(organizationID)
        }
    }

    private var availableProjects: [WorkProject] {
        let clientIDs = Set(availableClients.map(\.id))
        return projects.filter { project in
            guard !project.archived, let clientID = project.clientID else { return false }
            return clientIDs.contains(clientID)
        }
    }

    private var parentChoices: [ParentChoice] {
        var choices: [ParentChoice] = []

        if request.kind == .task || request.kind == .client {
            choices += activeOrganizations.map { organization in
                ParentChoice(parent: .organization(organization.id), title: organization.name)
            }
        }

        if request.kind == .task || request.kind == .project {
            choices += availableClients.map { client in
                ParentChoice(
                    parent: .client(client.id),
                    title: "\(organizationName(for: client)) › \(client.name)"
                )
            }
        }

        if request.kind == .task {
            choices += availableProjects.map { project in
                ParentChoice(
                    parent: .project(project.id),
                    title: "\(clientPath(for: project)) › \(project.name)"
                )
            }
        }

        if let selectedParent, !choices.contains(where: { $0.parent == selectedParent }),
           let title = parentTitle(selectedParent) {
            choices.append(ParentChoice(parent: selectedParent, title: "Archived — \(title)"))
        }
        return choices
    }

    private var ancestorSources: [ParentAppearanceSource] {
        guard let selectedParent else { return [] }
        switch selectedParent {
        case .organization(let id):
            guard let organization = organizations.first(where: { $0.id == id }) else { return [] }
            return [ParentAppearanceSource(name: organization.name,
                                           colorHex: organization.colorHex,
                                           symbolName: organization.sfSymbolName)]
        case .client(let id):
            guard let client = clients.first(where: { $0.id == id }) else { return [] }
            let organization = organizations.first(where: { $0.id == client.organizationID })
            var sources = [
                ParentAppearanceSource(name: client.name, colorHex: client.colorHex,
                                       symbolName: client.sfSymbolName)
            ]
            if let organization {
                sources.append(ParentAppearanceSource(name: organization.name,
                                                      colorHex: organization.colorHex,
                                                      symbolName: organization.sfSymbolName))
            }
            return sources
        case .project(let id):
            guard let project = projects.first(where: { $0.id == id }) else { return [] }
            let client = clients.first(where: { $0.id == project.clientID })
            let organization = organizations.first(where: { $0.id == client?.organizationID })
            let projectSource = ParentAppearanceSource(name: project.name,
                                                       colorHex: project.colorHex,
                                                       symbolName: project.sfSymbolName)
            let clientSources = client.map {
                [ParentAppearanceSource(name: $0.name, colorHex: $0.colorHex,
                                        symbolName: $0.sfSymbolName)]
            } ?? []
            let organizationSources = organization.map {
                [ParentAppearanceSource(name: $0.name, colorHex: $0.colorHex,
                                        symbolName: $0.sfSymbolName)]
            } ?? []
            return [projectSource] + clientSources + organizationSources
        }
    }

    private var parentSnapshot: WorkSnapshot? {
        try? WorkHierarchy.resolve(parent: selectedParent, in: modelContext)
    }

    private var inheritedParentNode: WorkNodeSnapshot? {
        guard let selectedParent, let parentSnapshot else { return nil }
        return switch selectedParent {
        case .organization: parentSnapshot.organization
        case .client: parentSnapshot.client
        case .project: parentSnapshot.project
        }
    }

    private var inheritedColorHex: String {
        inheritedParentNode?.colorHex ?? WorkHierarchy.defaultColorHex
    }

    private var inheritedSymbolName: String {
        inheritedParentNode?.sfSymbolName ?? WorkHierarchy.defaultSymbolName
    }

    private var resolvedColorHex: String {
        colorMode == .custom ? (customColor.toHex() ?? inheritedColorHex) : inheritedColorHex
    }

    private var resolvedSymbolName: String {
        iconMode == .custom ? customSymbolName : inheritedSymbolName
    }

    private var colorSourceName: String {
        if colorMode == .custom { return "Custom" }
        return inheritedColorSourceName ?? "Minutide default"
    }

    private var iconSourceName: String {
        if iconMode == .custom { return "Custom" }
        return inheritedIconSourceName ?? "Minutide default"
    }

    private var inheritedColorSourceName: String? {
        ancestorSources.first(where: { $0.colorHex != nil })?.name
    }

    private var inheritedIconSourceName: String? {
        ancestorSources.first(where: { $0.symbolName != nil })?.name
    }

    private var colorSummary: String {
        if colorMode == .custom { return "Custom" }
        return inheritedColorSourceName.map { "Same as \($0)" } ?? "Default"
    }

    private var iconSummary: String {
        if iconMode == .custom { return "Custom" }
        return inheritedIconSourceName.map { "Same as \($0)" } ?? "Default"
    }

    private var availableSymbols: [WorkIconChoice] {
        guard !customSymbolName.isEmpty,
              !symbols.contains(where: { $0.name == customSymbolName }) else { return symbols }
        return [WorkIconChoice(name: customSymbolName, title: "Current icon")] + symbols
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name", text: $name)
                        .accessibilityIdentifier(isTask ? "task.name" : "work.entity.name")

                    parentPicker
                }

                Section("Appearance") {
                    HStack {
                        Label(name.isEmpty ? request.kind.rawValue.capitalized : name,
                              systemImage: resolvedSymbolName)
                            .font(.headline)
                            .padding(12)
                            .foregroundStyle(Color(hex: resolvedColorHex))
                            .background(Color(hex: resolvedColorHex).opacity(0.16), in: RoundedRectangle(cornerRadius: 12))
                        Spacer(minLength: 0)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Preview: \(name.isEmpty ? request.kind.rawValue : name)")
                    .accessibilityValue("Color from \(colorSourceName), icon from \(iconSourceName)")
                    .accessibilityIdentifier("work.appearance.preview")

                    NavigationLink {
                        WorkColorChooser(
                            mode: $colorMode,
                            color: $customColor,
                            inheritedColorHex: inheritedColorHex,
                            inheritedSourceName: inheritedColorSourceName
                        )
                    } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Color")
                                    .foregroundStyle(.primary)
                                Text(colorSummary)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Circle()
                                .fill(Color(hex: resolvedColorHex))
                                .frame(width: 24, height: 24)
                                .overlay(Circle().strokeBorder(.primary.opacity(0.12), lineWidth: 1))
                                .accessibilityHidden(true)
                        }
                    }
                    .accessibilityIdentifier("work.appearance.color.mode")

                    NavigationLink {
                        WorkIconChooser(
                            mode: $iconMode,
                            symbolName: $customSymbolName,
                            inheritedSourceName: inheritedIconSourceName,
                            choices: availableSymbols
                        )
                    } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Icon")
                                    .foregroundStyle(.primary)
                                Text(iconSummary)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: resolvedSymbolName)
                                .font(.title3)
                                .foregroundStyle(Color(hex: resolvedColorHex))
                                .frame(width: 28, height: 28)
                                .accessibilityHidden(true)
                        }
                    }
                    .accessibilityIdentifier("work.appearance.icon.mode")
                }

                if isTask {
                    Section("Timer and Shortcuts") {
                        Button {
                            showDayPicker = true
                        } label: {
                            LabeledContent("Automatic days", value: trackedDaysText)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("task.weekdays")

                        Toggle("Store location", isOn: $storeLocation)
                            .onChange(of: storeLocation) { _, enabled in
                                if enabled { locationHandler.requestAuthorization() }
                            }
                            .disabled(locationHandler.authorizationStatus == .denied)
                            .accessibilityIdentifier("task.storeLocation")

                        if locationHandler.authorizationStatus == .denied
                            || locationHandler.authorizationStatus == .restricted {
                            Link("Go to Settings", destination: URL(string: UIApplication.openSettingsURLString)!)
                        }
                    }
                }
            }
            .disabled(isSaving)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving…" : "Save", action: save)
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                        .accessibilityIdentifier(isTask ? "task.save" : "work.entity.save")
                }
            }
            .onAppear(perform: loadExistingValues)
            .sheet(isPresented: $showDayPicker) {
                DayPickerView(selectedDays: $weekdays)
            }
            .alert(item: $activeAlert) { alert in
                switch alert {
                case .saveError(let message):
                    Alert(
                        title: Text("Couldn't save this item"),
                        message: Text(message),
                        dismissButton: .default(Text("OK"))
                    )
                case .automation:
                    Alert(
                        title: Text("What would you like to do?"),
                        message: Text("You can create a Shortcut automation for this task now or do it later."),
                        primaryButton: .default(Text("Create Automation Now"), action: createAutomationAndDismiss),
                        secondaryButton: .cancel(Text("Do It Later"), action: { dismiss() })
                    )
                }
            }
        }
        .interactiveDismissDisabled(isSaving)
    }

    @ViewBuilder
    private var parentPicker: some View {
        switch request.kind {
        case .organization:
            EmptyView()
        case .client:
            Picker("Organization", selection: $selectedParent) {
                Text("Choose organization").tag(nil as WorkParent?)
                ForEach(activeOrganizations, id: \.id) { organization in
                    Text(organization.name)
                        .tag(WorkParent?.some(.organization(organization.id)))
                        .accessibilityIdentifier("work.client.organization.\(organization.id.uuidString)")
                }
            }
            .pickerStyle(.menu)
            .accessibilityIdentifier("work.client.organization")
        case .project:
            Picker("Client", selection: $selectedParent) {
                Text("Choose client").tag(nil as WorkParent?)
                ForEach(availableClients, id: \.id) { client in
                    Text("\(organizationName(for: client)) › \(client.name)")
                        .tag(WorkParent?.some(.client(client.id)))
                        .accessibilityIdentifier("work.project.client.\(client.id.uuidString)")
                }
            }
            .pickerStyle(.menu)
            .accessibilityIdentifier("work.project.client")
        case .task:
            Picker("Location", selection: $selectedParent) {
                Text("Unassigned").tag(nil as WorkParent?)
                    .accessibilityIdentifier("task.location.unassigned")

                Section("Organizations") {
                    ForEach(activeOrganizations, id: \.id) { organization in
                        Text(organization.name)
                            .tag(WorkParent?.some(.organization(organization.id)))
                            .accessibilityIdentifier("task.location.organization.\(organization.id.uuidString)")
                    }
                }

                Section("Clients") {
                    ForEach(availableClients, id: \.id) { client in
                        Text("\(organizationName(for: client)) › \(client.name)")
                            .tag(WorkParent?.some(.client(client.id)))
                            .accessibilityIdentifier("task.location.client.\(client.id.uuidString)")
                    }
                }

                Section("Projects") {
                    ForEach(availableProjects, id: \.id) { project in
                        Text("\(clientPath(for: project)) › \(project.name)")
                            .tag(WorkParent?.some(.project(project.id)))
                            .accessibilityIdentifier("task.location.project.\(project.id.uuidString)")
                    }
                }

                let currentChoice = selectedParent.flatMap { selected in
                    parentChoices.first(where: { $0.parent == selected })
                }
                if let currentChoice, currentChoice.title.hasPrefix("Archived — ") {
                    Section("Current archived location") {
                        Text(currentChoice.title)
                            .tag(WorkParent?.some(currentChoice.parent))
                            .accessibilityIdentifier("task.location.archived")
                    }
                }
            }
            .pickerStyle(.menu)
            .accessibilityIdentifier("task.location")
        }
    }

    private var trackedDaysText: String {
        guard !weekdays.isEmpty else { return "None" }
        return weekdays.sorted { $0.rawValue < $1.rawValue }.map(\.shortTitle).joined(separator: ", ")
    }

    private func loadExistingValues() {
        guard !didLoadValues else { return }
        didLoadValues = true
        var explicitColor: String?
        var explicitSymbol: String?

        switch request.kind {
        case .organization:
            if let id = request.entityID, let organization = organizations.first(where: { $0.id == id }) {
                name = organization.name
                explicitColor = organization.colorHex
                explicitSymbol = organization.sfSymbolName
            }
        case .client:
            if let id = request.entityID, let client = clients.first(where: { $0.id == id }) {
                name = client.name
                selectedParent = client.organizationID.map(WorkParent.organization)
                explicitColor = client.colorHex
                explicitSymbol = client.sfSymbolName
            } else {
                selectedParent = request.defaultParent
            }
        case .project:
            if let id = request.entityID, let project = projects.first(where: { $0.id == id }) {
                name = project.name
                selectedParent = project.clientID.map(WorkParent.client)
                explicitColor = project.colorHex
                explicitSymbol = project.sfSymbolName
            } else {
                selectedParent = request.defaultParent
            }
        case .task:
            if let id = request.entityID, let task = tasks.first(where: { $0.id == id }) {
                name = task.name ?? ""
                selectedParent = task.workParent
                explicitColor = task.colorHex
                explicitSymbol = task.sfSymbolName
                weekdays = task.weekdays ?? Set(Weekday.allCases)
                storeLocation = task.storeLocation ?? false
            } else {
                selectedParent = request.defaultParent
            }
        }

        colorMode = explicitColor == nil ? .inherit : .custom
        iconMode = explicitSymbol == nil ? .inherit : .custom
        customColor = Color(hex: explicitColor ?? inheritedColorHex)
        customSymbolName = explicitSymbol ?? inheritedSymbolName
    }

    private func save() {
        guard canSave else { return }
        isSaving = true
        Task {
            do {
                let colorHex = colorMode == .custom ? customColor.toHex() : nil
                if colorMode == .custom && colorHex == nil {
                    throw WorkHierarchyError.invalidColor
                }
                let symbolName = iconMode == .custom ? customSymbolName : nil
                let actor = PersistenceManager.shared.workHierarchyActor

                var createdTaskID: UUID?
                switch request.kind {
                case .organization:
                    _ = try await actor.saveOrganization(
                        id: request.entityID,
                        name: name,
                        colorHex: colorHex,
                        sfSymbolName: symbolName
                    )
                case .client:
                    guard case .organization(let organizationID) = selectedParent else {
                        throw WorkHierarchyError.invalidParent
                    }
                    _ = try await actor.saveClient(
                        id: request.entityID,
                        name: name,
                        organizationID: organizationID,
                        colorHex: colorHex,
                        sfSymbolName: symbolName
                    )
                case .project:
                    guard case .client(let clientID) = selectedParent else {
                        throw WorkHierarchyError.invalidParent
                    }
                    _ = try await actor.saveProject(
                        id: request.entityID,
                        name: name,
                        clientID: clientID,
                        colorHex: colorHex,
                        sfSymbolName: symbolName
                    )
                case .task:
                    createdTaskID = try await actor.saveTask(
                        id: request.entityID,
                        name: name,
                        parent: selectedParent,
                        colorHex: colorHex,
                        sfSymbolName: symbolName,
                        weekdays: weekdays,
                        storeLocation: storeLocation
                    )
                }

                isSaving = false
                if isTask && isNew {
                    if let createdTaskID, let onTaskCreated {
                        onTaskCreated(createdTaskID)
                        dismiss()
                    } else {
                        activeAlert = .automation
                    }
                } else {
                    dismiss()
                }
            } catch {
                isSaving = false
                activeAlert = .saveError(error.localizedDescription)
            }
        }
    }

    private func createAutomationAndDismiss() {
        openAutomationPage()
        dismiss()
    }

    private func organizationName(for client: WorkClient) -> String {
        organizations.first(where: { $0.id == client.organizationID })?.name ?? "Archived organization"
    }

    private func clientPath(for project: WorkProject) -> String {
        guard let client = clients.first(where: { $0.id == project.clientID }) else {
            return "Archived client"
        }
        return "\(organizationName(for: client)) › \(client.name)"
    }

    private func parentTitle(_ parent: WorkParent) -> String? {
        switch parent {
        case .organization(let id):
            organizations.first(where: { $0.id == id })?.name
        case .client(let id):
            clients.first(where: { $0.id == id }).map { "\(organizationName(for: $0)) › \($0.name)" }
        case .project(let id):
            projects.first(where: { $0.id == id }).map { "\(clientPath(for: $0)) › \($0.name)" }
        }
    }
}
