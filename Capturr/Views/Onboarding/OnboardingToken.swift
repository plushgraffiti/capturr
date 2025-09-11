//
//  OnboardingToken.swift
//  Capturr
//
//  Created by Paul Griffiths on 3/9/25.
//

import SwiftUI

struct OnboardingToken: View {
    @Environment(\.modelContext) private var context
    @ObservedObject var viewModel: ProfileViewModel
    let onNext: () -> Void

    private var isApiTokenValid: Bool {
        !(viewModel.apiToken?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }
    
    var body: some View {
        VStack(spacing: 24) {

            VStack(spacing: 16) {
                
                ZStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 80, height: 80)
                    Image(systemName: "key")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.white)
                        .offset(x: 1, y: -1)
                }
                .padding(.top)

                Text("Setup: API Token")
                    .font(.title2)
                    .bold()
                    .multilineTextAlignment(.center)

                Text("We need an API token to connect and send notes to your Roam Research graph.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                HStack(spacing: 12) {
                    TextField("Not set", text: Binding(
                        get: { viewModel.apiToken ?? "" },
                        set: { viewModel.apiToken = $0 }
                    ))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .keyboardType(.asciiCapable)
                    .submitLabel(.done)
                    .onChange(of: viewModel.apiToken, initial: false) { _, _ in
                        try? viewModel.saveChanges(context: context)
                    }
                }
                .padding()
                
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text("You can generate a new API Token in Roam Research via Settings > Graph. When asked for Access Scope, select append-only.\n\n**Tip:** For easy copy/paste, copy the API Token from your Mac and the clipboard should be shared with your iPhone. Tap and hold in the field above and select Paste.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .padding(.horizontal)
            
            Spacer()
            
            Button {
                try? viewModel.saveChanges(context: context)
                onNext()
            } label: {
                Text("Next")
                    .frame(maxWidth: .infinity)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .padding(8)
            }
            .buttonStyle(.borderedProminent)
            .mask { RoundedRectangle(cornerRadius: 16, style: .continuous) }
            .disabled(!isApiTokenValid)
            .padding(.bottom, 60)
            
        }
        .padding()
        .background(Color(.secondarySystemBackground))
    }
}

#Preview {
    OnboardingToken(viewModel: ProfileViewModel(), onNext: { })
}
