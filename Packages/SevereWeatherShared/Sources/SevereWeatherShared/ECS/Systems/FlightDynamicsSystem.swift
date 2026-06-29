import RealityKit
import Foundation
import simd

public class FlightDynamicsSystem: System {
    private static let environmentQuery = EntityQuery(where: .has(EnvironmentComponent.self))
    private static let cockpitQuery = EntityQuery(where: .has(CockpitComponent.self))
    private static let cloudQuery = EntityQuery(where: .has(CloudTagComponent.self) && .has(OpacityComponent.self))
    
    public required init(scene: RealityKit.Scene) {}
    
    public func update(context: SceneUpdateContext) {
        let deltaTime = Float(context.deltaTime)
        
        // 1. Get Cockpit State
        var throttle: Float = 0.0
        var sidestickInput: SIMD2<Float> = .zero
        
        let cockpitEntities = context.scene.performQuery(Self.cockpitQuery)
        for entity in cockpitEntities {
            if let cockpit = entity.components[CockpitComponent.self] {
                throttle = cockpit.throttleValue
                sidestickInput = cockpit.normalizedDisplacement
                break
            }
        }
        
        // 2. Update Environment
        let environmentEntities = context.scene.performQuery(Self.environmentQuery)
        for entity in environmentEntities {
            guard var envComp = entity.components[EnvironmentComponent.self] else { continue }
            
            let speed = throttle * 150.0 // 150 m/s max speed
            
            // Note: We no longer translate the environmentRoot itself.
            // We only rotate it, and we translate the individual clouds!
            
            // --- ROTATION (Pitch, Roll, and YAW) ---
            // If nose down (stick pushed forward / +Z), environment must tilt UP (+pitch)
            // If roll left (stick pushed left / -X), environment must roll RIGHT (+roll)
            
            // Map sidestick displacement (-1 to 1) to angles
            let targetPitch = sidestickInput.y * (Float.pi / 4.0) // Max 45 degrees
            let targetRoll = -sidestickInput.x * (Float.pi / 3.0) // Max 60 degrees (negative because pushing left should roll environment right)
            
            // Smoothly interpolate current angles to target angles
            envComp.currentPitch = simd_mix(envComp.currentPitch, targetPitch, Float(deltaTime * 2.0))
            envComp.currentRoll = simd_mix(envComp.currentRoll, targetRoll, Float(deltaTime * 2.0))
            
            // Apply YAW (Turn) based on current Roll
            // If environment is rolled right (+roll), aircraft is rolling left.
            // Aircraft rolling left -> turns left -> environment should turn right (-yaw)
            envComp.currentYaw -= envComp.currentRoll * 0.5 * deltaTime
            
            let pitchRotation = simd_quatf(angle: envComp.currentPitch, axis: [1, 0, 0])
            let rollRotation = simd_quatf(angle: envComp.currentRoll, axis: [0, 0, 1])
            let yawRotation = simd_quatf(angle: envComp.currentYaw, axis: [0, 1, 0])
            
            entity.orientation = yawRotation * pitchRotation * rollRotation
            
            entity.components.set(envComp)
        }
        
        // Cloud logic has been moved to CloudSystem (Phase 2 & Phase 3)
    }
}
