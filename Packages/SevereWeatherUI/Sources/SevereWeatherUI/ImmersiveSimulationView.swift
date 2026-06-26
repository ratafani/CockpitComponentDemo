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
            subscription = await CockpitSimulationBuilder.setupWorld(content: content, viewModel: viewModel)
        } update: { content, attachments in
            if let attachmentEntity = attachments.entity(for: "FingerStatus") {
                if attachmentEntity.parent == nil {
                    attachmentEntity.position = [0, 1.3, -0.8]
                    viewModel.rootEntity.addChild(attachmentEntity)
                }
            }
        } attachments: {
            Attachment(id: "FingerStatus") {
                FingerStatusView(viewModel: viewModel)
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

struct FingerStatusView: View {
    var viewModel: CockpitViewModel
    
    var body: some View {
        HStack(spacing: 40) {
            HandStatusView(title: "Left Hand", statuses: viewModel.leftFingerStatus)
            HandStatusView(title: "Right Hand", statuses: viewModel.rightFingerStatus)
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }
}

struct HandStatusView: View {
    let title: String
    let statuses: [Bool]
    let fingerNames = ["Index", "Middle", "Ring", "Little"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.title3).bold()
            ForEach(0..<4, id: \.self) { i in
                HStack {
                    Text(fingerNames[i])
                        .font(.body)
                    Spacer()
                    Image(systemName: statuses[i] ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(statuses[i] ? .green : .red)
                        .font(.title2)
                }
            }
        }
        .frame(width: 160)
    }
}
