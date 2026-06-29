import RealityKit
import Foundation
import ILSFoundation

public class ShakeSystem: System {
    private let logger = ILLogger(subsystem: .app, category: "ShakeSystem")
    private static let query = EntityQuery(where: .has(ShakeComponent.self) && .has(ThreatComponent.self))
    
    public required init(scene: RealityKit.Scene) {}
    
    public func update(context: SceneUpdateContext) {
        let deltaTime = context.deltaTime
        
        let entities = context.scene.performQuery(Self.query)
        for entity in entities {
            guard var shakeComp = entity.components[ShakeComponent.self],
                  let threatComp = entity.components[ThreatComponent.self] else { continue }
            
            // Capture original transform if not set
            if shakeComp.originalPosition == nil {
                shakeComp.originalPosition = entity.position
                shakeComp.originalRotation = entity.orientation
            }
            
            // Determine intensity based on ThreatState
            switch threatComp.currentState {
            case .safe:
                shakeComp.intensity = 0.0
            case .buildup:
                // Slowly increase intensity from 0 to max over 5 seconds
                shakeComp.intensity = min(shakeComp.maxIntensity, shakeComp.intensity + Float(deltaTime) * (shakeComp.maxIntensity / 5.0))
            case .crisis:
                shakeComp.intensity = shakeComp.maxIntensity
            }
            
            if shakeComp.intensity > 0.001 {
                // Burst logic
                shakeComp.shakeBurstTimer -= deltaTime
                if shakeComp.shakeBurstTimer <= 0 {
                    shakeComp.isShakingNow.toggle()
                    if shakeComp.isShakingNow {
                        shakeComp.shakeBurstTimer = TimeInterval.random(in: 0.5...1.5) // Shake duration
                    } else {
                        shakeComp.shakeBurstTimer = TimeInterval.random(in: 1.0...2.5) // Pause duration
                    }
                }
                
                if shakeComp.isShakingNow {
                    shakeComp.timeElapsed += deltaTime
                    
                    // Simple fast chaotic shaking using sin/cos of high frequencies
                    let time = Float(shakeComp.timeElapsed)
                    
                    let offsetX = sin(time * 35.0) * shakeComp.intensity
                    let offsetY = cos(time * 42.0) * shakeComp.intensity
                    let offsetZ = sin(time * 28.0) * cos(time * 15.0) * shakeComp.intensity
                    
                    let pitch = sin(time * 20.0) * (shakeComp.intensity * 2.0)
                    let roll = cos(time * 25.0) * (shakeComp.intensity * 1.5)
                    
                    if let origPos = shakeComp.originalPosition, let origRot = shakeComp.originalRotation {
                        entity.position = origPos + SIMD3<Float>(offsetX, offsetY, offsetZ)
                        
                        let rotDelta = simd_quatf(angle: pitch, axis: [1, 0, 0]) * simd_quatf(angle: roll, axis: [0, 0, 1])
                        entity.orientation = origRot * rotDelta
                    }
                } else if let origPos = shakeComp.originalPosition, let origRot = shakeComp.originalRotation {
                    // Smoothly return to center during pause
                    entity.position = simd_mix(entity.position, origPos, SIMD3<Float>(repeating: Float(deltaTime * 10.0)))
                    entity.orientation = simd_slerp(entity.orientation, origRot, Float(deltaTime * 10.0))
                }
            } else if let origPos = shakeComp.originalPosition, let origRot = shakeComp.originalRotation {
                // Restore smoothly to original position if shaking stops
                entity.position = simd_mix(entity.position, origPos, SIMD3<Float>(repeating: Float(deltaTime * 5.0)))
                entity.orientation = simd_slerp(entity.orientation, origRot, Float(deltaTime * 5.0))
            }
            
            entity.components.set(shakeComp)
        }
    }
}
