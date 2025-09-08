//
//----------------------------------------------
// Original project: FM - 2
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

struct Interaction {
    var text: String
    var bot: Bool
}

struct MultiTurnSession: View {
    @State private var session:LanguageModelSession
    @State private var question: String = ""
    @Environment(FoundationManager.self) var manager
    @Environment(\.scenePhase) var scenePhase
    private let instructions = Instructions {
        "You work in a Tourist Information Center."
        "You are very polite"
        "Create concise answers to the questions and keep the answer to a single paragraph"
        "Base your answers on what the normal tourist would like to hear"
        "Each paragraph should contain no more than 2 sentences and be fewer than 25 words in total."
    }
    init() {
        session = LanguageModelSession(instructions: instructions)
    }
    @State private var scrollPosition = ScrollPosition()
    @State private var screenWidth: CGFloat = 0
    @State private var badPromptError: String?
    var body: some View {
        VStack {
            if manager.isModelAvailable {
                if session.transcript.count > 1 {
                    ScrollViewReader { proxy in
                        ScrollView {
                            ForEach(session.transcript) { entry in
                                HStack {
                                    if let interaction = getInteraction(for: entry) {
                                        if !interaction.bot {
                                            Spacer(minLength: 40)
                                        }
                                        ChatBubble(text: interaction.text, isBot: interaction.bot, width: screenWidth * 0.8)
                                        if interaction.bot {
                                            Spacer(minLength: 40)
                                        }
                                    }
                                }
                            }
                            if session.transcript.count > 1 && !session.isResponding {
                                Button {
                                    question = ""
                                    session = LanguageModelSession(instructions: instructions)
                                } label: {
                                    Text("New Chat")
                                }
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .padding(.horizontal)
                                .buttonStyle(.glass)
                                .disabled( session.isResponding)
                            }
                        }
                        .scrollPosition($scrollPosition)
                    }
                    .padding()
                } else {
                    ContentUnavailableView("How can I help?", systemImage: "questionmark.message", description: Text("I am your friendly Tourist Infomation Guide"))
                }
                HStack {
                    TextField("Ask away ...", text: $question)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            sendQuestion()
                        }
                }
                .overlay {
                    if session.isResponding {
                        Image(systemName: "ellipsis")
                            .symbolEffect(.variableColor)
                            .font(.title)
                    }
                }
            } else {
                IntelligenceUnavailableView()
            }
        }
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        screenWidth = proxy.size.width
                        print("width:", screenWidth)
                    }
                    .onChange(of: proxy.size.width) { _, newWidth in
                        screenWidth = newWidth
                    }
            }
        )
        .padding()
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                manager.checkIsAvailable()
                print("Model is available:", manager.isModelAvailable)
            }
        }
        .alert("Bad Prompt",
               isPresented: .constant(badPromptError != nil),
                       actions: {
                           Button("OK", role: .cancel) { }
                       },
                       message: {
                           Text(badPromptError ?? "")
                       }
                )
    }
    private func sendQuestion() {
        let trimmedQuestion = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuestion.isEmpty else { return }
        question = ""
        Task {
            let prompt = Prompt(trimmedQuestion)
            // Do not need the response as we are just looking at the transcript
            let stream = session.streamResponse(to: prompt)
            do {
                for try await partial in stream {
                    _ = manager.minimizeMarkDown(partial.content)
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
            withAnimation {
                scrollPosition.scrollTo(edge: .bottom)
            }
        }
    }
    private func getInteraction(for entry: Transcript.Entry) -> Interaction? {
        switch entry {
        case .prompt(let prompt):
            return Interaction(text: prompt.segments[0].description, bot: false)
        case .response(let response):
            return Interaction(text: (response.segments[0].description), bot: true)
        default:
            return nil
//        case .instructions(let instructions):
//            return "Instructions: \(instructions.segments[0].description)"
//        case .toolCalls(let call):
//            return "Tool Call: \(call.description)"
//        case .toolOutput(let output):
//            return "Tool Output: \(output.description)"
//        @unknown default:
//            return "Unknown entry type"
        }
    }
    
    private func getString(for entry: Transcript.Entry) -> String {
        switch entry {
        case .prompt(let prompt):
            return "You: \(prompt.description)"
        case .response(let response):
            return "AI: \(response.description)"
        default:
            return ""
//        case .instructions(let instructions):
//            return "Instructions: \(instructions.segments[0].description)"
//        case .toolCalls(let call):
//            return "Tool Call: \(call.description)"
//        case .toolOutput(let output):
//            return "Tool Output: \(output.description)"
//        @unknown default:
//            return "Unknown entry type"
        }
    }
}

#Preview {
    MultiTurnSession()
        .environment(FoundationManager())
}

private struct ChatBubble: View {
    let text: String
    let isBot: Bool
    let width : CGFloat
    
    var body: some View {
        Text(text)
            .foregroundStyle(isBot ? .primary : Color.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isBot ? Color(.systemGray5) : .green)
            .clipShape(.rect(cornerRadius: 16))
            .frame(maxWidth: width, alignment: isBot ? .leading : .trailing)
    }
}
