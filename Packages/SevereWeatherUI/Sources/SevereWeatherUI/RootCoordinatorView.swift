import SwiftUI
import SevereWeatherShared
import RealityKitContent

public struct RootCoordinatorView: View {
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    
    var coordinator: AppCoordinator
    
    public init(coordinator: AppCoordinator) {
        self.coordinator = coordinator
    }
    
    public var body: some View {
        ZStack {
            if coordinator.currentRoute == .intro {
                IntroView(coordinator: coordinator)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            } else {
                // When immersive is active, we can show a minimal HUD or empty view
                // since the main content is in the ImmersiveSpace
                VStack {
                    Spacer()
                    Button("Exit Simulation") {
                        coordinator.backToIntro()
                    }
                    .padding()
                    .glassBackgroundEffect()
                }
                .padding(.bottom, 40)
            }
        }
        .animation(.spring(duration: 0.5), value: coordinator.currentRoute)
        .onChange(of: coordinator.currentRoute) { _, newRoute in
            Task {
                if newRoute == .immersive {
                    await openImmersiveSpace(id: "ImmersiveSpace")
                } else if newRoute == .intro {
                    await dismissImmersiveSpace()
                }
            }
        }
    }
}
