import SwiftData
import SwiftUI

private enum WorkLocation: Hashable {
    case organization(UUID)
    case client(UUID)
    case project(UUID)

    var kind: WorkEntityKind {
        switch self {
        case .organization: .organization
        case .client: .client
        case .project: .project
        }
    }

    var entityID: UUID {
        switch self {
        case .organization(let id), .client(let id), .project(let id): id
        }
    }

    var parent: WorkParent {
        switch self {
        case .organization(let id): .organization(id)
        case .client(let id): .client(id)
        case .project(let id): .project(id)
        }
    }
}

private struct WorkArchiveTarget: Identifiable {
    let kind: WorkEntityKind
    let entityID: UUID
    let name: String

    var id: String { "\(kind.rawValue).\(entityID.uuidString)" }
}

struct WorkManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \WorkOrganization.name) private var organizations: [WorkOrganization]
    @Query(sort: \WorkClient.name) private var clients: [WorkClient]
    @Query(sort: \WorkProject.name) private var projects: [WorkProject]
    @Query private var tasks: [ActivityItem]

    @State private var path: [WorkLocation] = []
    @State private var editorRequest: WorkEditorRequest?
    @State private var archiveTarget: WorkArchiveTarget?
    @State private var showArchiveConfirmation = false
    @State private var operationError: String?
    @State private var showOperationError = false

    private var activeOrganizations: [WorkOrganization] {
        organizations.filter { !$0.archived }
    }

    private var archivedOrganizations: [WorkOrganization] {
        organizations.filter(\.archived)
    }

    private var unassignedActiveTasks: [ActivityItem] {
        tasks.filter { $0.archived != true && $0.workParent == nil }
            .sorted { ($0.name ?? "").localizedStandardCompare($1.name ?? "") == .orderedAscending }
    }

    private var unassignedArchivedTasks: [ActivityItem] {
        tasks.filter { $0.archived == true && $0.workParent == nil }
            .sorted { ($0.name ?? "").localizedStandardCompare($1.name ?? "") == .orderedAscending }
    }

    var body: some View {
        // This sheet owns the entire hierarchy path, including its root. Keep
        // these value destinations separate from the Tasks tab's navigation.
        NavigationStack(path: $path) {
            managementList
        }
    }

    private var managementList: some View {
        List {
            Section("Organizations") {
                if activeOrganizations.isEmpty {
                    ContentUnavailableView("No organizations yet", systemImage: "building.2",
                                           description: Text("Add one to group clients, projects, and tasks."))
                } else {
                    ForEach(activeOrganizations) { organization in
                        organizationRow(organization, archived: false)
                    }
                }
            }

            Section("Unassigned tasks") {
                if unassignedActiveTasks.isEmpty {
                    Text("Tasks without an organization, client, or project appear here.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(unassignedActiveTasks) { task in
                        taskRow(task)
                    }
                }
            }

            if !archivedOrganizations.isEmpty {
                Section("Archived organizations") {
                    ForEach(archivedOrganizations) { organization in
                        organizationRow(organization, archived: true)
                    }
                }
            }

            if !unassignedArchivedTasks.isEmpty {
                Section("Archived unassigned tasks") {
                    ForEach(unassignedArchivedTasks) { task in
                        taskRow(task)
                    }
                }
            }
        }
        .navigationTitle("Manage Work")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
                    .accessibilityIdentifier("work.done")
            }
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("New Organization", systemImage: "building.2") {
                        openEditor(kind: .organization)
                    }
                    .accessibilityIdentifier("work.organization.add")

                    Button("New Task", systemImage: "checkmark.circle") {
                        openEditor(kind: .task)
                    }
                    .accessibilityIdentifier("task.add")
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add work")
                .accessibilityIdentifier("work.add")
            }
        }
        .navigationDestination(for: WorkLocation.self) { location in
            WorkLocationDetailView(
                location: location,
                organizations: organizations,
                clients: clients,
                projects: projects,
                tasks: tasks,
                onAdd: { kind, parent in openEditor(kind: kind, parent: parent) },
                onEdit: { kind, id in openEditor(kind: kind, entityID: id) },
                onArchive: requestArchive,
                onRestore: { kind, id, name in setArchived(kind: kind, id: id, name: name, archived: false) }
            )
        }
        .sheet(item: $editorRequest) { request in
            WorkEntityEditor(request: request)
                .presentationDetents([.large])
        }
        .confirmationDialog(
            "Archive \(archiveTarget?.name ?? "this item")?",
            isPresented: $showArchiveConfirmation,
            titleVisibility: .visible
        ) {
            Button("Archive", role: .destructive) {
                guard let target = archiveTarget else { return }
                setArchived(kind: target.kind, id: target.entityID, name: target.name, archived: true)
            }
            Button("Cancel", role: .cancel) { archiveTarget = nil }
        } message: {
            Text("Existing time remains in reports. Archiving a parent makes its descendants unavailable for new timers and assignments until it is restored.")
        }
        .alert("Couldn't update work", isPresented: $showOperationError) {
            Button("OK", role: .cancel) { operationError = nil }
        } message: {
            Text(operationError ?? "Try again.")
        }
    }

    @ViewBuilder
    private func organizationRow(_ organization: WorkOrganization, archived: Bool) -> some View {
        let snapshot = try? WorkHierarchy.resolve(parent: .organization(organization.id), in: modelContext)
        NavigationLink(value: WorkLocation.organization(organization.id)) {
            WorkManagedEntityRow(
                title: organization.name,
                subtitle: archived ? "Archived" : "Clients and tasks",
                colorHex: snapshot?.organization?.colorHex ?? organization.colorHex,
                symbolName: snapshot?.organization?.sfSymbolName ?? organization.sfSymbolName ?? "building.2.fill",
                archived: archived
            )
        }
        .accessibilityIdentifier("work.organization.\(organization.id.uuidString)")
        .contextMenu {
            Button("Edit", systemImage: "pencil") {
                openEditor(kind: .organization, entityID: organization.id)
            }
            if archived {
                Button("Restore", systemImage: "arrow.uturn.backward") {
                    setArchived(kind: .organization, id: organization.id, name: organization.name, archived: false)
                }
            } else {
                Button("Archive", systemImage: "archivebox", role: .destructive) {
                    requestArchive(kind: .organization, id: organization.id, name: organization.name)
                }
            }
        }
    }

    @ViewBuilder
    private func taskRow(_ task: ActivityItem) -> some View {
        if let snapshot = try? WorkHierarchy.resolve(task: task, in: modelContext),
           let taskID = task.id {
            Button {
                openEditor(kind: .task, entityID: taskID)
            } label: {
                WorkManagedTaskRow(task: task, snapshot: snapshot)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("work.task.\(taskID.uuidString)")
            .contextMenu {
                Button("Edit", systemImage: "pencil") {
                    openEditor(kind: .task, entityID: taskID)
                }
                if task.archived == true {
                    Button("Restore", systemImage: "arrow.uturn.backward") {
                        setArchived(kind: .task, id: taskID, name: task.name ?? "Task", archived: false)
                    }
                } else {
                    Button("Archive", systemImage: "archivebox", role: .destructive) {
                        requestArchive(kind: .task, id: taskID, name: task.name ?? "Task")
                    }
                }
            }
        }
    }

    private func openEditor(kind: WorkEntityKind, entityID: UUID? = nil, parent: WorkParent? = nil) {
        editorRequest = WorkEditorRequest(kind: kind, entityID: entityID, defaultParent: parent)
    }

    private func requestArchive(kind: WorkEntityKind, id: UUID, name: String) {
        archiveTarget = WorkArchiveTarget(kind: kind, entityID: id, name: name)
        showArchiveConfirmation = true
    }

    private func setArchived(kind: WorkEntityKind, id: UUID, name: String, archived: Bool) {
        Task {
            do {
                try await PersistenceManager.shared.workHierarchyActor
                    .setArchived(kind: kind, id: id, archived: archived)
                archiveTarget = nil
            } catch {
                operationError = error.localizedDescription
                showOperationError = true
            }
        }
    }
}

private struct WorkLocationDetailView: View {
    @Environment(\.modelContext) private var modelContext

    let location: WorkLocation
    let organizations: [WorkOrganization]
    let clients: [WorkClient]
    let projects: [WorkProject]
    let tasks: [ActivityItem]
    let onAdd: (WorkEntityKind, WorkParent?) -> Void
    let onEdit: (WorkEntityKind, UUID) -> Void
    let onArchive: (WorkEntityKind, UUID, String) -> Void
    let onRestore: (WorkEntityKind, UUID, String) -> Void

    private var title: String {
        switch location {
        case .organization(let id): organizations.first(where: { $0.id == id })?.name ?? "Organization"
        case .client(let id): clients.first(where: { $0.id == id })?.name ?? "Client"
        case .project(let id): projects.first(where: { $0.id == id })?.name ?? "Project"
        }
    }

    private var canAddChildren: Bool {
        switch location {
        case .organization(let id):
            return organizations.contains { $0.id == id && !$0.archived }
        case .client(let id):
            guard let client = clients.first(where: { $0.id == id }), !client.archived,
                  let organizationID = client.organizationID else { return false }
            return organizations.contains { $0.id == organizationID && !$0.archived }
        case .project(let id):
            guard let project = projects.first(where: { $0.id == id }), !project.archived,
                  let clientID = project.clientID,
                  let client = clients.first(where: { $0.id == clientID }), !client.archived,
                  let organizationID = client.organizationID else { return false }
            return organizations.contains { $0.id == organizationID && !$0.archived }
        }
    }

    var body: some View {
        List {
            if !canAddChildren {
                Section {
                    Label("Archived location", systemImage: "archivebox")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Restore this item and its parents before adding new work here.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            switch location {
            case .organization(let id):
                clientSection(organizationID: id)
                taskSection(parent: .organization(id))
            case .client(let id):
                projectSection(clientID: id)
                taskSection(parent: .client(id))
            case .project(let id):
                taskSection(parent: .project(id))
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if canAddChildren {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        switch location {
                        case .organization(let id):
                            Button("New Client", systemImage: "person.2") {
                                onAdd(.client, .organization(id))
                            }
                            .accessibilityIdentifier("work.client.add")

                            Button("New Task", systemImage: "checkmark.circle") {
                                onAdd(.task, .organization(id))
                            }
                            .accessibilityIdentifier("task.add")
                        case .client(let id):
                            Button("New Project", systemImage: "folder") {
                                onAdd(.project, .client(id))
                            }
                            .accessibilityIdentifier("work.project.add")

                            Button("New Task", systemImage: "checkmark.circle") {
                                onAdd(.task, .client(id))
                            }
                            .accessibilityIdentifier("task.add")
                        case .project(let id):
                            Button("New Task", systemImage: "checkmark.circle") {
                                onAdd(.task, .project(id))
                            }
                            .accessibilityIdentifier("task.add")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add to \(title)")
                    .accessibilityIdentifier("work.add")
                }
            }
        }
    }

    @ViewBuilder
    private func clientSection(organizationID: UUID) -> some View {
        let children = clients.filter { $0.organizationID == organizationID }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        Section("Clients") {
            if children.isEmpty {
                Text("No clients yet.").foregroundStyle(.secondary)
            } else {
                ForEach(children) { client in
                    entityRow(kind: .client, id: client.id, name: client.name,
                              parent: .client(client.id), archived: client.archived,
                              route: .client(client.id))
                }
            }
        }
    }

    @ViewBuilder
    private func projectSection(clientID: UUID) -> some View {
        let children = projects.filter { $0.clientID == clientID }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        Section("Projects") {
            if children.isEmpty {
                Text("No projects yet.").foregroundStyle(.secondary)
            } else {
                ForEach(children) { project in
                    entityRow(kind: .project, id: project.id, name: project.name,
                              parent: .project(project.id), archived: project.archived,
                              route: .project(project.id))
                }
            }
        }
    }

    @ViewBuilder
    private func taskSection(parent: WorkParent) -> some View {
        let children = tasks.filter { $0.workParent == parent }
            .sorted { ($0.name ?? "").localizedStandardCompare($1.name ?? "") == .orderedAscending }
        Section("Tasks") {
            if children.isEmpty {
                Text("No tasks yet.").foregroundStyle(.secondary)
            } else {
                ForEach(children) { task in
                    if let snapshot = try? WorkHierarchy.resolve(task: task, in: modelContext),
                       let id = task.id {
                        Button {
                            onEdit(.task, id)
                        } label: {
                            WorkManagedTaskRow(task: task, snapshot: snapshot)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("work.task.\(id.uuidString)")
                        .contextMenu {
                            Button("Edit", systemImage: "pencil") { onEdit(.task, id) }
                            taskArchiveAction(task, id: id)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func entityRow(kind: WorkEntityKind, id: UUID, name: String,
                           parent: WorkParent, archived: Bool,
                           route: WorkLocation) -> some View {
        let snapshot = try? WorkHierarchy.resolve(parent: parent, in: modelContext)
        NavigationLink(value: route) {
            WorkManagedEntityRow(
                title: name,
                subtitle: archived ? "Archived" : childDescription(for: kind),
                colorHex: node(for: kind, snapshot: snapshot)?.colorHex,
                symbolName: node(for: kind, snapshot: snapshot)?.sfSymbolName ?? "folder.fill",
                archived: archived
            )
        }
        .accessibilityIdentifier("work.\(kind.rawValue).\(id.uuidString)")
        .contextMenu {
            Button("Edit", systemImage: "pencil") { onEdit(kind, id) }
            if archived {
                Button("Restore", systemImage: "arrow.uturn.backward") {
                    onRestore(kind, id, name)
                }
            } else {
                Button("Archive", systemImage: "archivebox", role: .destructive) {
                    onArchive(kind, id, name)
                }
            }
        }
    }

    @ViewBuilder
    private func taskArchiveAction(_ task: ActivityItem, id: UUID) -> some View {
        if task.archived == true {
            Button("Restore", systemImage: "arrow.uturn.backward") {
                onRestore(.task, id, task.name ?? "Task")
            }
        } else {
            Button("Archive", systemImage: "archivebox", role: .destructive) {
                onArchive(.task, id, task.name ?? "Task")
            }
        }
    }

    private func node(for kind: WorkEntityKind, snapshot: WorkSnapshot?) -> WorkNodeSnapshot? {
        switch kind {
        case .organization: snapshot?.organization
        case .client: snapshot?.client
        case .project: snapshot?.project
        case .task: snapshot?.task
        }
    }

    private func childDescription(for kind: WorkEntityKind) -> String {
        switch kind {
        case .organization: "Clients and tasks"
        case .client: "Projects and tasks"
        case .project: "Tasks"
        case .task: ""
        }
    }
}

private struct WorkManagedEntityRow: View {
    let title: String
    let subtitle: String
    let colorHex: String?
    let symbolName: String
    let archived: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color(hex: colorHex ?? WorkHierarchy.defaultColorHex).opacity(0.18))
                Image(systemName: symbolName)
                    .foregroundStyle(Color(hex: colorHex ?? WorkHierarchy.defaultColorHex))
            }
            .frame(width: 38, height: 38)

            VStack(alignment: .leading, spacing: 3) {
                Text(title).fontWeight(.medium)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if archived {
                Image(systemName: "archivebox")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Archived")
            }
        }
        .contentShape(Rectangle())
    }
}

private struct WorkManagedTaskRow: View {
    let task: ActivityItem
    let snapshot: WorkSnapshot

    private var path: String {
        [snapshot.organization?.name, snapshot.client?.name, snapshot.project?.name]
            .compactMap { $0 }
            .joined(separator: " › ")
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color(hex: snapshot.task?.colorHex ?? WorkHierarchy.defaultColorHex).opacity(0.18))
                Image(systemName: snapshot.task?.sfSymbolName ?? WorkHierarchy.defaultSymbolName)
                    .foregroundStyle(Color(hex: snapshot.task?.colorHex ?? WorkHierarchy.defaultColorHex))
            }
            .frame(width: 38, height: 38)

            VStack(alignment: .leading, spacing: 3) {
                Text(task.name ?? "Unknown task").fontWeight(.medium)
                if !path.isEmpty {
                    Text(path).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            if task.archived == true {
                Image(systemName: "archivebox")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Archived")
            }
        }
        .contentShape(Rectangle())
    }
}
