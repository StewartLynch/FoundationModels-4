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


import Foundation
import FoundationModels

@Observable
final class FoundationManager {
    var notAvailableReason = "Checking model availability..."
    var prompt: Prompt?
    var response: String = ""
    var isModelAvailable: Bool {
        notAvailableReason.isEmpty
    }

    init() {
        checkIsAvailable()
    }
    
    @discardableResult
    func checkIsAvailable() -> Bool {
        switch SystemLanguageModel.default.availability {
        case .available:
            notAvailableReason = ""
        case .unavailable(.deviceNotEligible):
            notAvailableReason = "U[grade to use Apple Intelligence"
        case .unavailable(.appleIntelligenceNotEnabled):
            notAvailableReason = "Enable Apple Intelligence in System Settings."
        case .unavailable(.modelNotReady):
            notAvailableReason = "Model not ready.  Downloding or temporarily unavailable. Please wait, ensure sufficient battery and Wi-Fi."
        case.unavailable(let unknownReason):
            notAvailableReason = "Model unavailable: \(String(describing: unknownReason))"
        }
        return isModelAvailable
    }
    
    func getResponse(from topic: String, session: LanguageModelSession) async {
        prompt = Prompt("Create a two verse about \(topic) in the style of William Shakespeare.  Do not return any preamble.  Just return the two verse poem.")
        
        if let prompt {
            do {
                response =  try await session.respond(to: prompt).content
            } catch {
                response = error.localizedDescription
            }
        }
    }
    
    func getResponse(for stretchType: StretchType, length: Double,  session: LanguageModelSession) async  {
        prompt = Prompt {
            "Create an stretching exercise for me."
            "Focus the exercies on \(stretchType.rawValue)"
            "Have the exerecise last for \(Int(length)) minutes"
        }
        if let prompt {
            do {
//                var content = try await session.respond(to: prompt).content
                response = minimizeMarkDown(try await session.respond(to: prompt).content)

            } catch {
                response = error.localizedDescription
            }
        }
    }
    
    func minimizeMarkDown(_ content: String) -> String {
        var content = content
        let tags = ["#", "##", "###", "####", "---"]
        tags.forEach { tag in
            content = content.replacingOccurrences(of: tag, with: "")
        }
        return content
    }
    
    func get30MinuteRoutine(session: LanguageModelSession, prompt: Prompt) async {
            do {
                response = minimizeMarkDown(try await session.respond(to: prompt).content)
            } catch let error as LanguageModelSession.GenerationError {
                switch error {
                case .guardrailViolation(let context):
                response += "Guardrail violation: \(context.debugDescription)\n"
                case .decodingFailure(let context):
                response += "Decoding failure: \(context.debugDescription)\n"
                default:
                response += "Other error: \(error.localizedDescription)\n"
                }
                if let failureReason = error.failureReason {
                    response += failureReason + "\n"
                }
                if let recovertSuggestion = error.recoverySuggestion {
                    response += recovertSuggestion
                }
            } catch {
                response = error.localizedDescription
            }
    }
}
