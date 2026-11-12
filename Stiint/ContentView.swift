//
//  ContentView.swift
//  Stiint
//
//  Created by Liam Wittig on 10.12.25.
//

import SwiftUI

private enum AppTab: Hashable {
    case myDay, tasks, reports, settings
}

struct ContentView: View {
    @AppStorage("pauseTracking") private var pauseTracking: Bool = false
    @State private var selectedTab: AppTab = .myDay
    @State private var showTimerPicker = false
    @State private var todayRequest = UUID()
    
    var todayCalendarIcon: String {
        let day = Calendar.current.component(.day, from: Date())
        return "\(day).calendar"
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("My Day", systemImage: todayCalendarIcon, value: AppTab.myDay) {
                if pauseTracking {
                    TrackingPausedView()
                } else {
                    HomeView(todayRequest: todayRequest)
                }
            }

            Tab("Tasks", systemImage: "timer", value: AppTab.tasks) {
                if pauseTracking {
                    TrackingPausedView()
                } else {
                    TimerView()
                }
            }

            Tab("Reports", systemImage: "chart.bar", value: AppTab.reports) {
                AnalyticsView()
            }

            Tab("Settings", systemImage: "gear", value: AppTab.settings) {
                SettingsView()
            }
        }
        .tabViewBottomAccessory(isEnabled: DtoManager.shared.activityDTO != nil || (selectedTab == .myDay && !pauseTracking), content: {
            if DtoManager.shared.activityDTO != nil {
                TimerStatusView(canSwitch: !pauseTracking) {
                    showTimerPicker = true
                }
            } else {
                Button {
                    showTimerPicker = true
                } label: {
                    Label("Start Timer", systemImage: "play.fill")
                        .font(.headline)
                        .foregroundStyle(.tint)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("timeline.timer.start")
            }
        })
        .sheet(isPresented: $showTimerPicker) {
            StartTimerView {
                selectedTab = .myDay
                todayRequest = UUID()
            }
        }
    }
}

#Preview {
    ContentView()
}
