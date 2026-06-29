import RealityKit
import Foundation
import simd

public class CloudSystem: System {
    private static let cloudQuery = EntityQuery(where: .has(CloudComponent.self))
    private static let cockpitQuery = EntityQuery(where: .has(CockpitComponent.self))
    
    public required init(scene: RealityKit.Scene) {}
    
    public func update(context: SceneUpdateContext) {
        let deltaTime = Float(context.deltaTime)
        
        // 1. Read Aircraft "State" (Speed from Throttle)
        var aircraftSpeed: Float = 0.0
        let cockpitEntities = context.scene.performQuery(Self.cockpitQuery)
        for entity in cockpitEntities {
            if let cockpit = entity.components[CockpitComponent.self] {
                aircraftSpeed = cockpit.throttleValue * 150.0 // 150 m/s max speed
                break
            }
        }
        
        // Aircraft forward vector is ALWAYS (0, 0, -1) because it's locked at the origin.
        let forwardVector = SIMD3<Float>(0, 0, -1)
        
        // Global offset vector that the aircraft travels this frame
        let velocityOffset = forwardVector * aircraftSpeed * deltaTime
        
        // 2. Process all Cloud entities
        let cloudEntities = context.scene.performQuery(Self.cloudQuery)
        
        for cloud in cloudEntities {
            guard let cloudComp = cloud.components[CloudComponent.self] else { continue }
            
            // --- PHASE 2: MOVEMENT ---
            // Move the cloud in the opposite direction of the aircraft's offset vector.
            // (If aircraft moves -Z, cloud must move +Z relative to it to come towards the pilot).
            // We multiply by speedMultiplier for parallax.
            let movementDelta = -velocityOffset * cloudComp.speedMultiplier
            
            // Assuming cloud is at top-level or its parent isn't scaled/rotated strangely, 
            // we apply this in its local space if it's a child of EnvironmentRoot which is already rotated.
            // Wait, if it's a child of EnvironmentRoot, the EnvironmentRoot is rotated. 
            // So if we move it by +Z in local space, it simulates the aircraft flying forward in that environment.
            // We'll use local position. z += movementDelta.z (which is positive)
            // But if we use vector addition:
            cloud.position += movementDelta
            
            // --- PHASE 3: RECYCLING LOGIC ---
            // Check cloud position relative to pilot (0,0,0)
            let cloudPos = cloud.position
            
            // Dot product to check if cloud is in front or behind.
            // forwardVector is (0, 0, -1). 
            // dot(cloudPos, forwardVector) = cloudPos.z * -1
            let dotProduct = simd_dot(cloudPos, forwardVector)
            
            // If dotProduct < 0, it means it's behind the pilot.
            // In (0,0,-1) forward vector, a positive Z means behind the pilot.
            // So dotProduct of (0, 0, 5) and (0, 0, -1) is -5. 
            // Threshold is the maxRecycleDistance. 
            // Example: threshold = 20. So if Z > 20, dotProduct < -20.
            if dotProduct < -cloudComp.maxRecycleDistance {
                // Cloud is too far behind, time to recycle!
                
                // Use the MathUtility to calculate a new position in front of the aircraft.
                let newPos = MathUtility.randomCoordinateInForwardCone(
                    radius: cloudComp.spawnRadius,
                    azimuthRange: -Float.pi/4 ... Float.pi/4, // -45 to +45 degrees
                    elevationRange: -Float.pi/12 ... Float.pi/6 // -15 to +30 degrees
                )
                
                // Teleport cloud to the new position
                cloud.position = newPos
                
                // Randomize Yaw (Rotation around Y axis)
                let randomYaw = Float.random(in: 0...(2 * Float.pi))
                cloud.orientation = simd_quatf(angle: randomYaw, axis: [0, 1, 0])
                
                // Randomize Scale (between 0.8x and 1.5x of its base scale)
                let randomScaleFactor = Float.random(in: 0.8...1.5)
                
                // Apply Far Ring Modification (Scale Illusion) if it's a far ring cloud
                if cloudComp.ringType == .far {
                    // For Far Ring, spawnRadius might be logically 10,000m, but we capped it.
                    // The scale illusion scales it down drastically. We multiply the baseScale by this small factor.
                    let farScaleIllusionFactor: Float = 0.1
                    cloud.scale = cloudComp.baseScale * randomScaleFactor * farScaleIllusionFactor
                } else {
                    cloud.scale = cloudComp.baseScale * randomScaleFactor
                }
            }
        }
    }
}
