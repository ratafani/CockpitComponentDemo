import RealityKit
import RealityKitContent
import ILSFoundation
import ILSEngine
import ILSHandTracking


public class CockpitEntity: Entity {
    
    private let logger = ILLogger(subsystem: .app, category: "CockpitEntity")
    
    public enum NodeName: String, CaseIterable {
        case sidestick = "SC_SideStickL_V01"
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
        
        // Find sidestick and throttle using strongly typed node names
        if let sidestick = immersiveCockpit.findEntity(named: NodeName.sidestick.rawValue) {
            cockpitComponent.sidestickEntity = sidestick
            cockpitComponent.initialSidestickTransform = sidestick.transform
        } else {
            logger.error("❌ Failed to find Sidestick entity with name: \(NodeName.sidestick.rawValue)")
        }
        
        if let throttleL = immersiveCockpit.findEntity(named: NodeName.throttleLeft.rawValue) {
            cockpitComponent.throttleEntity = throttleL
            cockpitComponent.initialThrottleTransform = throttleL.transform
        } else if let throttleR = immersiveCockpit.findEntity(named: NodeName.throttleRight.rawValue) {
            cockpitComponent.throttleEntity = throttleR
            cockpitComponent.initialThrottleTransform = throttleR.transform
        } else {
            logger.error("❌ Failed to find Throttle entity with names: \(NodeName.throttleLeft.rawValue) or \(NodeName.throttleRight.rawValue)")
        }
        
        self.components.set(cockpitComponent)
    }
    
    required init() {
        fatalError("init() has not been implemented")
    }
}
