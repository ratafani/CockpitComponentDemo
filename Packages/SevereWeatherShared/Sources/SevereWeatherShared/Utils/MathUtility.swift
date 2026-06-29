import Foundation
import simd

public struct MathUtility {
    
    /// Generates a random coordinate within a forward-facing cone (-Z direction).
    /// - Parameters:
    ///   - radius: The distance from the origin (0,0,0).
    ///   - azimuthRange: The range of yaw angles (in radians). 0 is forward, positive is right (+X), negative is left (-X).
    ///   - elevationRange: The range of pitch angles (in radians). 0 is horizontal, positive is up (+Y), negative is down (-Y).
    /// - Returns: A Cartesian coordinate (SIMD3<Float>) relative to the origin.
    public static func randomCoordinateInForwardCone(
        radius: Float,
        azimuthRange: ClosedRange<Float>,
        elevationRange: ClosedRange<Float>
    ) -> SIMD3<Float> {
        let randomAzimuth = Float.random(in: azimuthRange)
        let randomElevation = Float.random(in: elevationRange)
        
        let cosElevation = cos(randomElevation)
        
        let x = radius * cosElevation * sin(randomAzimuth)
        let y = radius * sin(randomElevation)
        let z = -radius * cosElevation * cos(randomAzimuth)
        
        return SIMD3<Float>(x, y, z)
    }
}
