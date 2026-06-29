import RealityKit
import Foundation

public enum ThreatState: Int {
    case safe = 0
    case buildup = 1
    case crisis = 2
}

public struct ThreatComponent: Component {
    public var currentState: ThreatState = .safe
    
    // Timer for automatically transitioning states
    public var stateTimer: TimeInterval = 0.0
    
    // Audio controllers
    public var engineController: AudioPlaybackController?
    public var groanController: AudioPlaybackController?
    public var alarmController: AudioPlaybackController?
    public var overspeedController: AudioPlaybackController?
    
    // Engine pitch manipulation
    public var targetEngineSpeed: Double = 1.0
    public var currentEngineSpeed: Double = 1.0
    
    // Lighting references (Stored as entity IDs so they can be retrieved from scene)
    public var masterWarningLightLeftID: Entity.ID?
    public var masterWarningLightRightID: Entity.ID?
    public var overheadAmbientLightID: Entity.ID?
    
    // Strobe effect logic
    public var isStrobeOn: Bool = false
    public var strobeTimer: TimeInterval = 0.0
    public let strobeInterval: TimeInterval = 0.15 // Fast blink for CRC alarm
    
    public init() {
        // Start in safe state, transition to buildup after 5-10 seconds
        self.stateTimer = TimeInterval.random(in: 5...10)
    }
}
