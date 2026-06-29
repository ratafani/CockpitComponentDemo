import RealityKit
import Foundation
import ILSFoundation

public class StormSystem: System {
    private let logger = ILLogger(subsystem: .app, category: "StormSystem")
    private static let query = EntityQuery(where: .has(PointLightComponent.self) && .has(LightningComponent.self))
    
    public required init(scene: RealityKit.Scene) {}
    
    public func update(context: SceneUpdateContext) {
        let deltaTime = context.deltaTime
        
        let entities = context.scene.performQuery(Self.query)
        for entity in entities {
            guard var lightningComp = entity.components[LightningComponent.self],
                  var lightComp = entity.components[PointLightComponent.self] else { continue }
            
            if lightningComp.isFlashing {
                lightningComp.flashTimer -= deltaTime
                
                if lightningComp.flashTimer <= 0 {
                    // Move to next sequence step
                    lightningComp.currentSequenceIndex += 1
                    if lightningComp.currentSequenceIndex < lightningComp.flashSequence.count {
                        lightningComp.flashTimer = lightningComp.flashSequence[lightningComp.currentSequenceIndex]
                        
                        // Toggle light intensity based on odd/even index
                        // Even indices (0, 2, 4) are flashes, Odd (1, 3) are dark gaps
                        if lightningComp.currentSequenceIndex % 2 == 0 {
                            lightComp.intensity = lightningComp.maxIntensity
                        } else {
                            lightComp.intensity = lightningComp.baseIntensity
                        }
                    } else {
                        // Flashing finished
                        lightningComp.isFlashing = false
                        lightComp.intensity = lightningComp.baseIntensity
                        lightningComp.nextStrikeTimer = TimeInterval.random(in: 3...10) // Next strike in 3-10s
                        
                        // The thunder sound usually plays at the end of the sequence or during it
                        // We triggered it at the start, so nothing to do here.
                    }
                } else {
                    // Smoothly fade out intensity if we are on a flash (even index)
                    if lightningComp.currentSequenceIndex % 2 == 0 {
                        // Lerp down for a nice fade
                        lightComp.intensity = max(lightningComp.baseIntensity, lightComp.intensity * 0.8)
                    }
                }
                
            } else {
                lightningComp.nextStrikeTimer -= deltaTime
                
                if lightningComp.nextStrikeTimer <= 0 {
                    // Trigger a strike!
                    lightningComp.isFlashing = true
                    
                    // Create a random flash pattern
                    // Example: [FlashDuration, Gap, FlashDuration, Gap, LongFade]
                    lightningComp.flashSequence = [
                        0.05, 0.05,
                        0.1,  0.1,
                        0.2
                    ]
                    lightningComp.currentSequenceIndex = 0
                    lightningComp.flashTimer = lightningComp.flashSequence[0]
                    lightComp.intensity = lightningComp.maxIntensity
                    
                    // Play thunder sound with spatial audio!
                    if let audio = lightningComp.thunderAudio {
                        // Delay thunder slightly based on "distance" to make it realistic
                        let distanceDelay = TimeInterval.random(in: 0.2...1.5)
                        Task { @MainActor in
                            try? await Task.sleep(nanoseconds: UInt64(distanceDelay * 1_000_000_000))
                            lightningComp.playbackController = entity.playAudio(audio)
                        }
                    }
                    
                    // RANDOMIZE SPATIAL POSITION OF LIGHTNING
                    // Spawn far away (Z: -100 to -30), but within the scaled down cloud radius
                    let randomX = Float.random(in: -60 ... 60)
                    let randomY = Float.random(in: 5 ... 30)
                    let randomZ = Float.random(in: -100 ... -30)
                    
                    // We use local position! Since environmentRoot rotates but no longer translates,
                    // the lightning will perfectly follow the pitch/yaw/roll of the environment.
                    entity.position = SIMD3<Float>(randomX, randomY, randomZ)
                    
                    // Make the flash huge and bright
                    lightComp.intensity = 20_000_000 // Extremely intense to blast through the clouds
                    lightComp.attenuationRadius = 150.0 // Scaled down but enough to cover the clouds
                    
                    logger.info("🌩️ Lightning strike triggered at local \(entity.position)!")
                }
            }
            
            // Re-apply components
            entity.components.set(lightningComp)
            entity.components.set(lightComp)
        }
    }
}
