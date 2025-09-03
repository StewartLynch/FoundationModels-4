//
//----------------------------------------------
// Original project: FM - 2
// by  Stewart Lynch on 2025-09-02
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

/*
 let session = LanguageModelSession()
 let stream = session.streamResponse(
     to: "Repeat 'This is a test' for 5 times",
 )

 for try await partial in stream {
     print(partial)
 }
 
 */

import SwiftUI
import FoundationModels

struct QA: Identifiable {
    var question: String
    var answer: String = ""
    let id = UUID()
}

struct MyChat: View {
    @Environment(FoundationManager.self) var manager
    @Environment(\.scenePhase) private var scenePhase
    private let instructions = Instructions {
        "You work in a Tourist Information Center."
        "You are very polite"
        "Create concise answers to the questions and keep the answer to a single paragraph"
        "Base your answers on what the normal tourist would like to hear"
        "Each paragraph should contain no more than 2 sentences and be fewer than 25 words in total."
    }
    @State private var session:LanguageModelSession
    @State private var question = ""
    @State private var conversation: [QA] = []
    @State private var scrollPosition = ScrollPosition()
    @State private var scrollViewWidth: CGFloat = 0
    init() {
        self.session = LanguageModelSession(instructions: instructions)
    }
    var body: some View {
        VStack(spacing: 8) {
            // Chat transcript
            if manager.isModelAvailable {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(conversation) { convo in
                                // User question - left, gray bubble
                                HStack {
                                    ChatBubble(text: convo.question, isIncoming: true, width: scrollViewWidth * 0.7)
                                    Spacer(minLength: 40)
                                }
                                // Model answer - right, green bubble
                                HStack {
                                    Spacer(minLength: 40)
                                    ChatBubble(text: convo.answer.isEmpty ? "   " : convo.answer, isIncoming: false, width: scrollViewWidth * 0.7)
                                        .overlay(alignment: .trailing) {
                                            if session.isResponding {
                                                Image(systemName: "ellipsis")
                                                    .symbolEffect(.variableColor)
                                                    .font(.title)
                                                    .foregroundStyle(.white)
                                                    .offset(x: -5)
                                            }
                                        }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .background(
                        GeometryReader { proxy in
                            Color.clear
                                .onAppear {
                                    scrollViewWidth = proxy.size.width
                                }
                                .onChange(of: proxy.size.width) { _, newWidth in
                                    scrollViewWidth = newWidth
                                }
                        }
                    )
                    .scrollPosition($scrollPosition)
                    .defaultScrollAnchor(.top)
                }
            } else {
                IntelligenceUnavailableView()
            }
            
            // Composer
            HStack {
                TextField("What is your question", text: $question, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .disabled(!manager.isModelAvailable || session.isResponding)
                    .onSubmit(sendQuestion)
                    .submitLabel(.send)
                Button {
                    sendQuestion()
                } label: {
                    Image(systemName: "paperplane.fill")
                }
                .buttonStyle(.glassProminent)
                .disabled(question.isEmpty || session.isResponding)
                Button {
                    conversation.removeAll()
                    session = LanguageModelSession(instructions: instructions)
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .padding(.horizontal)
                .buttonStyle(.glass)
                .disabled( session.isResponding || conversation.isEmpty)
            }
            .padding()
        }
        .padding(.top)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                manager.checkIsAvailable()
                print("Model is available:", manager.isModelAvailable)
            }
        }
    }
    
    
    private func sendQuestion() {
        guard manager.checkIsAvailable() else { return }
        let trimmedQuestion = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuestion.isEmpty else { return }
        
        // Append the user's question immediately
        let newQA = QA(question: trimmedQuestion, answer: "")
        conversation.append(newQA)
        let index = conversation.count - 1
        withAnimation {
            scrollPosition.scrollTo(edge: .bottom)
        }
        question = ""
        Task {
            let prompt = Prompt(trimmedQuestion)
            do {
                let answer = try await session.respond(to: prompt).content
                if conversation.indices.contains(index) {
                    conversation[index].answer = answer
                    scrollPosition.scrollTo(edge: .bottom)
                }
            } catch {
                if conversation.indices.contains(index) {
                    conversation[index].answer = error.localizedDescription
                }
            }
            withAnimation {
                scrollPosition.scrollTo(edge: .bottom)
            }
        }
    }
}

private struct ChatBubble: View {
    let text: String
    let isIncoming: Bool
    let width : CGFloat
    
    var body: some View {
        Text(text)
            .foregroundStyle(isIncoming ? .primary : Color.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isIncoming ? Color(.systemGray5) : .green)
            .clipShape(.rect(cornerRadius: 16))
            .frame(maxWidth: width, alignment: isIncoming ? .leading : .trailing)
            .accessibilityLabel(isIncoming ? "Question" : "Answer")
    }
}

#Preview {
    NavigationStack {
        MyChat()
            .environment(FoundationManager())
    }
}

