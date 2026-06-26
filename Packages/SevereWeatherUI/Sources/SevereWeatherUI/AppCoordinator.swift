import SwiftUI
import RealityKit

public enum AppRoute: Hashable {
    case intro
    case immersive
}

@MainActor
@Observable
public class AppCoordinator {
    public var currentRoute: AppRoute = .intro
    
    public init() {}
    
    public func startSimulation() {
        currentRoute = .immersive
    }
    
    public func backToIntro() {
        currentRoute = .intro
    }
}
