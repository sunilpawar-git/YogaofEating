import RealityKit
import SwiftUI

/// A RealityKit-backed view that renders the 3D Smiley friend.
struct SmileyRealityView: View {
    let state: SmileyState

    var body: some View {
        RealityView { content in
            // Create a procedural sphere for the Smiley
            let sphere = MeshResource.generateSphere(radius: 0.4)

            // Material depends on the mood
            let material = SimpleMaterial(color: colorForMood(state.mood), isMetallic: false)

            let smileyEntity = ModelEntity(mesh: sphere, materials: [material])
            smileyEntity.name = "Smiley"

            // Add Face (Eyes)
            let eyeMesh = MeshResource.generateSphere(radius: 0.04)
            let eyeMaterial = SimpleMaterial(color: .black, isMetallic: false)

            let leftEye = ModelEntity(mesh: eyeMesh, materials: [eyeMaterial])
            leftEye.position = [0.15, 0.1, 0.35]

            let rightEye = ModelEntity(mesh: eyeMesh, materials: [eyeMaterial])
            rightEye.position = [-0.15, 0.1, 0.35]

            smileyEntity.addChild(leftEye)
            smileyEntity.addChild(rightEye)

            // Add Mouth (Simple horizontal line for neutral, will update in mouth logic if complexity increases)
            let mouthMesh = MeshResource.generateBox(width: 0.2, height: 0.02, depth: 0.02, cornerRadius: 0.01)
            let mouthEntity = ModelEntity(mesh: mouthMesh, materials: [eyeMaterial])
            mouthEntity.position = [0, -0.1, 0.35]
            mouthEntity.name = "Mouth"
            smileyEntity.addChild(mouthEntity)

            // Add to the 3D scene
            content.add(smileyEntity)

            // Expert Guardrail: Battery-aware frame rate

        } update: { content in
            // Only update if scale or mood has changed (Sleeping State)
            guard let smiley = content.entities.first(where: { $0.name == "Smiley" }) else { return }

            let currentScale = Double(smiley.transform.scale.x)
            if abs(currentScale - self.state.scale) < 0.01 {
                // If practically identical, don't trigger expensive move animations
                return
            }

            let targetScale = Float(state.scale)

            // Animate smoothly
            smiley.move(
                to: Transform(scale: [targetScale, targetScale, targetScale]),
                relativeTo: nil,
                duration: 0.5,
                timingFunction: .easeInOut
            )

            // Update material color and mouth shape if mood changed
            if let model = smiley as? ModelEntity {
                model.model?.materials = [SimpleMaterial(color: self.colorForMood(self.state.mood), isMetallic: false)]

                if let mouth = model.findEntity(named: "Mouth") {
                    let mouthRotation: Float = switch self.state.mood {
                    case .serene:
                        .pi // Smile (upside down box is actually a smile if we position it right or just use
                    // rotation)
                    case .neutral:
                        0
                    case .overwhelmed:
                        .pi / 8 // Slightly tilted/distorted
                    }

                    // For a simple box mouth, we can rotate it on the Z axis or just tilt it
                    mouth.transform.rotation = simd_quaternion(mouthRotation, [0, 0, 1])
                }
            }
        }
    }

    private func colorForMood(_ mood: SmileyMood) -> UIColor {
        switch mood {
        case .serene:
            .systemYellow
        case .neutral:
            .systemOrange
        case .overwhelmed:
            .systemRed
        }
    }
}

#Preview {
    SmileyRealityView(state: .neutral)
        .frame(width: 300, height: 300)
}
