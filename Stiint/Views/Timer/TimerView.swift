import SwiftData
import SwiftUI

private struct TaskPickerItem: Identifiable {
    let id: UUID
    let activity: ActivityItem
    let snapshot: WorkSnapshot
}

private enum TimerSheet: Identifiable {
    case task(WorkEditorRequest)
    case workManagement

    var id: String {
        switch self {
        case .task(let request): "task.\(request.id.uuidString)"
        case .workManagement: "workManagement"
        }
    }
}

struct TimerView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("work.organizationScope") private var workScopeStorage = "all"

    @Query(sort: \ActivityItem.createdDate) private var activities: [ActivityItem]
    @Query(sort: \WorkOrganization.name) private var organizations: [WorkOrganization]

    @State private var activeSheet: TimerSheet?
    @State private var taskToArchive: TaskPickerItem?
    @State private var showArchiveConfirmation = false
    @State private var actionError: String?
    @State private var showActionError = false

    private var currentScope: WorkScope {
        WorkScope(rawValue: workScopeStorage).normalized(in: organizations)
    }

    private var scopeBinding: Binding<WorkScope> {
        Binding(
            get: { WorkScope(rawValue: workScopeStorage) },
            set: { workScopeStorage = $0.rawValue }
        )
    }

    private var runningActivity: ActivityDTO? {
        DtoManager.shared.activityDTO
    }

    private var visibleTasks: [TaskPickerItem] {
        activities.compactMap { activity in
            guard activity.archived != true,
                  let id = activity.id,
                  let snapshot = try? WorkHierarchy.resolve(
                    task: activity,
                    in: modelContext,
                    requireAvailable: true
                  ),
                  currentScope.matches(task: activity, snapshot: snapshot) else { return nil }
            return TaskPickerItem(id: id, activity: activity, snapshot: snapshot)
        }
        .sorted {
            ($0.activity.name ?? "").localizedStandardCompare($1.activity.name ?? "") == .orderedAscending
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let runningActivity {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Now tracking")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        RunningTaskSnapshotCard(activity: runningActivity)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                }

                List {
                    Section(currentScope.title(in: organizations)) {
                        if visibleTasks.isEmpty {
                            ContentUnavailableView(
                                "No tasks here yet",
                                systemImage: "checkmark.circle",
                                description: Text("Add a task or choose another work scope.")
                            )
                        } else {
                            ForEach(visibleTasks) { item in
                                TaskPickerRow(
                                    item: item,
                                    isRunning: runningActivity?.id == item.id,
                                    hasRunningTimer: runningActivity != nil,
                                    start: { start(item) }
                                )
                                .accessibilityIdentifier("activity.start.\(item.id.uuidString)")
                                .contextMenu {
                                    Button("Edit", systemImage: "pencil") {
                                        activeSheet = .task(WorkEditorRequest(kind: .task, entityID: item.id))
                                    }
                                    Button("Archive", systemImage: "archivebox", role: .destructive) {
                                        taskToArchive = item
                                        showArchiveConfirmation = true
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Tasks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    WorkScopePicker(selection: scopeBinding, organizations: organizations)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        activeSheet = .task(WorkEditorRequest(
                            kind: .task,
                            defaultParent: currentScope.defaultTaskParent(in: organizations)
                        ))
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add Task")
                    .accessibilityIdentifier("activity.add")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        activeSheet = .workManagement
                    } label: {
                        Text("Manage")
                    }
                    .accessibilityLabel("Manage Work")
                    .accessibilityIdentifier("work.manage")
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .task(let request):
                    WorkEntityEditor(request: request)
                        .presentationDetents([.large])
                case .workManagement:
                    WorkManagementView()
                        .presentationDetents([.large])
                }
            }
            .confirmationDialog(
                "Archive \(taskToArchive?.activity.name ?? "this task")?",
                isPresented: $showArchiveConfirmation,
                titleVisibility: .visible
            ) {
                Button("Archive", role: .destructive) {
                    guard let item = taskToArchive else { return }
                    setTaskArchived(item, archived: true)
                }
                Button("Cancel", role: .cancel) { taskToArchive = nil }
            } message: {
                Text("The task disappears from new timer lists. Its existing time remains in reports.")
            }
            .alert("Couldn't update task", isPresented: $showActionError) {
                Button("OK", role: .cancel) { actionError = nil }
            } message: {
                Text(actionError ?? "Try again.")
            }
        }
    }

    private func start(_ item: TaskPickerItem) {
        Task {
            await RunningManager.shared.startActivity(activityId: item.id)
        }
    }

    private func setTaskArchived(_ item: TaskPickerItem, archived: Bool) {
        Task {
            do {
                try await PersistenceManager.shared.workHierarchyActor
                    .setArchived(kind: .task, id: item.id, archived: archived)
                taskToArchive = nil
            } catch {
                actionError = error.localizedDescription
                showActionError = true
            }
        }
    }
}

struct RunningTaskSnapshotCard: View {
    let activity: ActivityDTO

    @Query private var openLogs: [ActivityLog]

    init(activity: ActivityDTO) {
        self.activity = activity
        let activityID = activity.id
        let startTime = activity.startTime
        _openLogs = Query(filter: #Predicate<ActivityLog> { log in
            log.endTime == nil
                && log.activity?.id == activityID
                && log.startTime == startTime
        })
    }

    var body: some View {
        RunningTaskCard(activity: activity, snapshot: openLogs.first?.workSnapshot)
    }
}

private struct TaskPickerRow: View {
    let item: TaskPickerItem
    let isRunning: Bool
    let hasRunningTimer: Bool
    let start: () -> Void

    private var name: String { item.activity.name ?? "Unknown task" }

    private var path: String {
        [item.snapshot.organization?.name, item.snapshot.client?.name, item.snapshot.project?.name]
            .compactMap { $0 }
            .joined(separator: " › ")
    }

    var body: some View {
        Button(action: start) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color(hex: item.snapshot.task?.colorHex ?? WorkHierarchy.defaultColorHex))
                        .frame(width: 40, height: 40)
                    Image(systemName: item.snapshot.task?.sfSymbolName ?? WorkHierarchy.defaultSymbolName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(name).fontWeight(.semibold)
                    if !path.isEmpty {
                        Text(path)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 8)
                if isRunning {
                    Label("Tracking", systemImage: "timer")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                } else {
                    Image(systemName: "play.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isRunning)
        .accessibilityLabel(
            isRunning ? "Currently tracking \(name)" :
                hasRunningTimer ? "Switch to \(name)" : "Start \(name)"
        )
        .accessibilityHint(path.isEmpty ? "" : path)
    }
}

private struct RunningTaskCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let activity: ActivityDTO
    let snapshot: WorkSnapshot?

    private var name: String { snapshot?.task?.name ?? activity.name }

    private var path: String {
        [snapshot?.organization?.name, snapshot?.client?.name, snapshot?.project?.name]
            .compactMap { $0 }
            .joined(separator: " › ")
    }

    private var color: Color {
        guard let colorHex = snapshot?.task?.colorHex else { return activity.color }
        return Color(hex: colorHex)
    }

    private var symbolName: String {
        snapshot?.task?.sfSymbolName ?? activity.icon
    }

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 12) {
                        taskIcon
                        taskDetails
                    }
                    stopButton
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            } else {
                HStack(spacing: 12) {
                    taskIcon
                    taskDetails
                    Spacer(minLength: 8)
                    stopButton
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var taskIcon: some View {
        Image(systemName: symbolName)
            .font(.title3)
            .foregroundStyle(color)
            .accessibilityHidden(true)
    }

    private var taskDetails: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.headline)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("timer.running.name")
            if !path.isEmpty {
                Text(path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text(activity.startTime, style: .timer)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("timer.running.elapsed")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var stopButton: some View {
        Button("Stop") {
            Task { await RunningManager.shared.stopActivity() }
        }
        .buttonStyle(.bordered)
        .fixedSize()
        .accessibilityLabel("Stop \(name)")
        .accessibilityIdentifier("timer.running.stop")
    }
}
