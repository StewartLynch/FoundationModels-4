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

struct TravelAgent: View {
    @State private var question: String = ""
    var body: some View {
        NavigationStack{
            VStack {
                ContentUnavailableView("How can I help?", systemImage: "questionmark.message", description: Text("I am your friendly Tourist Infomation Guide"))
                HStack {
                    TextField("Ask away ...", text: $question)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            // Send Question
                        }
                }
            }
            .navigationTitle("Travel Agent")
            
        }
        
    }
    
}

#Preview {
    TravelAgent()
        .environment(FoundationManager())
}

