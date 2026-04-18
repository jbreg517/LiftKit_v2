import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID
    var displayName: String?
    var email: String?
    var authProvider: String?
    var isPremium: Bool
    var createdAt: Date

    static let maxFreeTemplates    = 5
    static let maxVisibleTemplates = 10

    init(displayName: String? = nil,
         email: String? = nil,
         authProvider: String? = nil,
         isPremium: Bool = false) {
        self.id           = UUID()
        self.displayName  = displayName
        self.email        = email
        self.authProvider = authProvider
        self.isPremium    = isPremium
        self.createdAt    = Date()
    }
}
