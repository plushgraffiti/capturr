//
//  CaptureWrite.swift
//  Capturr
//
//  Created by Paul Griffiths on 6/8/25.
//

import SwiftUI
import SwiftData

struct CaptureWrite: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    
    @State private var text: String = ""
    @FocusState private var isFocused: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            TextEditor(text: $text)
                .focused($isFocused)
                .padding()
                .scrollContentBackground(.hidden)
                .scrollDismissesKeyboard(.interactively)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .contentMargins(.bottom, 96, for: .scrollContent)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isFocused = true
                    }
                }
        }
        .background(Color(.systemBackground))
        .navigationTitle("New Note")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button(action: submit) {
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

    private func submit() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let item = OutboxItem(content: trimmed, type: .note)
        modelContext.insert(item)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    CaptureWrite()
}
