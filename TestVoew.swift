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

struct TestVoew: View {
    @State private var session = LanguageModelSession()
    @State private var currentPrompt: String = ""

    var body: some View {
        VStack {
            ScrollView {
                ForEach(session.transcript) { entry in
                    Text(entry.description)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom)
                }
            }
            .padding()
            HStack {
                TextField("Prompt...", text: $currentPrompt)
                    .textFieldStyle(.roundedBorder)
                Button("Send") {
                    Task {
                        _ = try? await session.respond(to: currentPrompt)
                        currentPrompt = ""
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .font(.title)
    }
}

#Preview {
    TestVoew()
}
