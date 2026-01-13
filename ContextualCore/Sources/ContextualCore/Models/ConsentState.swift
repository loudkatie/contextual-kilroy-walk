import Foundation

public enum ConsentState: String, Codable {
    case idle
    case awaiting
    case granted
    case ignored
    case coolingDown
}
