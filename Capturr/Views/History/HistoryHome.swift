//
//  HistoryHome.swift
//  Capturr
//
//  Created by Paul Griffiths on 6/8/25.
//

import SwiftUI
import SwiftData

struct HistoryHome: View {
    @Query(sort: \OutboxItem.createdAt, order: .reverse) var items: [OutboxItem]
    @Environment(\.modelContext) private var modelContext
    @State private var expanded: Set<UUID> = []

    private func statusIcon(for item: OutboxItem) -> String {
        switch SyncStatus(rawValue: item.status) {
        case .some(.success): return "checkmark.circle"
        case .some(.pending): return "clock"
        case .some(.inProgress): return "arrow.triangle.2.circlepath"
        case .some(.failed): return "xmark.circle"
        default: return "questionmark.circle"
        }
    }

    private func statusColor(for item: OutboxItem) -> Color {
        switch SyncStatus(rawValue: item.status) {
        case .some(.success): return .green
        case .some(.pending): return .yellow
        case .some(.inProgress): return .blue
        case .some(.failed): return .red
        default: return .gray
        }
    }

    var body: some View {
        NavigationView {
            List(items) { item in
                DisclosureGroup(
                    isExpanded: Binding(
                        get: { expanded.contains(item.id) },
                        set: { isOpen in
                            if isOpen { expanded.insert(item.id) } else { expanded.remove(item.id) }
                        }
                    )
                ) {
                    // Expanded content
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Created:")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(item.createdAt.formatted(.dateTime))
                                .foregroundStyle(.secondary)
                        }
                        HStack {
                            Text("Sync attempts:")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(item.attemptCount)")
                                .foregroundStyle(.secondary)
                        }
                        if let lastTried = item.lastAttemptAt {
                            HStack {
                                Text("Last tried:")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(lastTried.formatted(.dateTime))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        HStack {
                            Text("Synced:")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(item.sentAt?.formatted(.dateTime) ?? "Not synced")
                                .foregroundStyle(.secondary)
                        }
                        
                        
                        if item.lastError?.isEmpty == false {
                            VStack(alignment: .leading) {
                                Text("Last response:")
                                    .foregroundStyle(.secondary)
                                
                                Text(item.lastError ?? "")
                                    .font(.system(.footnote, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                    .padding(8)
                                    .background(Color.gray.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                
                            }
                            .padding(.top, 10)
                        }
                    }
                    .padding(.vertical, 4)
                    .padding(.leading, -16)
                    .font(.subheadline)
                    
                } label: {
                    // Collapsed label
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(item.content)
                            .font(.body)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 8)
                        Image(systemName: statusIcon(for: item))
                            .foregroundStyle(statusColor(for: item))
                            .imageScale(.medium)
                            .accessibilityLabel(SyncStatus(rawValue: item.status)?.description ?? "Unknown")
                    }
                    .contentShape(Rectangle())
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        modelContext.delete(item)
                        try? modelContext.save()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .tint(.red)
                }
                
            }
            .navigationTitle("History")
            .tint(.primary)
        }
    }
}

#Preview {
    HistoryHome()
}
