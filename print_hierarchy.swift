import Foundation
import RealityKit

let url = URL(fileURLWithPath: "/Volumes/Taftaf Personal/VisionOS Training/Airbus Proj/CockpitComponentDemo/Packages/RealityKitContent/Sources/RealityKitContent/RealityKitContent.rkassets/ImmersiveCockpit.usda")

func printHierarchy(_ entity: Entity, indent: String = "") {
    var info = "\(indent)- \(entity.name) [\(type(of: entity))]"
    if let model = entity as? ModelEntity {
        info += " (joints: \(model.jointNames.count))"
        if !model.jointNames.isEmpty {
            info += " \(model.jointNames)"
        }
    }
    print(info)
    for child in entity.children {
        printHierarchy(child, indent: indent + "  ")
    }
}

let group = DispatchGroup()
group.enter()

Task { @MainActor in
    do {
        let entity = try await Entity(contentsOf: url)
        if let s2 = entity.findEntity(named: "Sidestick2") {
             printHierarchy(s2)
        } else {
             printHierarchy(entity)
        }
    } catch {
        print("Failed to load: \(error)")
    }
    group.leave()
}

RunLoop.main.run(until: Date(timeIntervalSinceNow: 5.0))
