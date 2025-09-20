//
//  SharingView.swift
//  Sharing
//
//  Created by Paul Griffiths on 20/9/25.
//

import SwiftUI

struct ShareView: View {
    @ObservedObject var model: ShareModel
    let onPost: () -> Void
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    TextEditor(text: $model.text)
                        .font(.body)
                        .textInputAutocapitalization(.sentences)
                        .autocorrectionDisabled(false)
                        .keyboardType(.default)
                        .accessibilityIdentifier("ShareEditor")
                        .focused($focused)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.separator), lineWidth: 0.5))
                        .padding(.horizontal)
                        .scrollContentBackground(.hidden)
                        .scrollDismissesKeyboard(.interactively)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .onAppear { Task { @MainActor in focused = true } }
                }
                .background(Color(.secondarySystemBackground))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .navigationTitle("CAPTURR")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { NotificationCenter.default.post(name: .init("Close"), object: nil) }) {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.plain)
                    .labelStyle(.iconOnly)
                    .accessibilityIdentifier("CancelButton")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: onPost) {
                        Image(systemName: "checkmark")
                    }
                    .buttonStyle(.borderedProminent)
                    .labelStyle(.iconOnly)
                    .accessibilityIdentifier("ConfirmButton")
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: onPost) {
                    Text("Send to Graph")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding()
            }
        }
    }
}

