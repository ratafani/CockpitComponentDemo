import RealityKit
import ARKit
import QuartzCore
import ILSFoundation
import ILSEngine
import ILSHandTracking

public class CockpitCalibrationSystem: System {
    private var isCalibrated = false
    private let arkitSession = ARKitSession()
    private let worldTracking = WorldTrackingProvider()
    
    public required init(scene: RealityKit.Scene) {
        
        Task {
            do {
                if WorldTrackingProvider.isSupported {
                    try await arkitSession.run([worldTracking])
                }
            } catch {
                print("Failed to start ARKitSession for calibration: \(error)")
            }
        }
    }
    
    public func update(context: SceneUpdateContext) {
        guard !isCalibrated,
              worldTracking.state == .running,
              let deviceAnchor = worldTracking.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()) else {
            return
        }
        
        let cockpitEntities = context.scene.performQuery(Self.cockpitQuery)
        for entity in cockpitEntities {
            // deviceAnchor.originFromAnchorTransform gives the transform of the device (head) in world space
            let headTransform = Transform(matrix: deviceAnchor.originFromAnchorTransform)
            
            // The 0,0,0 of the model is already the head position.
            // So we just set the cockpit's position and orientation to match the user's head at startup,
            // but we might only want to match the position, and perhaps the Y-axis rotation (yaw),
            // keeping pitch and roll level.
            
            var eulerAngles = headTransform.rotation.eulerAngles
            // Keep pitch and roll 0 to ensure the cockpit is level with the ground
            eulerAngles.x = 0
            eulerAngles.z = 0
            
            entity.position = headTransform.translation
            // Tambahkan .pi (180 derajat) agar menghadap searah dengan user
            entity.orientation = simd_quatf(angle: eulerAngles.y + .pi, axis: [0, 1, 0])
            // Kurangi ukuran lebih jauh lagi (scale = 0.56)
            entity.scale = SIMD3<Float>(repeating: 0.56)
            
            isCalibrated = true
            print("Cockpit calibrated to head position: \(entity.position)")
        }
    }
    
    private static let cockpitQuery = EntityQuery(where: .has(CockpitComponent.self))
}

// Helper extension to get euler angles
extension simd_quatf {
    var eulerAngles: SIMD3<Float> {
        let ysqr = imag.y * imag.y
        let t0 = +2.0 * (real * imag.x + imag.y * imag.z)
        let t1 = +1.0 - 2.0 * (imag.x * imag.x + ysqr)
        let pitch = atan2(t0, t1)
        
        var t2 = +2.0 * (real * imag.y - imag.z * imag.x)
        t2 = t2 > 1.0 ? 1.0 : t2
        t2 = t2 < -1.0 ? -1.0 : t2
        let yaw = asin(t2)
        
        let t3 = +2.0 * (real * imag.z + imag.x * imag.y)
        let t4 = +1.0 - 2.0 * (ysqr + imag.z * imag.z)
        let roll = atan2(t3, t4)
        
        return SIMD3<Float>(pitch, yaw, roll)
    }
}
