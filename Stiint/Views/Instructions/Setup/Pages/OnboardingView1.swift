//
//  OnboardingView1.swift
//  Stiint
//
//  Created by Wittig, Liam on 19.12.25.
//

import SwiftUI

struct OnboardingView1: View {
    @Binding var index: Int

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Illustration or symbol
            Image(.appIcon)
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                .accessibilityLabel("Minutide")

            // Title
            Text("Start Tracking Your Time")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            // Description
            Text("Welcome to Minutide. Track your activities, explore your time in Insights, and create automations with Shortcuts.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            // Continue and explain the community edition.
            VStack(spacing: 16) {
                Button(action: {
                    index += 1
                }) {
                    Text("Let's Start")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                }

                VStack(spacing: 4) {
                    Text("All features are free. No account or subscription required.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    Text("Based on Stiint by Liam Wittig, under the MIT License.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}
