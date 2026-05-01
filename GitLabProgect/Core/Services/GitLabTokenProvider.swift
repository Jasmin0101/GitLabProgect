import Foundation

enum GitLabTokenProvider {
    static func token() -> String? {
        let envValue = ProcessInfo.processInfo.environment["GITLAB_TOKEN"]?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if let envValue, !envValue.isEmpty {
            return envValue
        }

        let infoPlistValue = Bundle.main.object(forInfoDictionaryKey: "GITLAB_TOKEN") as? String
        let value = infoPlistValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !value.isEmpty {
            return value
        }

        return nil
    }
}
