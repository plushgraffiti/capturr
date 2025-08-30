//
//  CaptureHome.swift
//  Capturr
//
//  Created by Paul Griffiths on 6/8/25.
//

import SwiftUI

struct CaptureHome: View {
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                Spacer()
                
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 4), GridItem(.flexible(), spacing: 4)], alignment: .leading, spacing: 0) {
                    
                    CaptureButton(
                        destination: CaptureWrite(),
                        label: "Write",
                        icon: "list.bullet.rectangle"
                    )
                    
                    CaptureButton(
                        destination: CaptureTodo(),
                        label: "Todo",
                        icon: "checklist"
                    )
                        
                    CaptureButton(
                        destination: CaptureVoice(),
                        label: "Voice",
                        icon: "waveform"
                    )
                        
                }
                .padding(.bottom, 10)
                
                
            }
            .padding(10)
            .navigationTitle("Capture")
        }
    }
}

#Preview {
    let mockViewModel = ProfileViewModel()
    mockViewModel.defaultTag = "#capture"
    return ContentView()
        .environmentObject(mockViewModel)
        .environment(\.locale, .init(identifier: "en"))
        .preferredColorScheme(.dark)
}
