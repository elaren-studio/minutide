//
//  TimerRunningView.swift
//  Pattrn
//
//  Created by Liam Wittig on 07.12.25.
//

import SwiftUI

struct TimerRunningView: View {
    var body: some View {
        if let activity = DtoManager.shared.activityDTO {
            NavigationView {
                VStack(spacing: 40) {
                    Text(activity.startTime, style: .timer)
                        .font(.system(size: 80, weight: .light, design: .monospaced))
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier("timer.running.elapsed")

                    Button(action: {
                        Task {
                            await RunningManager.shared.stopActivity()
                        }
                    }) {
                        Text("Stop")
                            .font(.title2.bold())
                            .frame(maxWidth: 130, minHeight: 60)
                            .cornerRadius(40)
                            .padding(.horizontal)
                            .glassEffect()
                    }
                    .accessibilityLabel("Stop \(activity.name)")
                    .accessibilityIdentifier("timer.running.stop")
                }
                .navigationTitle(activity.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text(activity.name)
                            .font(.headline)
                            .accessibilityIdentifier("timer.running.name")
                    }
                }
            }
        } else {
            Text("Awaiting activityDTO")
        }
    }
}

#Preview {
    TimerRunningView()
}
