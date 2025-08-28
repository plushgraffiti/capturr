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
                
                HStack {
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
                }
                
                HStack {
                    CaptureButton(
                        destination: CaptureVoice(),
                        label: "Voice",
                        icon: "waveform"
                    )
                    
                }
                
            }.padding(20)
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
