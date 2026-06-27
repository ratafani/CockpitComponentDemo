import RealityKit
import ILSFoundation
import ILSEngine
import ILSHandTracking

public struct CockpitComponent: Component {
    /// References to specific interactive parts of the cockpit
    public var sidestickEntity: Entity?
    public var sidestickModelEntity: ModelEntity?
    public var sidestickJointIndex: Int?
    
    public var throttleEntity: Entity?
    
    // Interaction States
    public var isSidestickGrabbed: Bool = false
    public var isThrottleGrabbed: Bool = false
    
    // Base transformations to calculate delta
    public var initialSidestickTransform: Transform?
    public var initialThrottleTransform: Transform?
    
    /// Current values for simulation
    public var throttleValue: Float = 0.0 // 0 to 1
    public var sidestickPitch: Float = 0.0
    public var sidestickRoll: Float = 0.0
    public var normalizedDisplacement: SIMD2<Float> = .zero
    
    public init() {}
}
