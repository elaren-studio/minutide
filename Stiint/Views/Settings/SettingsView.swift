//
//  SettingsView.swift
//  Stiint
//
//  Created by Wittig, Liam on 15.12.25.
//

import SwiftData
import SwiftUI

struct SettingsView: View {
    @State private var showInstructions = false
    @State private var showAcknowledgement = false

    @Query(sort: \ActivityLog.startTime, order: .reverse) private var logs: [ActivityLog]
    @AppStorage("pauseTracking") private var pauseTracking: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Minutide")
                            .font(.headline)
                        Text("All features are free. No account, subscription, or purchase is required.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    Toggle("Pause Tracking", isOn: $pauseTracking)
                        .onChange(of: pauseTracking) { _, newValue in
                            if newValue {
                                Task {
                                    await RunningManager.shared.stopActivity()
                                }
                            }
                        }
                }

                Section("Help") {
                    Button("Tutorial") {
                        SetupManager.shared.resetSetup()
                    }
                    Button("How to Create an Automation") {
                        showInstructions = true
                    }
                }

                Section("Data Export") {
                    NavigationLink("Export") {
                        RawDataView(logs: logs)
                    }
                }

                Section {
                    Text("An independent community fork of Stiint, originally created by Liam Wittig and released under the MIT License.")
                        .font(.subheadline)
                    Link(
                        "Original Stiint Source",
                        destination: URL(string: "https://github.com/Liam1506/Stiint")!
                    )
                    Button("Acknowledgements & Licenses") {
                        showAcknowledgement = true
                    }
                } header: {
                    Text("About")
                } footer: {
                    Text("This fork is separate from the original Stiint app and its subscriptions.")
                }
            }
            .navigationTitle("Settings")
        }
        .sheet(isPresented: $showInstructions) {
            InstructionView()
        }
        .sheet(isPresented: $showAcknowledgement) {
            AcknowledgementsView()
        }
    }
}

#Preview {
    SettingsView()
}
