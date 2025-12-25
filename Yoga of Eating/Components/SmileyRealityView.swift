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

            // Add Mouth (Curved smile using arc of spheres)
            let mouthContainer = Entity()
            mouthContainer.name = "MouthContainer"
            let mouthSpheres = self.createSmileMouth(for: self.state.mood)
            for sphere in mouthSpheres {
                mouthContainer.addChild(sphere)
            }
            smileyEntity.addChild(mouthContainer)

            // Add to the 3D scene
            content.add(smileyEntity)

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

                // Update mouth shape based on mood
                if let mouthContainer = model.findEntity(named: "MouthContainer") {
                    // Remove old mouth spheres
                    mouthContainer.children.removeAll()

                    // Add new mouth spheres for current mood
                    let newMouthSpheres = self.createSmileMouth(for: self.state.mood)
                    for sphere in newMouthSpheres {
                        mouthContainer.addChild(sphere)
                    }
                }
            }
        }
    }

    /// Creates a curved mouth using an arc of small spheres
    private func createSmileMouth(for mood: SmileyMood) -> [ModelEntity] {
        let mouthMesh = MeshResource.generateSphere(radius: 0.025)
        let mouthMaterial = SimpleMaterial(color: .black, isMetallic: false)

        var spheres: [ModelEntity] = []
        let numberOfSpheres = 9
        let radius: Float = 0.15
        let centerY: Float = -0.15
        let centerZ: Float = 0.35

        // Define arc angles based on mood
        let (startAngle, endAngle): (Float, Float) = switch mood {
        case .serene:
            // Smile: upward curve
            (-150.0 * .pi / 180.0, -30.0 * .pi / 180.0)
        case .neutral:
            // Neutral: straight line
            (180.0 * .pi / 180.0, 0.0 * .pi / 180.0)
        case .overwhelmed:
            // Frown: downward curve
            (30.0 * .pi / 180.0, 150.0 * .pi / 180.0)
        }

        // Create spheres along the arc
        for index in 0..<numberOfSpheres {
            let progress = Float(index) / Float(numberOfSpheres - 1)
            let angle = startAngle + (endAngle - startAngle) * progress

            let posX = radius * cos(angle)
            let posY = centerY + radius * sin(angle)
            let posZ = centerZ

            let sphere = ModelEntity(mesh: mouthMesh, materials: [mouthMaterial])
            sphere.position = [posX, posY, posZ]
            spheres.append(sphere)
        }

        return spheres
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
