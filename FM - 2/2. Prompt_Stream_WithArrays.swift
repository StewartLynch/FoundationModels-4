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

struct Prompt_Stream_WithArrays: View {
    @Environment(FoundationManager.self) var manager
    @Environment(NavManager.self) var navManager
    @Environment(\.scenePhase) private var scenePhase
    @State private var session = LanguageModelSession()
    @State private var prompt = Prompt {
        "Create a 30 minute stretching routine for me giving 10 minutes to each of the following areas:"
        StretchType.allCases.map { Prompt($0.rawValue)}
    }
    @State private var response = ""
    var body: some View {
        NavigationStack {
            VStack {
                // Prompt Criteria
                
                if manager.isModelAvailable {
                    Button("Get 30 minute routine") {
                        guard manager.checkIsAvailable() else { return }
                        response = ""
                        Task {
                            let stream = session.streamResponse(to: prompt)
                            do {
                                for try await partial in stream {
                                    response = manager.minimizeMarkDown(partial.content)
                                }
                            } catch let error as LanguageModelSession.GenerationError {
                                switch error {
                                case .guardrailViolation(let context):
                                    print("Guardrail violation: \(context.debugDescription)")
                                case .decodingFailure(let context):
                                    print("Decoding failure: \(context.debugDescription)")
                                default:
                                    print("Other error: \(error.localizedDescription)")
                                }
                                if let failureReason = error.failureReason {
                                    print(failureReason)
                                }
                                if let recoverySuggestion = error.recoverySuggestion {
                                    print(recoverySuggestion)
                                }
                            } catch {
                                print(error.localizedDescription)
                            }
                        }
                    }
                    .buttonStyle(.glassProminent)
                    ScrollView{
                        Text(LocalizedStringKey(response))
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
                                //                            Text("Thinking....").font(.largeTitle)
                            }
                        }
                    }
                } else {
                    IntelligenceUnavailableView()
                }
            }
            .padding()
            .navigationTitle(navManager.selectedTab.rawValue)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                manager.checkIsAvailable()
                print("Model is available:", manager.isModelAvailable)
            }
        }
        .onAppear {
            session.prewarm(promptPrefix: prompt)
        }
    }
}

#Preview {
    Prompt_Stream_WithArrays()
        .environment(FoundationManager())
        .environment(NavManager())
}
