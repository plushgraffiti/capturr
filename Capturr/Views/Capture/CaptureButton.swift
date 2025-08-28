//
//  CaptureButton.swift
//  Capturr
//
//  Created by Paul Griffiths on 8/8/25.
//

import SwiftUI

struct CaptureButton<Destination: View>: View {
    let destination: Destination
    var label: String
    var icon: String
    
    var body: some View {
        HStack {
            NavigationLink{
                destination
            } label: {
                HStack {
                    VStack {
                        Text(label)
                            .font(.system(.title3, weight: .medium))
                            .foregroundStyle(.primary)
                            .padding(.bottom, 30)
                        Image(systemName: icon)
                            .imageScale(.large)
                            .font(.system(size: 26, weight: .regular, design: .default))
                            .foregroundStyle(.blue)
                    }
                    .padding(10)
                    Spacer()
                }
                .padding()
                .frame(maxWidth: 500)
                .clipped()
                .background {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color(.quaternarySystemFill))
                }
                .padding(5)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
}

#Preview {
    CaptureButton(
        destination: CaptureWrite(),
        label: "Write",
        icon: "pencil"
    )
}
