import SwiftUI
import simd

public struct SidestickCompassView: View {
    var displacement: SIMD2<Float> // -1.0 to 1.0

    public init(displacement: SIMD2<Float>) {
        self.displacement = displacement
    }

    public var body: some View {
        ZStack {
            // Outer Ring
            Circle()
                .strokeBorder(.white.opacity(0.5), lineWidth: 3)
            
            // Crosshairs
            Rectangle()
                .fill(.white.opacity(0.3))
                .frame(width: 1, height: 120)
            
            Rectangle()
                .fill(.white.opacity(0.3))
                .frame(width: 120, height: 1)
            
            // Current Position Indicator
            Circle()
                .fill(.green)
                .frame(width: 24, height: 24)
                .shadow(color: .green, radius: 5, x: 0, y: 0)
                // In SwiftUI, -y is up.
                // displacement.x is left/right. displacement.y is forward/back.
                // If y is positive (forward), it should go up visually (reversed according to user request).
                .offset(x: CGFloat(displacement.x * 50), y: CGFloat(displacement.y * 50))
        }
        .frame(width: 120, height: 120)
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(Circle())
    }
}
