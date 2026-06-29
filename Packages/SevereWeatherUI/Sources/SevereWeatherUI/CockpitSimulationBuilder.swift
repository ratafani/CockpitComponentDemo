import SwiftUI
import RealityKit
import RealityKitContent
import SevereWeatherShared
import ARKit

@MainActor
public enum CockpitSimulationBuilder {
    public static func setupWorld(content: RealityViewContent, viewModel: CockpitViewModel) async -> EventSubscription? {
        // 1. Register Components & Systems
        CockpitComponent.registerComponent()
        HandModelComponent.registerComponent()
        LightningComponent.registerComponent()
        ThreatComponent.registerComponent()
        ShakeComponent.registerComponent()
        CloudComponent.registerComponent()
        
        CockpitCalibrationSystem.registerSystem()
        HandTrackingSystem.registerSystem()
        CockpitInteractionSystem.registerSystem()
        StormSystem.registerSystem()
        ThreatSystem.registerSystem()
        ShakeSystem.registerSystem()
        FlightDynamicsSystem.registerSystem()
        CloudSystem.registerSystem()
        
        // 2. Load the immersive cockpit scene and create ECS entities
        do {
            let immersiveCockpit = try await Entity(named: "ImmersiveCockpit", in: realityKitContentBundle)
            let cockpitEntity = CockpitEntity(immersiveCockpit: immersiveCockpit)
            
            // Add threat and shake components to the cockpit entity (for shaking and state tracking)
            var threatComp = ThreatComponent()
            let shakeComp = ShakeComponent()
            
            // Load Hands
            async let leftGloveTask = loadGloveModel(named: "LeftGlove")
            async let rightGloveTask = loadGloveModel(named: "RightGlove")
            let (leftGlove, rightGlove) = await (leftGloveTask, rightGloveTask)
            
            let handsEntity = HandsEntity(leftGlove: leftGlove, rightGlove: rightGlove)
            
            // Setup Environment Root
            let environmentRoot = Entity()
            environmentRoot.components.set(EnvironmentComponent())
            
            // Add Ambient Moonlight so clouds are visible from afar!
            let moonlight = Entity()
            var dirLight = DirectionalLightComponent(color: UIColor(white: 0.8, alpha: 1.0))
            dirLight.intensity = 800 // Soft light so clouds aren't pitch black
            moonlight.components.set(dirLight)
            moonlight.orientation = simd_quatf(angle: -.pi / 4, axis: [1, 0, 0])
            environmentRoot.addChild(moonlight)
            
            // Load base cloud model from Reality Composer Pro
            var baseCloud = Entity()
            do {
                // Load the cloud USD model
                baseCloud = try await Entity(named: "Cloud", in: realityKitContentBundle)
            } catch {
                print("Failed to load cloud.usdc from RCP: \(error)")
                // Safe fallback to sphere just in case the name is wrong
                let fallbackMaterial = SimpleMaterial(color: UIColor(white: 0.5, alpha: 0.6), isMetallic: false)
                baseCloud = ModelEntity(mesh: .generateSphere(radius: 25.0), materials: [fallbackMaterial])
            }
            
            // Add Clouds to the environment using the loaded model
            for i in 0..<40 { 
                // Using .clone(recursive: true) is extremely performant because it shares the mesh and material data across all instances!
                let cloud = baseCloud.clone(recursive: true)
                
                // Hollow tunnel logic: Ensure clouds spawn outside a 30m center radius so they rush past the windows
                // but never physically clip through the cockpit cabin!
                let isHorizontal = Bool.random()
                let cx: Float
                let cy: Float
                
                if isHorizontal {
                    // Push out to the left or right side
                    cx = Float.random(in: 30...150) * (Bool.random() ? 1 : -1)
                    cy = Float.random(in: -30...30)
                } else {
                    // Push above or below
                    cx = Float.random(in: -150...150)
                    cy = Float.random(in: 30...80) * (Bool.random() ? 1 : -1)
                }
                
                let cz = Float.random(in: -800...50)
                
                if i == 0 {
                    // Force the very first cloud to be just outside the right window
                    // so it swooshes past dramatically without clipping!
                    cloud.position = [25, 0, -50] 
                } else {
                    cloud.position = [cx, cy, cz]
                }
                
                // Add MASSIVE scale variation. If the USD model is small, this will make it massive!
                let randomScale = Float.random(in: 20.0...80.0) 
                
                // Add random rotation so the 3D model looks different from every angle
                let randomYaw = Float.random(in: 0...(2 * .pi))
                cloud.orientation = simd_quatf(angle: randomYaw, axis: [0, 1, 0])
                
                // Set CloudComponent
                let ringType: CloudComponent.RingType
                let speedMult: Float
                let spawnDist: Float
                
                if i < 15 {
                    ringType = .near
                    speedMult = 1.0
                    spawnDist = 300.0
                } else if i < 30 {
                    ringType = .mid
                    speedMult = 0.5
                    spawnDist = 600.0
                } else {
                    ringType = .far
                    speedMult = 0.05
                    spawnDist = 1000.0
                }
                
                cloud.components.set(CloudComponent(
                    ringType: ringType,
                    speedMultiplier: speedMult,
                    maxRecycleDistance: 50.0,
                    spawnRadius: spawnDist,
                    baseScale: SIMD3<Float>(repeating: randomScale)
                ))
                
                // Save target scale in tag component just in case
                cloud.components.set(CloudTagComponent(targetScale: randomScale))
                environmentRoot.addChild(cloud)
            }
            
            // Setup Lightning Light and Audio
            let lightningEntity = Entity()
            var pointLight = PointLightComponent(color: .white)
            pointLight.intensity = 0
            pointLight.attenuationRadius = 20.0
            lightningEntity.components.set(pointLight)
            
            var lightningComp = LightningComponent()
            lightningEntity.position = [0, 2, -2] // Position outside the windshield
            
            // Setup Threat Lights
            let masterWarningLeft = Entity()
            let masterWarningRight = Entity()
            let overheadAmbient = Entity()
            
            var warningLightComp = PointLightComponent(color: .red)
            warningLightComp.intensity = 0
            warningLightComp.attenuationRadius = 2.0 // Small radius for sharp specular on glare shield
            
            masterWarningLeft.components.set(warningLightComp)
            masterWarningRight.components.set(warningLightComp)
            
            var ambientLightComp = PointLightComponent(color: .red)
            ambientLightComp.intensity = 0
            ambientLightComp.attenuationRadius = 10.0
            overheadAmbient.components.set(ambientLightComp)
            
            // Positioning relative to Cockpit (approximate glare shield and overhead)
            masterWarningLeft.position = [-0.3, 0.9, -0.6]
            masterWarningRight.position = [0.3, 0.9, -0.6]
            overheadAmbient.position = [0, 1.8, 0]
            
            viewModel.rootEntity.addChild(masterWarningLeft)
            viewModel.rootEntity.addChild(masterWarningRight)
            viewModel.rootEntity.addChild(overheadAmbient)
            
            threatComp.masterWarningLightLeftID = masterWarningLeft.id
            threatComp.masterWarningLightRightID = masterWarningRight.id
            threatComp.overheadAmbientLightID = overheadAmbient.id
            
            // Load Audio Resources
            do {
                var loopConfig = AudioFileResource.Configuration()
                loopConfig.shouldLoop = true
                
                // 1. External Audio Layer (Wind, Engine, Groan)
                let windAudio = try await AudioFileResource(named: "wind.mp3", in: Bundle.module, configuration: loopConfig)
                let engineAudio = try await AudioFileResource(named: "engine_cruise.mp3", in: Bundle.module, configuration: loopConfig)
                let groanAudio = try await AudioFileResource(named: "fuselage_groan.mp3", in: Bundle.module, configuration: loopConfig)
                
                let ambientAudioEntity = Entity()
                ambientAudioEntity.components.set(SpatialAudioComponent())
                
                let windController = ambientAudioEntity.prepareAudio(windAudio)
                windController.gain = -10
                windController.play()
                
                let engineController = ambientAudioEntity.prepareAudio(engineAudio)
                engineController.gain = -5
                engineController.play() // Play from start (0-10s safe phase)
                
                let groanController = ambientAudioEntity.prepareAudio(groanAudio)
                groanController.gain = -2 // Starts stopped, ThreatSystem will play it
                
                threatComp.engineController = engineController
                threatComp.groanController = groanController
                
                viewModel.rootEntity.addChild(ambientAudioEntity)
                
                // 2. Internal Dashboard Audio Layer (Alarms)
                let alarmAudio = try await AudioFileResource(named: "alarm_crc.mp3", in: Bundle.module, configuration: loopConfig)
                let overspeedAudio = try await AudioFileResource(named: "OVERSPEED.wav", in: Bundle.module, configuration: loopConfig)
                
                let dashboardAudioEntity = Entity()
                dashboardAudioEntity.position = [0, 0.9, -0.6] // Glare shield center
                dashboardAudioEntity.components.set(SpatialAudioComponent())
                
                let alarmController = dashboardAudioEntity.prepareAudio(alarmAudio)
                alarmController.gain = 0 // Loud
                
                let overspeedController = dashboardAudioEntity.prepareAudio(overspeedAudio)
                overspeedController.gain = 2 // Very loud
                
                threatComp.alarmController = alarmController
                threatComp.overspeedController = overspeedController
                
                viewModel.rootEntity.addChild(dashboardAudioEntity)
                
                // Thunder Audio (for Lightning)
                let thunderAudio = try await AudioFileResource(named: "lighting.mp3", in: Bundle.module)
                lightningComp.thunderAudio = thunderAudio
                lightningEntity.components.set(SpatialAudioComponent())
                
            } catch {
                print("Failed to load audio resources: \(error)")
            }
            
            lightningEntity.components.set(lightningComp)
            cockpitEntity.components.set(threatComp)
            cockpitEntity.components.set(shakeComp)
            
            environmentRoot.addChild(lightningEntity)
            
            // Add the created entities to the scene
            viewModel.rootEntity.addChild(environmentRoot)
            viewModel.rootEntity.addChild(cockpitEntity)
            viewModel.rootEntity.addChild(handsEntity)
            content.add(viewModel.rootEntity)
            
            // 3. Sync ECS State to SwiftUI ViewModel
            let subscription = content.subscribe(to: SceneEvents.Update.self) { event in
                if let handComp = handsEntity.components[HandModelComponent.self] {
                    viewModel.leftFingerStatus = handComp.leftFingerStatus
                    viewModel.rightFingerStatus = handComp.rightFingerStatus
                }
                if let cockpitComp = cockpitEntity.components[CockpitComponent.self] {
                    viewModel.isSidestickGrabbed = cockpitComp.isSidestickGrabbed
                    viewModel.isThrottleGrabbed = cockpitComp.isThrottleGrabbed
                    viewModel.sidestickDisplacement = cockpitComp.normalizedDisplacement
                    viewModel.throttleValue = cockpitComp.throttleValue
                }
            }
            
            return subscription
            
        } catch {
            print("Failed to load ImmersiveCockpit: \(error)")
            return nil
        }
    }
    
    private static func loadGloveModel(named name: String) async -> ModelEntity? {
        if let url = Bundle.module.url(forResource: name, withExtension: "usdz") {
            do {
                let glove = try await ModelEntity(contentsOf: url)
                let expectedJointCount = HandSkeleton.JointName.allCases.count
                if glove.jointNames.count != expectedJointCount {
                    print("Joint count mismatch for \(name)")
                }
                return glove
            } catch {
                print("Failed to load \(name): \(error)")
                return nil
            }
        } else {
            print("Failed to find \(name).usdz in Bundle.module")
            return nil
        }
    }
}
