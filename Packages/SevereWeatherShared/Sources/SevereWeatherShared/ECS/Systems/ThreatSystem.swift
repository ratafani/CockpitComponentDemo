import RealityKit
import Foundation
import ILSFoundation

public class ThreatSystem: System {
    private let logger = ILLogger(subsystem: .app, category: "ThreatSystem")
    private static let query = EntityQuery(where: .has(ThreatComponent.self))
    
    public required init(scene: RealityKit.Scene) {}
    
    public func update(context: SceneUpdateContext) {
        let deltaTime = context.deltaTime
        
        let entities = context.scene.performQuery(Self.query)
        for entity in entities {
            guard var threatComp = entity.components[ThreatComponent.self] else { continue }
            
            // Handle State Transitions
            if threatComp.stateTimer > 0 {
                threatComp.stateTimer -= deltaTime
                
                if threatComp.stateTimer <= 0 {
                    // Transition State
                    if threatComp.currentState == .safe {
                        threatComp.currentState = .buildup
                        threatComp.stateTimer = 5.0 // Buildup lasts 5 seconds before crisis
                        
                        logger.info("🚨 Threat Phase 1: Buildup Started")
                        
                        // Start fuselage groan
                        threatComp.groanController?.play()
                        
                        // Begin engine pitch drop
                        threatComp.targetEngineSpeed = 0.4
                        
                    } else if threatComp.currentState == .buildup {
                        threatComp.currentState = .crisis
                        
                        logger.info("🚨 Threat Phase 2: CRISIS Started")
                        
                        // Play Alarms
                        threatComp.alarmController?.play()
                        threatComp.overspeedController?.play()
                        
                        // Turn on Overhead Ambient Red Light
                        if let overheadID = threatComp.overheadAmbientLightID,
                           let overheadEntity = context.scene.findEntity(id: overheadID),
                           var pointLight = overheadEntity.components[PointLightComponent.self] {
                            pointLight.intensity = 5000 // Dim red glow
                            overheadEntity.components.set(pointLight)
                        }
                    }
                }
            }
            
            // Handle Engine Pitch Drop (Lerp speed)
            if threatComp.currentEngineSpeed != threatComp.targetEngineSpeed {
                let diff = threatComp.targetEngineSpeed - threatComp.currentEngineSpeed
                // Slowly drop pitch over time
                threatComp.currentEngineSpeed += diff * min(1.0, deltaTime * 0.5) 
                
                // AudioPlaybackController speed sets playback rate (and thus pitch!)
                threatComp.engineController?.speed = threatComp.currentEngineSpeed
            }
            
            // Check for Recovery in Crisis
            if threatComp.currentState == .crisis {
                if let cockpitComp = entity.components[CockpitComponent.self] {
                    // If throttle is pulled back below 30%, we recover!
                    if cockpitComp.throttleValue < 0.3 {
                        logger.info("✅ Throttle lowered. Recovering from Crisis!")
                        threatComp.currentState = .safe
                        threatComp.stateTimer = 0 // Prevent it from triggering again immediately
                        
                        // Stop Alarms & Groan
                        threatComp.alarmController?.stop()
                        threatComp.overspeedController?.stop()
                        threatComp.groanController?.stop()
                        
                        // Restore Engine
                        threatComp.targetEngineSpeed = 1.0
                        
                        // Turn off Strobe Lights
                        threatComp.isStrobeOn = false
                        if let leftID = threatComp.masterWarningLightLeftID, let leftEntity = context.scene.findEntity(id: leftID), var leftLight = leftEntity.components[PointLightComponent.self] {
                            leftLight.intensity = 0; leftEntity.components.set(leftLight)
                        }
                        if let rightID = threatComp.masterWarningLightRightID, let rightEntity = context.scene.findEntity(id: rightID), var rightLight = rightEntity.components[PointLightComponent.self] {
                            rightLight.intensity = 0; rightEntity.components.set(rightLight)
                        }
                        
                        // Turn off Ambient Red Light
                        if let overheadID = threatComp.overheadAmbientLightID, let overheadEntity = context.scene.findEntity(id: overheadID), var pointLight = overheadEntity.components[PointLightComponent.self] {
                            pointLight.intensity = 0; overheadEntity.components.set(pointLight)
                        }
                    }
                }
            }
            
            // Handle Master Warning Strobe Effect during Crisis
            if threatComp.currentState == .crisis {
                threatComp.strobeTimer -= deltaTime
                if threatComp.strobeTimer <= 0 {
                    threatComp.strobeTimer = threatComp.strobeInterval
                    threatComp.isStrobeOn.toggle()
                    
                    let intensity: Float = threatComp.isStrobeOn ? 100000.0 : 0.0 // Hard strobe
                    
                    if let leftID = threatComp.masterWarningLightLeftID,
                       let leftEntity = context.scene.findEntity(id: leftID),
                       var leftLight = leftEntity.components[PointLightComponent.self] {
                        leftLight.intensity = intensity
                        leftEntity.components.set(leftLight)
                    }
                    
                    if let rightID = threatComp.masterWarningLightRightID,
                       let rightEntity = context.scene.findEntity(id: rightID),
                       var rightLight = rightEntity.components[PointLightComponent.self] {
                        rightLight.intensity = intensity
                        rightEntity.components.set(rightLight)
                    }
                }
            }
            
            entity.components.set(threatComp)
        }
    }
}
