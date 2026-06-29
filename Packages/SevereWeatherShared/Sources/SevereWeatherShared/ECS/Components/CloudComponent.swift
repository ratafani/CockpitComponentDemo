import RealityKit
import Foundation

public struct CloudComponent: Component {
    public enum RingType { 
        case near
        case mid
        case far
    }
    
    public var ringType: RingType
    public var speedMultiplier: Float // Near = 1.0, Mid = 0.5, Far = 0.05
    public var maxRecycleDistance: Float // Distance behind pilot before recycling
    public var spawnRadius: Float // Distance in front of pilot to spawn
    public var baseScale: SIMD3<Float> // Store the initial/base scale of the cloud
    
    public init(ringType: RingType, speedMultiplier: Float, maxRecycleDistance: Float, spawnRadius: Float, baseScale: SIMD3<Float> = .one) {
        self.ringType = ringType
        self.speedMultiplier = speedMultiplier
        self.maxRecycleDistance = maxRecycleDistance
        self.spawnRadius = spawnRadius
        self.baseScale = baseScale
    }
}
