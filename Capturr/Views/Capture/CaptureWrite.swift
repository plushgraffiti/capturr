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
                .background(Color(.secondarySystemBackground))
                .frame(maxHeight: .infinity)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isFocused = true
                    }
                }

            Button(action: submit) {
                Text("Send to Graph")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding()
            }
        }
        .navigationTitle("New Note")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isFocused = false
                }
            }
        }
    }

    private func submit() {
        let manager = SyncManager(modelContext: modelContext)
        manager.captureNote(text)
        let worker = SyncWorker(modelContext: modelContext)
        worker.syncPendingItems()
        dismiss()
    }
}

#Preview {
    CaptureWrite()
}
