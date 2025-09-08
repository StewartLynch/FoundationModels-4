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

struct ThePromptBuilder: View {
    // 1
    @Environment(FoundationManager.self) var manager
    @Environment(NavManager.self) var navManager
    @Environment(\.scenePhase) private var scenePhase
    @State private var session = LanguageModelSession()
    @State private var stretchType = StretchType.lback
    @State private var length: Double = 10
    @State private var response = ""
    var body: some View {
        NavigationStack {
            VStack {
                Picker("Stretch Type", selection: $stretchType) {
                    ForEach(StretchType.allCases) { stretch in
                        Text(stretch.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                VStack{
                    Slider(value: $length, in: 5...60) {
                        Text("Length")
                    } ticks: {
                        SliderTickContentForEach(
                            stride(from: 5, through: 60, by: 5).map { $0 },
                            id: \.self
                        ) { value in
                            SliderTick(value)
                        }
                    }
                    Text("Length: \(Text(length, format: .number.precision(.fractionLength(0)))) minutes")
                }
                
                if manager.isModelAvailable {
                    Button("Create Exercise") {
                        guard manager.checkIsAvailable() else { return }
                        response = ""
                        Task {
                            let prompt = Prompt {
                                "Create an stretching exercise for me."
                                "Focus the exercies on \(stretchType.rawValue)"
                                "Have the exerecise last for \(Int(length)) minutes"
                            }
                            do {
                                response = manager.minimizeMarkDown(try await session.respond(to: prompt).content)
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
                                Text("Thinking....").font(.largeTitle)
                            }
                        }
                    }
                } else {
                    IntelligenceUnavailableView()
                }
            }
            .padding()
            .navigationTitle(navManager.selectedTab.rawValue)
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    manager.checkIsAvailable()
                    print("Model is available:", manager.isModelAvailable)
                }
            }
        }
    }
}

#Preview {
    ThePromptBuilder()
        .environment(FoundationManager())
        .environment(NavManager())
}

enum StretchType: String, CaseIterable, Identifiable {
    case lback = "Lower back"
    case uback = "Upper back"
    case neck = "Neck"
    var id: Self { self }
}
