import RealityKit
import simd

public struct EnvironmentComponent: Component {
    public var currentZOffset: Float = 0.0
    public var currentPitch: Float = 0.0
    public var currentRoll: Float = 0.0
    public var currentYaw: Float = 0.0
    
    // Base orientation to calculate from
    public var baseOrientation: simd_quatf = simd_quatf(angle: 0, axis: [1, 0, 0])
    
    public init() {}
}
