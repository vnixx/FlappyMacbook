import SpriteKit
import AppKit

class GameScene: SKScene {

    // MARK: - Types

    private enum GameState {
        case waitingToStart
        case playing
        case gameOver
    }

    // MARK: - Configuration

    private let verticalPipeGap: CGFloat = 150.0
    private let lerpFactor: CGFloat = 0.3
    private let pipeSpawnInterval: TimeInterval = 2.0

    // MARK: - Nodes

    private var bird: SKSpriteNode!
    private var moving: SKNode!
    private var pipes: SKNode!
    private var scoreLabelNode: SKLabelNode!
    private var statusLabel: SKLabelNode!
    private var instructionLabel: SKLabelNode!

    // MARK: - Textures

    private var pipeTextureUp: SKTexture!
    private var pipeTextureDown: SKTexture!
    private var groundTexture: SKTexture!
    private var movePipesAndRemove: SKAction!
    private var skyColor: SKColor!

    // MARK: - Game State

    private var state: GameState = .waitingToStart
    private var score = 0
    private var currentBirdY: CGFloat = 0
    private var groundHeight: CGFloat = 0
    private var birdXPosition: CGFloat = 0

    // MARK: - Input

    private let lidAngleController = LidAngleController()
    private var useMouseFallback = false
    private var mouseNormalizedY: CGFloat = 0.5
    private var mouseEventMonitor: Any?

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        skyColor = SKColor(red: 81.0 / 255.0, green: 192.0 / 255.0, blue: 201.0 / 255.0, alpha: 1.0)
        backgroundColor = skyColor

        moving = SKNode()
        addChild(moving)
        pipes = SKNode()
        moving.addChild(pipes)

        birdXPosition = frame.width * 0.35

        setupBackground()
        setupBird()
        setupLabels()

        useMouseFallback = !lidAngleController.isAvailable
        currentBirdY = frame.midY

        if useMouseFallback {
            setupMouseTracking()
        }

        showInstructions()
    }

    override func willMove(from view: SKView) {
        if let monitor = mouseEventMonitor {
            NSEvent.removeMonitor(monitor)
            mouseEventMonitor = nil
        }
    }

    // MARK: - Setup

    private func setupBackground() {
        groundTexture = SKTexture(imageNamed: "land")
        groundTexture.filteringMode = .nearest
        groundHeight = groundTexture.size().height * 2

        let moveGround = SKAction.moveBy(
            x: -groundTexture.size().width * 2, y: 0,
            duration: TimeInterval(0.02 * groundTexture.size().width * 2))
        let resetGround = SKAction.moveBy(
            x: groundTexture.size().width * 2, y: 0, duration: 0)
        let moveForever = SKAction.repeatForever(.sequence([moveGround, resetGround]))

        let groundTileCount = 2 + Int(frame.width / (groundTexture.size().width * 2))
        for i in 0..<groundTileCount {
            let sprite = SKSpriteNode(texture: groundTexture)
            sprite.setScale(2.0)
            sprite.position = CGPoint(
                x: CGFloat(i) * sprite.size.width,
                y: sprite.size.height / 2.0)
            sprite.run(moveForever)
            moving.addChild(sprite)
        }

        let skyTexture = SKTexture(imageNamed: "sky")
        skyTexture.filteringMode = .nearest

        let moveSky = SKAction.moveBy(
            x: -skyTexture.size().width * 2, y: 0,
            duration: TimeInterval(0.1 * skyTexture.size().width * 2))
        let resetSky = SKAction.moveBy(
            x: skyTexture.size().width * 2, y: 0, duration: 0)
        let moveSkyForever = SKAction.repeatForever(.sequence([moveSky, resetSky]))

        let skyTileCount = 2 + Int(frame.width / (skyTexture.size().width * 2))
        for i in 0..<skyTileCount {
            let sprite = SKSpriteNode(texture: skyTexture)
            sprite.setScale(2.0)
            sprite.zPosition = -20
            sprite.position = CGPoint(
                x: CGFloat(i) * sprite.size.width,
                y: sprite.size.height / 2.0 + groundHeight)
            sprite.run(moveSkyForever)
            moving.addChild(sprite)
        }

        pipeTextureUp = SKTexture(imageNamed: "PipeUp")
        pipeTextureUp.filteringMode = .nearest
        pipeTextureDown = SKTexture(imageNamed: "PipeDown")
        pipeTextureDown.filteringMode = .nearest

        let distance = frame.width + 2 * pipeTextureUp.size().width
        let movePipes = SKAction.moveBy(
            x: -distance, y: 0,
            duration: TimeInterval(0.01 * distance))
        movePipesAndRemove = .sequence([movePipes, .removeFromParent()])
    }

    private func setupBird() {
        let birdTexture1 = SKTexture(imageNamed: "bird-01")
        birdTexture1.filteringMode = .nearest
        let birdTexture2 = SKTexture(imageNamed: "bird-02")
        birdTexture2.filteringMode = .nearest

        let flap = SKAction.repeatForever(
            .animate(with: [birdTexture1, birdTexture2], timePerFrame: 0.2))

        bird = SKSpriteNode(texture: birdTexture1)
        bird.setScale(2.0)
        bird.position = CGPoint(x: birdXPosition, y: frame.midY)
        bird.zPosition = 10
        bird.run(flap)
        addChild(bird)
    }

    private func setupLabels() {
        scoreLabelNode = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        scoreLabelNode.position = CGPoint(x: frame.midX, y: frame.height * 0.75)
        scoreLabelNode.zPosition = 100
        scoreLabelNode.fontSize = 36
        scoreLabelNode.text = "0"
        addChild(scoreLabelNode)

        statusLabel = SKLabelNode(fontNamed: "Helvetica")
        statusLabel.position = CGPoint(x: frame.midX, y: frame.height - 24)
        statusLabel.zPosition = 100
        statusLabel.fontSize = 12
        statusLabel.fontColor = .white
        addChild(statusLabel)

        instructionLabel = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        instructionLabel.position = CGPoint(x: frame.midX, y: frame.midY + 100)
        instructionLabel.zPosition = 100
        instructionLabel.fontSize = 20
        instructionLabel.numberOfLines = 3
        instructionLabel.verticalAlignmentMode = .center
        addChild(instructionLabel)
    }

    private func setupMouseTracking() {
        mouseEventMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.mouseMoved, .leftMouseDragged]
        ) { [weak self] event in
            guard let self, let view = self.view else { return event }
            let locationInView = view.convert(event.locationInWindow, from: nil)
            let locationInScene = self.convertPoint(fromView: locationInView)
            self.mouseNormalizedY = max(0, min(1, locationInScene.y / self.frame.height))
            return event
        }
    }

    // MARK: - Game Flow

    private func showInstructions() {
        state = .waitingToStart
        pipes.removeAllChildren()
        pipes.removeAction(forKey: "spawn")
        score = 0
        scoreLabelNode.text = "0"
        moving.speed = 1
        bird.speed = 1
        bird.zRotation = 0

        if useMouseFallback {
            instructionLabel.text = "Move mouse to control height\nClick to start"
            statusLabel.text = "Sensor unavailable — Mouse mode"
        } else {
            instructionLabel.text = "Open/close the lid to fly!\nClick to start"
            statusLabel.text = "Lid angle sensor active"
        }
        instructionLabel.isHidden = false
    }

    private func startGame() {
        state = .playing
        instructionLabel.isHidden = true

        let spawn = SKAction.run { [weak self] in self?.spawnPipes() }
        let delay = SKAction.wait(forDuration: pipeSpawnInterval)
        pipes.run(.repeatForever(.sequence([spawn, delay])), withKey: "spawn")
    }

    private func gameOver() {
        guard state == .playing else { return }
        state = .gameOver

        moving.speed = 0
        bird.speed = 0
        pipes.removeAction(forKey: "spawn")

        instructionLabel.text = "Game Over!\nScore: \(score)\nClick to restart"
        instructionLabel.isHidden = false

        removeAction(forKey: "flash")
        run(.sequence([
            .repeat(.sequence([
                .run { [weak self] in self?.backgroundColor = SKColor.red },
                .wait(forDuration: 0.05),
                .run { [weak self] in
                    if let color = self?.skyColor { self?.backgroundColor = color }
                },
                .wait(forDuration: 0.05),
            ]), count: 4),
        ]), withKey: "flash")
    }

    // MARK: - Pipe Management

    private func spawnPipes() {
        let pipePair = SKNode()
        pipePair.position = CGPoint(
            x: frame.width + pipeTextureUp.size().width * 2, y: 0)
        pipePair.zPosition = 1

        let height = UInt32(frame.height / 4)
        let y = CGFloat(arc4random_uniform(height) + height)

        let pipeDown = SKSpriteNode(texture: pipeTextureDown)
        pipeDown.setScale(2.0)
        pipeDown.position = CGPoint(
            x: 0, y: y + pipeDown.size.height + verticalPipeGap)
        pipeDown.name = "pipe"
        pipePair.addChild(pipeDown)

        let pipeUp = SKSpriteNode(texture: pipeTextureUp)
        pipeUp.setScale(2.0)
        pipeUp.position = CGPoint(x: 0, y: y)
        pipeUp.name = "pipe"
        pipePair.addChild(pipeUp)

        pipePair.run(movePipesAndRemove)
        pipes.addChild(pipePair)
    }

    // MARK: - Collision & Scoring

    private func checkCollisions() {
        let birdRadius = bird.size.height / 2.0
        let birdRect = CGRect(
            x: bird.position.x - birdRadius,
            y: bird.position.y - birdRadius,
            width: birdRadius * 2, height: birdRadius * 2)

        let birdVisualH = bird.size.height * bird.yScale
        if bird.position.y - birdVisualH / 2 <= groundHeight {
            gameOver()
            return
        }

        for pipePair in pipes.children {
            for child in pipePair.children {
                guard let pipe = child as? SKSpriteNode, pipe.name == "pipe" else { continue }

                let center = pipe.convert(CGPoint.zero, to: self)
                let pipeRect = CGRect(
                    x: center.x - pipe.size.width / 2,
                    y: center.y - pipe.size.height / 2,
                    width: pipe.size.width, height: pipe.size.height)

                if pipeRect.intersects(birdRect) {
                    gameOver()
                    return
                }
            }
        }
    }

    private func checkScoring() {
        for pipePair in pipes.children {
            guard pipePair.userData?["scored"] == nil else { continue }

            let worldX = pipePair.convert(CGPoint.zero, to: self).x
            let pipeWidth = pipeTextureUp.size().width * 2

            if worldX + pipeWidth < bird.position.x {
                pipePair.userData = pipePair.userData ?? NSMutableDictionary()
                pipePair.userData?["scored"] = true

                score += 1
                scoreLabelNode.text = String(score)
                scoreLabelNode.run(.sequence([
                    .scale(to: 1.5, duration: 0.1),
                    .scale(to: 1.0, duration: 0.1),
                ]))
            }
        }
    }

    // MARK: - Update

    override func update(_ currentTime: TimeInterval) {
        let normalized: CGFloat = useMouseFallback
            ? mouseNormalizedY
            : lidAngleController.normalizedAngle

        let margin = bird.size.height * bird.yScale
        let playableMin = groundHeight + margin / 2
        let playableMax = frame.height - margin / 2
        let targetBirdY = playableMin + normalized * (playableMax - playableMin)

        currentBirdY = currentBirdY * (1 - lerpFactor) + targetBirdY * lerpFactor
        bird.position = CGPoint(x: birdXPosition, y: currentBirdY)

        let delta = targetBirdY - currentBirdY
        bird.zRotation = min(max(-0.4, delta * 0.015), 0.3)

        if useMouseFallback {
            statusLabel.text = "Mouse: \(Int(normalized * 100))%"
        } else {
            statusLabel.text = String(format: "Lid: %.0f°", lidAngleController.rawAngle)
        }

        guard state == .playing else { return }
        checkCollisions()
        checkScoring()
    }

    // MARK: - Input Events

    override func mouseDown(with event: NSEvent) {
        switch state {
        case .waitingToStart:
            startGame()
        case .gameOver:
            showInstructions()
        case .playing:
            break
        }
    }

    override func keyDown(with event: NSEvent) {
        guard event.keyCode == 49 else { return }  // Space bar
        switch state {
        case .waitingToStart:
            startGame()
        case .gameOver:
            showInstructions()
        case .playing:
            break
        }
    }
}
