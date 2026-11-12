import Foundation

/// The local task-list scope. Scope changes never alter the running timer.
enum WorkScope: Equatable, Sendable {
    case allWork
    case unassigned
    case organization(UUID)

    static let storageKey = "work.organizationScope"

    init(rawValue: String?) {
        switch rawValue {
        case "unassigned":
            self = .unassigned
        case let value? where value != "all":
            if let id = UUID(uuidString: value) {
                self = .organization(id)
            } else {
                self = .allWork
            }
        default:
            self = .allWork
        }
    }

    var rawValue: String {
        switch self {
        case .allWork: "all"
        case .unassigned: "unassigned"
        case .organization(let id): id.uuidString
        }
    }

    var defaultTaskParent: WorkParent? {
        guard case .organization(let id) = self else { return nil }
        return .organization(id)
    }

    func defaultTaskParent(in organizations: [WorkOrganization]) -> WorkParent? {
        guard case .organization(let id) = self,
              organizations.contains(where: { $0.id == id && !$0.archived }) else {
            return nil
        }
        return .organization(id)
    }

    func normalized(in organizations: [WorkOrganization]) -> WorkScope {
        guard case .organization(let id) = self else { return self }
        return organizations.contains(where: { $0.id == id && !$0.archived })
            ? self
            : .allWork
    }

    func title(in organizations: [WorkOrganization]) -> String {
        switch self {
        case .allWork:
            "All Work"
        case .unassigned:
            "Unassigned"
        case .organization(let id):
            organizations.first(where: { $0.id == id && !$0.archived })?.name ?? "All Work"
        }
    }

    /// Organization scope includes tasks assigned directly to that organization,
    /// one of its clients, or one of a client's projects.
    func matches(task: ActivityItem, snapshot: WorkSnapshot) -> Bool {
        guard task.archived != true else { return false }
        switch self {
        case .allWork:
            return true
        case .unassigned:
            return task.workParent == nil
        case .organization(let id):
            return snapshot.organization?.id == id
        }
    }
}
