//
//  CreateLog.swift
//  Stiint
//
//  Created by Liam Wittig on 13.01.26.
//

import SwiftUI
import SwiftData

struct CreateLogView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("work.organizationScope") private var organizationScope = "all"
    @Environment(\.dismiss) private var dismiss
    @State private var saving = false
    @State private var saveError: String?

    
    @State private var defaultDate: Date
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var maxEndtime: Date
    
    
    @State private var activity: ActivityItem?
    
    
    
    @Query private var activities: [ActivityItem]
    @Query private var organizations: [WorkOrganization]
    @Query private var clients: [WorkClient]
    @Query private var projects: [WorkProject]

    private var availableTasks: [ActivityItem] {
        // Querying the graph also invalidates this list after hierarchy edits.
        _ = organizations.count + clients.count + projects.count
        let scope = WorkScope(rawValue: organizationScope)
        return activities.filter { task in
            guard let snapshot = try? WorkHierarchy.resolve(task: task, in: modelContext,
                                                            requireAvailable: true) else { return false }
            return scope.matches(task: task, snapshot: snapshot)
        }.sorted { ($0.name ?? "").localizedStandardCompare($1.name ?? "") == .orderedAscending }
    }

    private func taskLabel(_ task: ActivityItem) -> String {
        guard let snapshot = try? WorkHierarchy.resolve(task: task, in: modelContext) else {
            return task.name ?? "Unnamed task"
        }
        let path = [snapshot.organization?.name, snapshot.client?.name, snapshot.project?.name]
            .compactMap { $0 }.joined(separator: " / ")
        return path.isEmpty ? task.name ?? "Unnamed task" : "\(task.name ?? "Unnamed task") — \(path)"
    }
    
    
   
    
    init(defaultDate: Date){
        
        let calendar = Calendar.current
        
        self.defaultDate = defaultDate
        let endOfDate = calendar.date(
            byAdding: .day,
            value: 1,
            to: calendar.startOfDay(for: defaultDate)
        )!
        
        
        
        if endOfDate < Date.now{
            maxEndtime = endOfDate
            endTime = endOfDate.addingTimeInterval(-3600 * 10)
            startTime = endOfDate.addingTimeInterval(-3600 * 11)
            return
        }
        

        if let time = DtoManager.shared.activityDTO?.startTime {
            
            if(time > calendar.startOfDay(for: Date.now)){
                self.defaultDate = time
            }
            maxEndtime = time
            endTime = time
            startTime = time.addingTimeInterval(-3600)
            return
            
        }
        maxEndtime = Date.now
        endTime = Date.now
        startTime = Date.now.addingTimeInterval(-3600)
        
    }
    
    func calcBounds(){

        let calendar = Calendar.current
        
        let endOfDate = calendar.date(
            byAdding: .day,
            value: 1,
            to: calendar.startOfDay(for: defaultDate)
        )!
        
        
        
        if endOfDate < Date.now{
            
            maxEndtime = endOfDate
            endTime = endOfDate.addingTimeInterval(-3600 * 10)
            startTime = endOfDate.addingTimeInterval(-3600 * 11)
            return
        }
        

        if let time = DtoManager.shared.activityDTO?.startTime {
            if(time > calendar.startOfDay(for: Date.now)){
                defaultDate = time
            }
            maxEndtime = time
    
            endTime = time
            startTime = time.addingTimeInterval(-3600)
            
            
        }else{
            maxEndtime = Date.now
            
            endTime = Date.now
            startTime = Date.now.addingTimeInterval(-3600)
        }

    }
    
    var body: some View {
        NavigationStack {
            Form {
                
                Section("Task") {
                    Picker("Task", selection: $activity) {
                        Text("Choose a task").tag(Optional<ActivityItem>.none)
                        ForEach(availableTasks) { activity in
                            Text(taskLabel(activity))
                                .tag(activity as ActivityItem?)
                        }
                    }
                    if availableTasks.isEmpty {
                        Text("Create a task in the Tasks tab, or switch to All Work to use a task from another organization.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }
                Section("Time"){
                    
                    DatePicker(
                        "Date",
                        selection: $defaultDate,
                        in: ...maxEndtime,
                        displayedComponents: .date
                    ) .onChange(of: defaultDate) { old, newValue in
                        calcBounds()
                    }
                    DatePicker(
                        "Start Time",
                        selection: $startTime,
                        in: ...endTime,
                        displayedComponents: .hourAndMinute
                    )
                    
                    DatePicker(
                        "End Time",
                        selection: $endTime,
                        in: startTime...maxEndtime,
                        displayedComponents: .hourAndMinute
                    )
                    
                }
                Section("Duration") {
                    let duration = Duration.seconds(
                        endTime.timeIntervalSince(startTime)
                    )
                    Text(
                        duration,
                        format: .units(allowed: [.hours, .minutes])
                    )
                }
            }.disabled(saving).onAppear(){
                activity = availableTasks.first
            }        .navigationTitle("Create Log")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        
                        Button("Create") {
                            
                            guard endTime > startTime else {
                                return
                            }
                            
                            guard activity != nil else {
                                return
                            }
                            
                            saveLog()
                        }
                        .disabled(saving || activity?.id == nil || activity?.archived == true || endTime <= startTime)
                    }
                }
                .interactiveDismissDisabled(saving)
                .alert("Unable to create log", isPresented: Binding(
                    get: { saveError != nil }, set: { if !$0 { saveError = nil } }
                )) {
                    Button("OK") { saveError = nil }
                } message: { Text(saveError ?? "") }
        }
    }

    private func saveLog() {
        guard !saving, let activityId = activity?.id else { return }
        saving = true
        let start = startTime
        let end = endTime
        Task {
            defer { saving = false }
            do {
                try await PersistenceManager.shared.activityLogActor.saveCompletedLog(
                    activityId: activityId, startTime: start, endTime: end
                )
                dismiss()
            } catch {
                saveError = error.localizedDescription
            }
        }
    }
}

#Preview {
    CreateLogView(defaultDate: Date.now)
}
