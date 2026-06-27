import SwiftUI
import RealityKit
import RealityKitContent
import ILSFoundation
import ILSEngine
import ILSHandTracking

@MainActor
@Observable
public class CockpitViewModel {
    
    public var rootEntity: Entity = Entity()
    private var cockpitEntity: CockpitEntity?
    
    public var leftFingerStatus: [Bool] = [false, false, false, false]
    public var rightFingerStatus: [Bool] = [false, false, false, false]
    
    public var isSidestickGrabbed: Bool = false
    public var isThrottleGrabbed: Bool = false
    public var sidestickDisplacement: SIMD2<Float> = .zero
    public var throttleValue: Float = 0.0
    
    public init() {}
    
    public func cleanupScene() {
        rootEntity.children.removeAll()
        cockpitEntity = nil
    }
}
