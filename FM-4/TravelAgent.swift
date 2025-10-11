//
//----------------------------------------------
// Original project: FM-4
// by  Stewart Lynch on 2025-09-03
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

struct TravelAgent: View {
    private let manager = FoundationManager()
    @State private var question: String = ""
    @Environment(\.scenePhase) var scenePhase
    private let instructions = Instructions {
        "You work in a Tourist Information Center."
        "You are very polite."
        "Create concise answers to the questions and keep answers to a single paragraph."
        "Base your answers on what the normal tourist would like to hear."
        "Each paragraph should contain no more than 2 sentences and be fewer than 25 words in total."
    }
    @State private var session: LanguageModelSession
    @State private var errorString: String?
    @State private var scrollPosition = ScrollPosition()
    init() {
        session = LanguageModelSession(instructions: instructions)
    }
    var body: some View {
        NavigationStack{
            if manager.isModelAvailable {
                VStack {
                    if session.transcript.count > 1 {
                        ScrollView {
                            ForEach(session.transcript) { entry in
                                if let interaction = getInteraction(for: entry) {
                                    HStack {
                                        if interaction.isAgent {
                                            Spacer(minLength: 50)
                                            interaction
                                        } else {
                                            interaction
                                            Spacer(minLength: 50)
                                        }
                                    }
                                }
                            }
                            if session.isResponding {
                                HStack {
                                    Spacer(minLength: 50)
                                    ThinkingBubble()
                                }
                            }
                        }
                        .scrollPosition($scrollPosition)
                    } else {
                        ContentUnavailableView("How can I help?", systemImage: "questionmark.message", description: Text("I am your friendly Tourist Infomation Guide"))
                    }
                    TextField("Ask away ...", text: $question)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            if !question.isEmpty {
                                sendQuestion()
                                question = ""
                            }
                        }
                }
                .padding()
                .navigationTitle("Travel Agent")
                .toolbar {
                    Button("New Chat") {
                        session = LanguageModelSession(instructions: instructions)
                    }
                    .disabled(session.transcript.count <= 1 || session.isResponding)
                }
                .alert("Prompt Error", isPresented: .constant(errorString != nil)) {
                    Button("OK") {
                        errorString = nil
                    }
                } message: {
                    if let errorString {
                        Text(errorString)
                    }
                }

            } else {
                IntelligenceUnavailableView()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                manager.checkIsAvailable()
            }
        }
    }
    
    func sendQuestion() {
        let prompt = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }
        let stream = session.streamResponse(to: prompt)
        Task {
            do {
                for try await partialResponse in stream {
                    _ = partialResponse.content
                    withAnimation {
                        scrollPosition.scrollTo(edge: .bottom)
                    }
                }
            } catch let error as LanguageModelSession.GenerationError {
                switch error {
                case .guardrailViolation(let context):
                    errorString = "Guardrail Violation: \(context.debugDescription)"
                case .decodingFailure(let context):
                    errorString = "Decoding Failure: \(context.debugDescription)"
                case .rateLimited(let context):
                    errorString = "Rate Limit exceeded: \(context.debugDescription)"
                default:
                    errorString = "Other error: \(error.localizedDescription)"
                }
                if let failureReason = error.failureReason {
                    errorString! += "\n\(failureReason)"
                }
                if let recoverySuggestion = error.recoverySuggestion {
                    errorString! += "\n\(recoverySuggestion)"
                }
            
            } catch {
                errorString = error.localizedDescription
            }
        }
    }
    
    func getInteraction(for entry: Transcript.Entry) -> ChatBubble? {
        switch entry {
        case .prompt(let prompt):
            ChatBubble(text: prompt.segments[0].description, isAgent: false)
        case .response(let response):
            ChatBubble(text: response.segments[0].description, isAgent: true)
        default:
            nil
        }
    }
}

#Preview {
    TravelAgent()
}

struct ChatBubble: View {
    let text: String
    let isAgent: Bool
    var body: some View {
        Text(text)
            .foregroundStyle(isAgent ? .primary : Color.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isAgent ? Color(.systemGray5) : .blue)
            .clipShape(.rect(cornerRadius: 16))
            .frame(maxWidth: .infinity, alignment: isAgent ? .trailing : .leading)
    }
}

struct ThinkingBubble: View {
    var body: some View {
        Image(systemName: "ellipsis")
            .symbolEffect(.variableColor)
            .imageScale(.large)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray5))
            .clipShape(.rect(cornerRadius: 16))
            .frame(maxWidth: .infinity, alignment:  .trailing)
    }
}
