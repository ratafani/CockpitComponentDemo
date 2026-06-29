import RealityKit
import Foundation

public struct ShakeComponent: Component {
    public var intensity: Float = 0.0
    public var maxIntensity: Float = 0.003 // Shaking bounds reduced to be more comfortable
    
    // Original position to return to when not shaking
    public var originalPosition: SIMD3<Float>?
    public var originalRotation: simd_quatf?
    
    // Time tracker for noise calculation
    public var timeElapsed: TimeInterval = 0.0
    
    // Burst logic to prevent continuous shaking (motion sickness prevention)
    public var isShakingNow: Bool = true
    public var shakeBurstTimer: TimeInterval = 0.0
    
    public init() {}
}
