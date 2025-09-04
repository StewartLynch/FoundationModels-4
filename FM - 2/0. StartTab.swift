//
//----------------------------------------------
// Original project: FM - 2
// by  Stewart Lynch on 2025-08-31
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

enum MyTabs: String, CaseIterable, View {
    case promptBuilder = "Workout"
    case promptArrays = "Full Workout"
    case chat = "Tourist Info"
    
    var id: Self { self }
    var body: some View {
        switch self {
        case .promptBuilder:
            ThePromptBuilder()
        case .promptArrays:
            Prompt_Stream_WithArrays()
        case .chat:
            MultiTurnSession()
        }
        
    }
}


struct StartTab: View {
    @State private var selectedTab = MyTabs.promptBuilder
    @Environment(FoundationManager.self) var manager
    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                ForEach(MyTabs.allCases.indices, id: \.self) { index in
                    let tab = MyTabs.allCases[index]
                    Tab(
                        tab.rawValue,
                        systemImage: "\(index + 1).circle",
                        value: tab) {
                            tab
                        }
                }
            }
            .navigationTitle(selectedTab.rawValue)
        }
    }
}

#Preview {
    StartTab()
        .environment(FoundationManager())
}


