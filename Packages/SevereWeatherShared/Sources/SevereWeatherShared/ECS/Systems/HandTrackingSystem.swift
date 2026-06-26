import RealityKit
import ARKit
import UIKit
import ILSHandTracking
import ILSFoundation

public class HandTrackingSystem: System {
    private let logger = ILLogger(subsystem: .app, category: "HandTracking")
    
    public required init(scene: RealityKit.Scene) {
        // Initialization handled externally by HandTrackingService
    }
    
    public func update(context: SceneUpdateContext) {
        let entities = context.scene.performQuery(Self.handQuery)
        
        let leftHandAnchor = HandTrackingService.shared.latestLeftHand
        let rightHandAnchor = HandTrackingService.shared.latestRightHand
        
        for entity in entities {
            guard var handComp = entity.components[HandModelComponent.self] else { continue }
            
            updateGlove(handComp.leftGlove, with: leftHandAnchor, isPinching: &handComp.isLeftPinching, pinchPos: &handComp.leftPinchPosition, fingerStatus: &handComp.leftFingerStatus, originalMaterials: handComp.originalLeftMaterials, side: "Left")
            updateGlove(handComp.rightGlove, with: rightHandAnchor, isPinching: &handComp.isRightPinching, pinchPos: &handComp.rightPinchPosition, fingerStatus: &handComp.rightFingerStatus, originalMaterials: handComp.originalRightMaterials, side: "Right")
            
            // Re-assign the mutated component back to the entity
            entity.components.set(handComp)
        }
    }
    
    @MainActor
    private func updateGlove(_ glove: ModelEntity?, with anchor: HandAnchor?, isPinching: inout Bool, pinchPos: inout SIMD3<Float>, fingerStatus: inout [Bool], originalMaterials: [Material], side: String) {
        guard let glove = glove else { return }
        
        guard let anchor = anchor, anchor.isTracked, let skeleton = anchor.handSkeleton else {
            glove.isEnabled = false
            isPinching = false
            return
        }
        
        glove.isEnabled = true
        glove.transform = Transform(matrix: anchor.originFromAnchorTransform)
        
        let joints = skeleton.allJoints
        let expectedJointCount = HandSkeleton.JointName.allCases.count
        
        // Ensure the model has the same number of joints as the ARKit hand skeleton
        guard glove.jointNames.count == expectedJointCount else { return }
        
        for (index, joint) in joints.enumerated() {
            let jointTransform = skeleton.joint(joint.name).parentFromJointTransform
            glove.jointTransforms[index].rotation = simd_quatf(jointTransform)
        }
        
        // Calculate Grab State (All fingers curled)
        let isIndexCurled = isFingerCurled(skeleton: skeleton, tip: .indexFingerTip, knuckle: .indexFingerKnuckle)
        let isMiddleCurled = isFingerCurled(skeleton: skeleton, tip: .middleFingerTip, knuckle: .middleFingerKnuckle)
        let isRingCurled = isFingerCurled(skeleton: skeleton, tip: .ringFingerTip, knuckle: .ringFingerKnuckle)
        let isLittleCurled = isFingerCurled(skeleton: skeleton, tip: .littleFingerTip, knuckle: .littleFingerKnuckle)
        
        fingerStatus = [isIndexCurled, isMiddleCurled, isRingCurled, isLittleCurled]
        
        let totalCurled = (isIndexCurled ? 1 : 0) + (isMiddleCurled ? 1 : 0) + (isRingCurled ? 1 : 0) + (isLittleCurled ? 1 : 0)
        let wasPinching = isPinching
        // Relax threshold: if 3 out of 4 fingers are curled, consider it a grab
        isPinching = totalCurled >= 3
        
        if isPinching != wasPinching {
            logger.info("\(side) Grab State Changed: \(isPinching) (Index: \(isIndexCurled), Middle: \(isMiddleCurled), Ring: \(isRingCurled), Little: \(isLittleCurled))")
        } else if Int.random(in: 1...60) == 1 {
            // Log occasionally to prove the system is running and show finger states
            logger.info("\(side) Tracking... Curled: \(totalCurled)/4 (I:\(isIndexCurled) M:\(isMiddleCurled) R:\(isRingCurled) L:\(isLittleCurled))")
        }
        
        // Calculate the grab position as the center of the palm (wrist or mid point)
        // We'll use the middle finger knuckle as a proxy for palm center
        let palmJoint = skeleton.joint(.middleFingerKnuckle)
        let palmCol = (anchor.originFromAnchorTransform * palmJoint.anchorFromJointTransform).columns.3
        pinchPos = SIMD3<Float>(palmCol.x, palmCol.y, palmCol.z)
        
        // Visual feedback: green tint
        if isPinching && !wasPinching {
            // Apply green tint
            var material = SimpleMaterial(color: .green.withAlphaComponent(0.8), isMetallic: false)
            glove.model?.materials = [material]
        } else if !isPinching && wasPinching {
            // Restore original materials
            glove.model?.materials = originalMaterials
        }
    }
    
    // Custom finger curled detection that ignores isTracked
    // ARKit loses track of fingertips when they are hidden in a fist,
    // but the estimated transform is still accurate enough for distance checks!
    private func isFingerCurled(skeleton: HandSkeleton, tip: HandSkeleton.JointName, knuckle: HandSkeleton.JointName) -> Bool {
        let tipJoint = skeleton.joint(tip)
        let knuckleJoint = skeleton.joint(knuckle)
        let wristJoint = skeleton.joint(.wrist)
        
        let tipCol = tipJoint.anchorFromJointTransform.columns.3
        let knuckleCol = knuckleJoint.anchorFromJointTransform.columns.3
        let wristCol = wristJoint.anchorFromJointTransform.columns.3
        
        let tipDistance = simd_distance(SIMD3<Float>(tipCol.x, tipCol.y, tipCol.z), SIMD3<Float>(wristCol.x, wristCol.y, wristCol.z))
        let knuckleDistance = simd_distance(SIMD3<Float>(knuckleCol.x, knuckleCol.y, knuckleCol.z), SIMD3<Float>(wristCol.x, wristCol.y, wristCol.z))
        
        return tipDistance < knuckleDistance
    }
    
    private static let handQuery = EntityQuery(where: .has(HandModelComponent.self))
}
