import RealityKit
import simd

public class CockpitInteractionSystem: System {
    private static let cockpitQuery = EntityQuery(where: .has(CockpitComponent.self))
    private static let handQuery = EntityQuery(where: .has(HandModelComponent.self))
    
    // Store reference pinch positions and rotations to calculate deltas
    private var initialLeftPinchPos: SIMD3<Float>?
    private var initialRightPinchPos: SIMD3<Float>?
    private var throttleValueAtGrabStart: Float = 0.0
    
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
                    
                    let rotation = simd_quatf(angle: clampedPitch, axis: [1, 0, 0]) * simd_quatf(angle: clampedRoll, axis: [0, 1, 0])
                    
                    if let model = cockpit.sidestickModelEntity, let jointIndex = cockpit.sidestickJointIndex, model.jointNames.count > jointIndex {
                        // For a Skinned Mesh, apply rotation to the specific joint
                        model.jointTransforms[jointIndex].rotation = rotation
                    } else if let initialRot = cockpit.initialSidestickTransform?.rotation {
                        // Fallback for rigid mesh: rotate the entity
                        cockpit.sidestickEntity?.transform.rotation = initialRot * rotation
                    }
                    
                    // Update displacement
                    cockpit.normalizedDisplacement = SIMD2<Float>(
                        max(-1, min(1, delta.x / 0.1)),
                        max(-1, min(1, delta.z / 0.1))
                    )
                }
            } else {
                cockpit.isSidestickGrabbed = false
                cockpit.normalizedDisplacement = .zero
                initialLeftPinchPos = nil
                // Spring loaded: return to center smoothly
                if let model = cockpit.sidestickModelEntity, let jointIndex = cockpit.sidestickJointIndex, model.jointNames.count > jointIndex {
                    let currentRotation = model.jointTransforms[jointIndex].rotation
                    model.jointTransforms[jointIndex].rotation = simd_slerp(currentRotation, simd_quatf(angle: 0, axis: [1,0,0]), 0.15)
                } else if let currentRotation = cockpit.sidestickEntity?.transform.rotation,
                   let initialRot = cockpit.initialSidestickTransform?.rotation {
                    cockpit.sidestickEntity?.transform.rotation = simd_slerp(currentRotation, initialRot, 0.15)
                }
            }
            
            // Handle Throttle (Right Hand)
            if hands.isRightPinching {
                if !cockpit.isThrottleGrabbed {
                    cockpit.isThrottleGrabbed = true
                    initialRightPinchPos = hands.rightPinchPosition
                    throttleValueAtGrabStart = cockpit.throttleValue
                }
                
                if let initialPos = initialRightPinchPos {
                    let delta = hands.rightPinchPosition - initialPos
                    
                    // User explicitly requested moving hand forward/backward relative to body.
                    // In ARKit, negative Z (-Z) is forward, positive Z (+Z) is backward.
                    // Moving hand straight forward (-Z) pushes throttle to 100%.
                    // We divide by 0.25 (25cm) to scale the movement.
                    let movementDelta = -(delta.z / 0.25)
                    
                    cockpit.throttleValue = max(0.0, min(1.0, throttleValueAtGrabStart + movementDelta))
                    
                    // Apply rotation. Throttle rotates from -pi/4 to pi/4.
                    let currentPitch = (0.5 - cockpit.throttleValue) * (Float.pi / 2)
                    let rotation = simd_quatf(angle: currentPitch, axis: [1, 0, 0])
                    
                    if let initialRot = cockpit.initialThrottleTransform?.rotation {
                        cockpit.throttleEntity?.transform.rotation = initialRot * rotation
                    }
                }
            } else {
                cockpit.isThrottleGrabbed = false
                initialRightPinchPos = nil
            }

            
            entity.components.set(cockpit)
        }
    }
}
