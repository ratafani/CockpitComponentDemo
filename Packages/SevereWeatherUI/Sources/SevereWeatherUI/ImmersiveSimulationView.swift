import SwiftUI
import RealityKit
import RealityKitContent
import SevereWeatherShared
import ILSHandTracking

public struct ImmersiveSimulationView: View {
    @State private var viewModel = CockpitViewModel()
    @State private var subscription: EventSubscription?
    
    public init() {}
    
    public var body: some View {
        RealityView { content, attachments in
            print("[Attachments] 🛠️ RealityView make closure started.")
            
            // Create a head anchor so UI follows the user's gaze
            let headAnchor = AnchorEntity(.head)
            headAnchor.name = "HeadAnchor"
            content.add(headAnchor)
            
            subscription = await CockpitSimulationBuilder.setupWorld(content: content, viewModel: viewModel)
            
            if let compassEntity = attachments.entity(for: "SidestickCompass") {
                // Position closer to center-left
                compassEntity.position = [-0.15, -0.1, -0.5] 
                headAnchor.addChild(compassEntity)
            }
            
            if let throttleEntity = attachments.entity(for: "ThrottleStatus") {
                // Position closer to center-right
                throttleEntity.position = [0.15, -0.1, -0.5] 
                headAnchor.addChild(throttleEntity)
            }
        } update: { content, attachments in
            let headAnchor = content.entities.first { $0.name == "HeadAnchor" }
            
            if let compassEntity = attachments.entity(for: "SidestickCompass"), let head = headAnchor {
                if compassEntity.parent != head {
                    compassEntity.position = [-0.15, -0.1, -0.5] 
                    head.addChild(compassEntity)
                }
            }
            
            if let throttleEntity = attachments.entity(for: "ThrottleStatus"), let head = headAnchor {
                if throttleEntity.parent != head {
                    throttleEntity.position = [0.15, -0.1, -0.5] 
                    head.addChild(throttleEntity)
                }
            }

        } attachments: {
            Attachment(id: "SidestickCompass") {
                SidestickCompassView(displacement: viewModel.sidestickDisplacement)
                    .opacity(viewModel.isSidestickGrabbed ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.isSidestickGrabbed)
            }
            Attachment(id: "ThrottleStatus") {
                ThrottleStatusView(throttleValue: viewModel.throttleValue)
                    .opacity(viewModel.isThrottleGrabbed ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.isThrottleGrabbed)
            }
        }
        .task {
            do {
                try await HandTrackingService.shared.start()
            } catch {
                print("Failed to start hand tracking: \(error)")
            }
        }
        .onDisappear {
            subscription?.cancel()
            viewModel.cleanupScene()
        }
    }
}
