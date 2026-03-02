import SwiftUI
import SpriteKit

struct ContentView: View {
    private let scene: GameScene = {
        let scene = GameScene(size: CGSize(width: 400, height: 600))
        scene.scaleMode = .aspectFill
        return scene
    }()

    var body: some View {
        SpriteView(scene: scene)
            .ignoresSafeArea()
            .frame(minWidth: 300, minHeight: 450)
    }
}
