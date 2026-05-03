import Foundation

enum GitLabTokenProvider {
    static func token() -> String? {
      

        let infoPlistValue = Bundle.main.object(forInfoDictionaryKey: "GITLAB_TOKEN") as? String

        return infoPlistValue
    }
}
