import RealityKit
import simd

public class CockpitInteractionSystem: System {
    private static let cockpitQuery = EntityQuery(where: .has(CockpitComponent.self))
    private static let handQuery = EntityQuery(where: .has(HandModelComponent.self))
    
    // Store reference pinch positions and rotations to calculate deltas
    private var initialLeftPinchPos: SIMD3<Float>?
    private var initialRightPinchPos: SIMD3<Float>?
    private var throttleGrabRotation: simd_quatf?
    
    public required init(scene: RealityKit.Scene) {}
    
    public func update(context: SceneUpdateContext) {
        let handEntities = context.scene.performQuery(Self.handQuery)
        var handComp: HandModelComponent?
        for entity in handEntities {
            handComp = entity.components[HandModelComponent.self]
            break
        }
        
        guard let hands = handComp else { return }
        
        let cockpitEntities = context.scene.performQuery(Self.cockpitQuery)
        for entity in cockpitEntities {
            guard var cockpit = entity.components[CockpitComponent.self] else { continue }
            
            // Handle Sidestick (Left Hand)
            if hands.isLeftPinching {
                if !cockpit.isSidestickGrabbed {
                    cockpit.isSidestickGrabbed = true
                    initialLeftPinchPos = hands.leftPinchPosition
                }
                
                if let initialPos = initialLeftPinchPos {
                    let delta = hands.leftPinchPosition - initialPos
                    let pitchAngle = (delta.z / 0.1) * (Float.pi / 6)
                    let rollAngle = (delta.x / 0.1) * (Float.pi / 6)
                    
                    let clampedPitch = max(-Float.pi/9, min(Float.pi/9, pitchAngle))
                    let clampedRoll = max(-Float.pi/9, min(Float.pi/9, rollAngle))
                    
                    if let initialRot = cockpit.initialSidestickTransform?.rotation {
                        let rotation = simd_quatf(angle: clampedPitch, axis: [1, 0, 0]) * simd_quatf(angle: -clampedRoll, axis: [0, 0, 1])
                        cockpit.sidestickEntity?.transform.rotation = initialRot * rotation
                    }
                }
            } else {
                cockpit.isSidestickGrabbed = false
                initialLeftPinchPos = nil
                // Spring loaded: return to center smoothly
                if let currentRotation = cockpit.sidestickEntity?.transform.rotation,
                   let initialRot = cockpit.initialSidestickTransform?.rotation {
                    cockpit.sidestickEntity?.transform.rotation = simd_slerp(currentRotation, initialRot, 0.15)
                }
            }
            
            // Handle Throttle (Right Hand)
            if hands.isRightPinching {
                if !cockpit.isThrottleGrabbed {
                    cockpit.isThrottleGrabbed = true
                    initialRightPinchPos = hands.rightPinchPosition
                    throttleGrabRotation = cockpit.throttleEntity?.transform.rotation
                }
                
                if let initialPos = initialRightPinchPos, let baseRot = throttleGrabRotation {
                    let delta = hands.rightPinchPosition - initialPos
                    let pitchAngle = (delta.z / 0.1) * (Float.pi / 4)
                    let clampedPitch = max(-Float.pi/4, min(Float.pi/4, pitchAngle))
                    
                    let rotation = simd_quatf(angle: clampedPitch, axis: [1, 0, 0])
                    cockpit.throttleEntity?.transform.rotation = baseRot * rotation
                }
            } else {
                cockpit.isThrottleGrabbed = false
                initialRightPinchPos = nil
                throttleGrabRotation = nil
                // Throttle stays where it was left (no spring)
            }
            
            entity.components.set(cockpit)
        }
    }
}
