import RealityKit
import Foundation

public struct LightningComponent: Component {
    /// The maximum intensity of the lightning flash
    public var maxIntensity: Float = 50000.0 // Adjusted for PointLight in RealityKit
    
    /// The base intensity (usually 0, meaning off)
    public var baseIntensity: Float = 0.0
    
    /// Current flashing state
    public var isFlashing: Bool = false
    
    /// Timer for controlling the sequence of flashes (a lightning strike often has multiple quick flashes)
    public var flashTimer: TimeInterval = 0
    public var flashSequence: [TimeInterval] = []
    public var currentSequenceIndex: Int = 0
    
    /// Countdown to the next lightning strike
    public var nextStrikeTimer: TimeInterval = 0
    
    /// Audio resources
    public var thunderAudio: AudioFileResource?
    public var playbackController: AudioPlaybackController?
    
    public init() {
        self.nextStrikeTimer = TimeInterval.random(in: 4...12)
    }
}
