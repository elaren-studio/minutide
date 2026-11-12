import Foundation
import SwiftData

@Model
public final class WorkOrganization {
    public var id: UUID
    public var name: String
    public var colorHex: String?
    public var sfSymbolName: String?
    public var archived: Bool
    public var createdDate: Date

    public init(id: UUID = UUID(), name: String, colorHex: String? = nil, sfSymbolName: String? = nil) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.sfSymbolName = sfSymbolName
        self.archived = false
        self.createdDate = .now
    }
}

@Model
public final class WorkClient {
    public var id: UUID
    public var name: String
    public var organizationID: UUID?
    public var colorHex: String?
    public var sfSymbolName: String?
    public var archived: Bool
    public var createdDate: Date

    public init(id: UUID = UUID(), name: String, organizationID: UUID,
                colorHex: String? = nil, sfSymbolName: String? = nil) {
        self.id = id
        self.name = name
        self.organizationID = organizationID
        self.colorHex = colorHex
        self.sfSymbolName = sfSymbolName
        self.archived = false
        self.createdDate = .now
    }
}

@Model
public final class WorkProject {
    public var id: UUID
    public var name: String
    public var clientID: UUID?
    public var colorHex: String?
    public var sfSymbolName: String?
    public var archived: Bool
    public var createdDate: Date

    public init(id: UUID = UUID(), name: String, clientID: UUID,
                colorHex: String? = nil, sfSymbolName: String? = nil) {
        self.id = id
        self.name = name
        self.clientID = clientID
        self.colorHex = colorHex
        self.sfSymbolName = sfSymbolName
        self.archived = false
        self.createdDate = .now
    }
}
