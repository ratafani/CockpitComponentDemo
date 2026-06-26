//
//  CockpitComponentDemoApp.swift
//  CockpitComponentDemo
//
//  Created by Muhammad Tafani Rabbani on 26/06/26.
//

import SwiftUI
import SevereWeatherUI

@main
struct CockpitComponentDemoApp: App {
    
    @State private var coordinator = AppCoordinator()
    
    var body: some Scene {
        WindowGroup {
            RootCoordinatorView(coordinator: coordinator)
        }
        .windowStyle(.plain) // Use plain window style for a cleaner look with glass background
        
        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveSimulationView()
        }
        .immersionStyle(selection: .constant(.full), in: .full)
        .upperLimbVisibility(.hidden)
    }
}
