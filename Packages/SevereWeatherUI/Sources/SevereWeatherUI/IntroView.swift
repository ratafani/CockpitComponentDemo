import SwiftUI

public struct IntroView: View {
    var coordinator: AppCoordinator
    
    public init(coordinator: AppCoordinator) {
        self.coordinator = coordinator
    }
    
    public var body: some View {
        VStack(spacing: 40) {
            VStack(spacing: 16) {
                Text("SEVERE WEATHER EVASION")
                    .font(.system(size: 48, weight: .black, design: .default))
                    .foregroundStyle(.primary)
                    .tracking(2)
                
                Text("Prepare to navigate through extreme turbulence.")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button {
                withAnimation {
                    coordinator.startSimulation()
                }
            } label: {
                Text("START SIMULATOR")
                    .font(.title3.bold())
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.plain)
            .background(
                Capsule()
                    .fill(Color.accentColor)
                    .shadow(color: .accentColor.opacity(0.3), radius: 10, x: 0, y: 5)
            )
            .foregroundStyle(.white)
            .hoverEffect()
        }
        .padding(64)
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 32, style: .continuous))
    }
}

#Preview {
    IntroView(coordinator: AppCoordinator())
}
