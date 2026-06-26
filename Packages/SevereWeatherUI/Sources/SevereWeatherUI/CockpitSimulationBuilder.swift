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
        
        CockpitCalibrationSystem.registerSystem()
        HandTrackingSystem.registerSystem()
        CockpitInteractionSystem.registerSystem()
        
        // 2. Load the immersive cockpit scene and create ECS entities
        do {
            let immersiveCockpit = try await Entity(named: "ImmersiveCockpit", in: realityKitContentBundle)
            let cockpitEntity = CockpitEntity(immersiveCockpit: immersiveCockpit)
            
            // Load Hands
            async let leftGloveTask = loadGloveModel(named: "LeftGlove")
            async let rightGloveTask = loadGloveModel(named: "RightGlove")
            let (leftGlove, rightGlove) = await (leftGloveTask, rightGloveTask)
            
            let handsEntity = HandsEntity(leftGlove: leftGlove, rightGlove: rightGlove)
            
            // Add the created entities to the scene
            viewModel.rootEntity.addChild(cockpitEntity)
            viewModel.rootEntity.addChild(handsEntity)
            content.add(viewModel.rootEntity)
            
            // 3. Sync ECS State to SwiftUI ViewModel (Example)
            let subscription = content.subscribe(to: SceneEvents.Update.self) { event in
                if let handComp = handsEntity.components[HandModelComponent.self] {
                    viewModel.leftFingerStatus = handComp.leftFingerStatus
                    viewModel.rightFingerStatus = handComp.rightFingerStatus
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
