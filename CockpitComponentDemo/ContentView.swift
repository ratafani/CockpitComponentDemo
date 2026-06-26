//
//  ContentView.swift
//  CockpitComponentDemo
//
//  Created by Muhammad Tafani Rabbani on 26/06/26.
//

import SwiftUI
import RealityKit

struct ContentView: View {

    var body: some View {
        VStack {
            ToggleImmersiveSpaceButton()
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
