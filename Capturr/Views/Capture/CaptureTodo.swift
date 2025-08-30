//
//  CaptureTodo.swift
//  Capturr
//
//  Created by Paul Griffiths on 6/8/25.
//

import SwiftUI
import SwiftData

struct CaptureTodo: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @State private var todos: [String] = [""]
    @FocusState private var focusedIndex: Int?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            List {
                ForEach(todos.indices, id: \.self) { index in
                    HStack {
                        Image(systemName: "circle")
                            .foregroundStyle(.secondary)
                        TextField("New To-Do", text: $todos[index])
                            .focused($focusedIndex, equals: index)
                            .submitLabel(.next)
                            .onSubmit {
                                if index < todos.count - 1 {
                                    focusedIndex = index + 1
                                } else {
                                    todos.append("")
                                    focusedIndex = todos.count - 1
                                }
                            }
                            .onChange(of: todos[index]) {
                                if index == todos.count - 1 && !todos[index].isEmpty {
                                    todos.append("")
                                }
                            }
                    }
                }
            }
            .listStyle(.plain)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    focusedIndex = 0
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
        .navigationTitle("New To-Dos")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func submit() {
        let nonEmptyTodos = todos
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !nonEmptyTodos.isEmpty else { return }

        for todo in nonEmptyTodos {
            let item = OutboxItem(content: todo, type: .todo)
            modelContext.insert(item)
        }
        try? modelContext.save()
        dismiss()
    }
    
}

#Preview {
    NavigationStack {
        CaptureTodo()
    }
}
