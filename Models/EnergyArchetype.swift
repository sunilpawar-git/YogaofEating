import Foundation

enum EnergyArchetype: String, Codable, CaseIterable {
    case steadyState
    case spikeDip
    case nocturnalOwl
    case earlyBird
    case inconsistent

    var displayName: String {
        switch self {
        case .steadyState: Strings.EnergyArchetype.steadyState
        case .spikeDip: Strings.EnergyArchetype.spikeDip
        case .nocturnalOwl: Strings.EnergyArchetype.nocturnalOwl
        case .earlyBird: Strings.EnergyArchetype.earlyBird
        case .inconsistent: Strings.EnergyArchetype.inconsistent
        }
    }
}
