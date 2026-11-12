import SwiftData
import SwiftUI

/// Manual tracking always starts now, even when My Day is showing an older day.
struct StartTimerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("work.organizationScope") private var storedScope = "all"
    @Query(sort: \ActivityItem.name) private var tasks: [ActivityItem]
    @Query(sort: \WorkOrganization.name) private var organizations: [WorkOrganization]
    @Query private var clients: [WorkClient]
    @Query private var projects: [WorkProject]

    var onStarted: () -> Void

    @State private var scope: WorkScope = .allWork
    @State private var didLoadScope = false
    @State private var search = ""
    @State private var newTaskID: UUID?
    @State private var taskEditor: WorkEditorRequest?
    @State private var isStarting = false
    @State private var startError: String?

    private struct Choice: Identifiable {
        let id: UUID
        let snapshot: WorkSnapshot
        var name: String { snapshot.task?.name ?? "Unnamed task" }
        var path: String {
            [snapshot.organization?.name, snapshot.client?.name, snapshot.project?.name]
                .compactMap { $0 }.joined(separator: " › ")
        }
    }

    private var choices: [Choice] {
        _ = organizations.count + clients.count + projects.count
        let normalized = scope.normalized(in: organizations)
        return tasks.compactMap { task in
            guard let id = task.id,
                  let snapshot = try? WorkHierarchy.resolve(task: task, in: modelContext, requireAvailable: true),
                  id == newTaskID || normalized.matches(task: task, snapshot: snapshot) else { return nil }
            let choice = Choice(id: id, snapshot: snapshot)
            guard search.isEmpty || "\(choice.name) \(choice.path)".localizedStandardContains(search) else { return nil }
            return choice
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button("New Task", systemImage: "plus") {
                        taskEditor = WorkEditorRequest(kind: .task,
                            defaultParent: scope.defaultTaskParent(in: organizations))
                    }
                    .accessibilityIdentifier("timer.picker.new")
                }
                Section {
                    if choices.isEmpty {
                        ContentUnavailableView(
                            search.isEmpty ? "No tasks here yet" : "No matching tasks",
                            systemImage: "checkmark.circle",
                            description: Text("Create a task or choose another work scope.")
                        )
                    }
                    ForEach(choices) { choice in
                        let isRunning = DtoManager.shared.activityDTO?.id == choice.id
                        Button {
                            start(choice.id)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: choice.snapshot.task?.sfSymbolName ?? WorkHierarchy.defaultSymbolName)
                                    .font(.title3)
                                    .foregroundStyle(Color(hex: choice.snapshot.task?.colorHex ?? WorkHierarchy.defaultColorHex))
                                    .frame(width: 30)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(choice.name).fontWeight(.semibold)
                                    if !choice.path.isEmpty {
                                        Text(choice.path).font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                Image(systemName: isRunning ? "timer" : "play.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .disabled(isRunning)
                        .accessibilityLabel(isRunning ? "Currently tracking \(choice.name)" : "Start \(choice.name)")
                        .accessibilityHint(choice.path)
                        .accessibilityIdentifier("timer.picker.task.\(choice.id.uuidString)")
                    }
                } footer: {
                    Text(DtoManager.shared.activityDTO == nil
                         ? "Tap a task to start tracking now."
                         : "Starting another task saves the current timer and begins the next one now.")
                }
            }
            .disabled(isStarting)
            .navigationTitle("Start Timer")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $search, prompt: "Find a task")
            .searchPresentationToolbarBehavior(.avoidHidingContent)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isStarting)
                }
                ToolbarItem(placement: .principal) {
                    WorkScopePicker(selection: $scope, organizations: organizations,
                                    identifier: "timer.picker.scope")
                }
            }
            .onAppear {
                guard !didLoadScope else { return }
                didLoadScope = true
                scope = WorkScope(rawValue: storedScope).normalized(in: organizations)
            }
            .sheet(item: $taskEditor) { request in
                WorkEntityEditor(request: request, onTaskCreated: { id in
                    newTaskID = id
                    search = ""
                })
            }
            .alert("Couldn't start timer", isPresented: Binding(
                get: { startError != nil }, set: { if !$0 { startError = nil } }
            )) {
                Button("OK") { startError = nil }
            } message: {
                Text(startError ?? "")
            }
        }
        .interactiveDismissDisabled(isStarting)
    }

    private func start(_ id: UUID) {
        guard !isStarting else { return }
        isStarting = true
        Task {
            await RunningManager.shared.startActivity(activityId: id)
            isStarting = false
            guard DtoManager.shared.activityDTO?.id == id else {
                startError = "This task may no longer be available. Choose another task and try again."
                return
            }
            onStarted()
            dismiss()
        }
    }
}
