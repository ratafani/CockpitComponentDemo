import RealityKit
import simd

public struct CloudTagComponent: Component {
    public var targetScale: Float
    
    public init(targetScale: Float = 1.0) {
        self.targetScale = targetScale
    }
}
