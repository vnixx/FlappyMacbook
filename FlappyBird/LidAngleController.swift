import Foundation
import AppleSiliconSensor

final class LidAngleController {

    private var sensorManager: SensorManager?
    private var token: Any?

    private let minAngle: Float = 30
    private let maxAngle: Float = 90

    private(set) var normalizedAngle: CGFloat = 0.5
    private(set) var rawAngle: Float = 80

    var isAvailable: Bool { sensorManager != nil }

    init() {
        do {
            let manager = SensorManager()
            token = manager.onLidAngle { [weak self] data in
                let angle = data.angle
                guard let self else { return }
                let clamped = min(max(angle, self.minAngle), self.maxAngle)
                let norm = CGFloat((clamped - self.minAngle) / (self.maxAngle - self.minAngle))
                DispatchQueue.main.async { [weak self] in
                    self?.rawAngle = angle
                    self?.normalizedAngle = norm
                }
            }
            try manager.start()
            sensorManager = manager
        } catch {
            print("[LidAngleController] Sensor unavailable: \(error)")
            sensorManager = nil
            token = nil
        }
    }

    deinit {
        sensorManager?.stop()
    }
}
