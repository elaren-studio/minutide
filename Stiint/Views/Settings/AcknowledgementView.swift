//
//  AcknowledgementView.swift
//  Stiint
//
//  Created by Wittig, Liam on 22.12.25.
//

import AcknowList
import SwiftUI

struct AcknowledgementsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Minutide") {
                    Text("An independent community fork of Stiint by Liam Wittig. All features are free.")
                    Text("Original software copyright © 2026 Liam Wittig.")
                    NavigationLink("MIT License") {
                        ScrollView {
                            Text(Self.mitLicense)
                                .textSelection(.enabled)
                                .padding()
                        }
                        .navigationTitle("MIT License")
                    }
                }
                Section("Third-party Software") {
                    NavigationLink("Third-party Licenses") {
                        AcknowListSwiftUIView(acknowledgements: Self.thirdPartyAcknowledgements)
                            .navigationTitle("Third-party Licenses")
                    }
                }
            }
            .navigationTitle("Acknowledgements")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }

    private static var thirdPartyAcknowledgements: [Acknow] {
        ["AcknowList", "Sankey", "D3", "D3-Sankey"].map { name in
            let url = Bundle.main.url(forResource: "\(name)-LICENSE", withExtension: "txt")
            let text = url.flatMap { try? String(contentsOf: $0, encoding: .utf8) }
            return Acknow(title: name, text: text ?? "License resource unavailable in this build.")
        }
    }

    // Keep the upstream copyright and permission notice available in the app.
    private static let mitLicense = """
    MIT License

    Copyright (c) 2026 Liam Wittig

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
    """
}

#Preview {
    AcknowledgementsView()
}
