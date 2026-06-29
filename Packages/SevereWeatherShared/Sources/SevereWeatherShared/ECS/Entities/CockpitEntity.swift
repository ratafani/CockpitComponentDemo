import RealityKit
import RealityKitContent
import ILSFoundation
import ILSEngine
import ILSHandTracking


public class CockpitEntity: Entity {
    
    private let logger = ILLogger(subsystem: .app, category: "CockpitEntity")
    
    public enum NodeName: String, CaseIterable {
        case sidestick = "Cube_002"
        case throttleLeft = "CP_ThrottleL_Lever_Rig_V01"
        case throttleRight = "CP_ThrottleR_Lever_Rig_V01"
    }
    
    public var component: CockpitComponent {
        get { components[CockpitComponent.self] ?? CockpitComponent() }
        set { components[CockpitComponent.self] = newValue }
    }
    
    public init(immersiveCockpit: Entity) {
        super.init()
        
        // Add the loaded 3D model as a child
        self.addChild(immersiveCockpit)
        
        // Initialize component
        var cockpitComponent = CockpitComponent()
        
        // Helper to extract ModelEntity and joint
        func setupSidestick(boneNode: Entity, rootNode: Entity) {
            cockpitComponent.sidestickEntity = boneNode
            cockpitComponent.initialSidestickTransform = boneNode.transform
            
            // The Skinned Mesh (ModelEntity) is usually the root node or one of its direct children, NOT the bone itself
            let modelEntity: ModelEntity? = (rootNode as? ModelEntity) ?? rootNode.children.compactMap { $0 as? ModelEntity }.first
            
            if let model = modelEntity, !model.jointNames.isEmpty {
                cockpitComponent.sidestickModelEntity = model
                
                // If Cube_002 happens to match a joint name exactly
                if let index = model.jointNames.firstIndex(of: boneNode.name) {
                    cockpitComponent.sidestickJointIndex = index
                    logger.info("Found exact joint match: \(boneNode.name) at index \(index)")
                }
                else if let index = model.jointNames.firstIndex(where: { $0.lowercased().contains("stick") }) {
                    cockpitComponent.sidestickJointIndex = index
                    logger.info("Found Sidestick joint: \(model.jointNames[index]) at index \(index)")
                } else if model.jointNames.count > 1 {
                    cockpitComponent.sidestickJointIndex = model.jointNames.count - 1
                    logger.info("Using last joint for Sidestick: \(model.jointNames.last!)")
                } else {
                    cockpitComponent.sidestickJointIndex = 0
                }
            }
        }
        
        // Find sidestick and throttle using strongly typed node names
        if let sidestickRoot = immersiveCockpit.findEntity(named: "Sidestick2"),
           let sidestickBone = sidestickRoot.findEntity(named: NodeName.sidestick.rawValue) {
            setupSidestick(boneNode: sidestickBone, rootNode: sidestickRoot)
        } else if let sidestickBone = immersiveCockpit.findEntity(named: NodeName.sidestick.rawValue) {
            setupSidestick(boneNode: sidestickBone, rootNode: immersiveCockpit)
        } else {
            logger.error("❌ Failed to find Sidestick entity with name: \(NodeName.sidestick.rawValue)")
        }
        
        if let throttleL = immersiveCockpit.findEntity(named: NodeName.throttleLeft.rawValue) {
            cockpitComponent.throttleEntity = throttleL
            cockpitComponent.initialThrottleTransform = throttleL.transform
            // Set visually to 1.0 position (OVERSPEED)
            throttleL.transform.rotation = throttleL.transform.rotation * simd_quatf(angle: -Float.pi/4, axis: [1, 0, 0])
        } else if let throttleR = immersiveCockpit.findEntity(named: NodeName.throttleRight.rawValue) {
            cockpitComponent.throttleEntity = throttleR
            cockpitComponent.initialThrottleTransform = throttleR.transform
            // Set visually to 1.0 position (OVERSPEED)
            throttleR.transform.rotation = throttleR.transform.rotation * simd_quatf(angle: -Float.pi/4, axis: [1, 0, 0])
        } else {
            logger.error("❌ Failed to find Throttle entity with names: \(NodeName.throttleLeft.rawValue) or \(NodeName.throttleRight.rawValue)")
        }
        
        self.components.set(cockpitComponent)
    }
    
    required init() {
        fatalError("init() has not been implemented")
    }
}
