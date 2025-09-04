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
    
#warning("Added for this video")
    func minimizeMarkDown(_ content: String) -> String {
        var content = content
        let tags = ["#", "##", "###", "####", "---"]
        tags.forEach { tag in
            content = content.replacingOccurrences(of: tag, with: "")
        }
        return content
    }
    
    func getResponse(from prompt: Prompt, session: LanguageModelSession) async -> String{
        //                return try! await session.respond(to: prompt).content
        var responseText = ""
        do {
#warning("Added for this video")
            responseText =  minimizeMarkDown(try await session.respond(to: prompt).content)
        } catch let error as LanguageModelSession.GenerationError {
            switch error {
                //            case .exceededContextWindowSize(let context):
                //
                //            case .assetsUnavailable(let context):
                //
            case .guardrailViolation(let context):
                responseText = "Guardrail violation: \(context.debugDescription)\n"
                //            case .unsupportedGuide(let context):
                //
                //            case .unsupportedLanguageOrLocale(let context):
                //
            case .decodingFailure(let context):
                responseText = "Decoding failure: \(context.debugDescription)\n"
                //            case .rateLimited(let context):
                //
                //            case .concurrentRequests(let context):
                //
                //            case .refusal(let refusal, let context):
            default:
                responseText = "Other error: \(error.localizedDescription)\n"
            }
            if let failureReason = error.failureReason {
                responseText += failureReason + "\n"
            }
            if let recovertSuggestion = error.recoverySuggestion {
                responseText += recovertSuggestion
            }
        } catch {
            return error.localizedDescription
        }
        return responseText
    }
    
    func getStream(from prompt: Prompt, session: LanguageModelSession, completion: (String) -> ()) async {
        var responseText = ""
        do {
            let stream = session.streamResponse(to: prompt)
            for try await partial in stream {
                completion(partial.content)
            }
            completion(minimizeMarkDown(try await session.respond(to: prompt).content))
        } catch let error as LanguageModelSession.GenerationError {
            switch error {
            case .guardrailViolation(let context):
                responseText = "Guardrail violation: \(context.debugDescription)\n"
            case .decodingFailure(let context):
                responseText = "Decoding failure: \(context.debugDescription)\n"
            default:
                responseText = "Other error: \(error.localizedDescription)\n"
            }
            if let failureReason = error.failureReason {
                responseText += failureReason + "\n"
            }
            if let recovertSuggestion = error.recoverySuggestion {
                responseText += recovertSuggestion
            }
            completion(responseText)
        } catch {
            completion(error.localizedDescription)
        }
    }

}
