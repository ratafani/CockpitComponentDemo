import SwiftUI

public struct ThrottleStatusView: View {
    var throttleValue: Float // 0.0 to 1.0

    public init(throttleValue: Float) {
        self.throttleValue = throttleValue
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            // Track background
            RoundedRectangle(cornerRadius: 10)
                .fill(.white.opacity(0.2))
                .frame(width: 40, height: 160)
            
            // Fill level
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [.green, .yellow, .red]),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .frame(width: 40, height: max(10, CGFloat(throttleValue) * 160))
                .animation(.linear(duration: 0.1), value: throttleValue)
            
            // Indicator Line
            Rectangle()
                .fill(.white)
                .frame(width: 60, height: 4)
                .offset(y: -CGFloat(throttleValue) * 160 + (throttleValue > 0 ? 8 : 0))
        }
        .frame(width: 80, height: 180)
        .padding(16)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }
}
