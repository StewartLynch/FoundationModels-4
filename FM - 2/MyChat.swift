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
    @State private var session = LanguageModelSession()
    @State private var question = ""
    @State private var conversation: [QA] = []
    @State private var scrollPosition = ScrollPosition()
    @State private var trimmedQuestion: String = ""
    var body: some View {
        VStack(spacing: 8) {
            // Chat transcript
            if manager.isModelAvailable {
                GeometryReader { geo in
                    let maxBubbleWidth = geo.size.width * 0.7
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(conversation) { convo in
                                    // User question - left, gray bubble
                                    HStack {
                                        ChatBubble(text: convo.question, isIncoming: true, maxWidth: maxBubbleWidth)
                                        Spacer(minLength: 40)
                                    }
                                    // Model answer - right, green bubble
                                    HStack {
                                        Spacer(minLength: 40)
                                        ChatBubble(text: convo.answer.isEmpty ? "…" : convo.answer, isIncoming: false, maxWidth: maxBubbleWidth)
                                    }

                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 18)
                        }
                        .scrollPosition($scrollPosition)
                        .defaultScrollAnchor(.top)
                        .animation(.default, value: scrollPosition)
                        .padding(.bottom)
                        .overlay {
                            if session.isResponding {
                                VStack {
                                    ProgressView()
                                    Text("Thinking....").font(.headline)
                                }
                                .padding()
                                .background(.ultraThinMaterial, in: .rect(cornerRadius: 12))
                            }
                        }
                    }
                }
            } else {
                IntelligenceUnavailableView()
            }
            
            // Composer
            HStack(alignment: .bottom, spacing: 8) {
                TextField("What is your question", text: $question, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .disabled(!manager.isModelAvailable || session.isResponding)
                    .onSubmit(sendQuestion)
            }
            .padding(.horizontal)
            .padding(.bottom)
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
        trimmedQuestion = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuestion.isEmpty else { return }
        
        // Append the user's question immediately
        let newQA = QA(question: trimmedQuestion, answer: "")
        conversation.append(newQA)
        let index = conversation.count - 1
        scrollPosition.scrollTo(edge: .bottom)

        question = ""
        
        Task {
            let prompt = Prompt {
                "Keep answers to a single short paragraph."
                trimmedQuestion
            }
            do {
                let answer = try await session.respond(to: prompt).content
                // Update the answer in place if the index is still valid
                if conversation.indices.contains(index) {
                    conversation[index].answer = answer
                    scrollPosition.scrollTo(edge: .bottom)
                }
            } catch {
                if conversation.indices.contains(index) {
                    conversation[index].answer = error.localizedDescription
                }
            }
            scrollPosition.scrollTo(edge: .bottom)
        }
    }
}

private struct ChatBubble: View {
    let text: String
    let isIncoming: Bool
    let maxWidth: CGFloat
    
    var body: some View {
        Text(text)
            .foregroundStyle(isIncoming ? .primary : Color.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(bubbleBackground)
            .clipShape(bubbleShape)
            .frame(maxWidth: maxWidth, alignment: isIncoming ? .leading : .trailing)
            .accessibilityLabel(isIncoming ? "Question" : "Answer")
    }
    
    private var bubbleBackground: some ShapeStyle {
        isIncoming ? Color(.systemGray5) : Color(.systemGreen)
    }
    
    private var bubbleShape: some Shape {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
    }
}

#Preview {
    MyChat()
        .environment(FoundationManager())
}
