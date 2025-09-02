//
//----------------------------------------------
// Original project: FM - 2
// by  Stewart Lynch on 2025-09-01
//
// Follow me on Mastodon: https://iosdev.space/@StewartLynch
// Follow me on Threads: https://www.threads.net/@stewartlynch
// Follow me on Bluesky: https://bsky.app/profile/stewartlynch.bsky.social
// Follow me on X: https://x.com/StewartLynch
// Follow me on LinkedIn: https://linkedin.com/in/StewartLynch
// Email: slynch@createchsol.com
// Subscribe on YouTube: https://youTube.com/@StewartLynch
// Buy me a ko-fi:  https://ko-fi.com/StewartLynch
//----------------------------------------------
// Copyright © 2025 CreaTECH Solutions. All rights reserved.


import SwiftUI
import FoundationModels

struct PromptRequestTemplateView: View {
    @Environment(FoundationManager.self) var manager
    @Environment(\.scenePhase) private var scenePhase
    @State private var session = LanguageModelSession()

    var body: some View {
        VStack {
            // Prompt Criteria
            
            if manager.isModelAvailable {
                Button("Button Label") {
                    guard manager.checkIsAvailable() else { return }
                    manager.response = ""
                    Task {
                        // request response

                    }
                }
                .buttonStyle(.glassProminent)
                ScrollView{
                    Text(LocalizedStringKey(manager.response))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                }
                .scrollBounceBehavior(.basedOnSize)
                .background(.quinary)
                .clipShape(.rect(cornerRadius: 20))
                .overlay {
                    if session.isResponding {
                        VStack {
                            ProgressView()
                            Text("Thinking....").font(.largeTitle)
                        }
                    }
                }
            } else {
                IntelligenceUnavailableView()
            }
        }
        .padding()
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                manager.checkIsAvailable()
                print("Model is available:", manager.isModelAvailable)
            }
        }
    }
}

#Preview {
    PromptRequestTemplateView()
        .environment(FoundationManager())
}
