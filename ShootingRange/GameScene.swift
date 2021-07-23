//
//  GameScene.swift
//  ShootingRange
//
//  Created by Igor Chernyshov on 21.07.2021.
//

import SpriteKit
import GameplayKit

final class GameScene: SKScene {

	// MARK: - Nodes
	private var scoreLabel: SKLabelNode!
	private var timeLabel: SKLabelNode!
	private var bulletsLabel: SKLabelNode!
	private var reloadButton: SKSpriteNode!

	// MARK: - Properties
	private var score: Int = 0 {
		didSet {
			scoreLabel.text = "Score: \(score)"
		}
	}
	private var time: Int = 20 {
		didSet {
			timeLabel.text = "Time: \(time)"
			if time == 0 { gameOver() }
		}
	}
	private var bullets: Int = 6 {
		didSet {
			guard bullets >= 0 else { fatalError("Player was able to shoot without bulltes") }
			bulletsLabel.text = String(repeating: "⁍", count: bullets)
			if bullets == 6 {
				isReloading = false
			}
			if bullets < 6 && !isReloading {
				reloadButton.isHidden = false
			}
		}
	}
	private var isReloading = false {
		didSet {
			if isReloading == true {
				reloadTicker = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in self.bullets += 1 }
			} else {
				reloadTicker?.invalidate()
			}
			reloadButton.isHidden = true
		}
	}

	private let paths: [(from: CGPoint, to: CGPoint)] = [(CGPoint(x: -50, y: 670), CGPoint(x: 1074, y: 670)),
														 (CGPoint(x: 1074, y: 570), CGPoint(x: -50, y: 570)),
														 (CGPoint(x: -50, y: 470), CGPoint(x: 1074, y: 470))]

	private var timer: Timer?
	private var clock: Timer?
	private var reloadTicker: Timer?

	// MARK: - Lifecycle
	override func didMove(to view: SKView) {
		configureBackground()
		configureLabels()
		configureReloadButton()
		clock = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in self.time -= 1 }
		timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in self.createEnemy() }
	}

	// MARK: - UI Configuration
	private func configureBackground() {
		let background = SKSpriteNode(imageNamed: "background")
		background.position = CGPoint(x: 512, y: 384)
		background.blendMode = .replace
		background.zPosition = -1
		background.name = "background"
		addChild(background)
	}

	private func configureLabels() {
		scoreLabel = makeLabelNode(text: "Score: 0", position: CGPoint(x: 8, y: 724))
		addChild(scoreLabel)

		timeLabel = makeLabelNode(text: "Time: 60", position: CGPoint(x: 400, y: 724))
		addChild(timeLabel)

		bulletsLabel = makeLabelNode(text: "⁍⁍⁍⁍⁍⁍", position: CGPoint(x: 860, y: 724))
		addChild(bulletsLabel)
	}

	private func makeLabelNode(text: String, position: CGPoint) -> SKLabelNode {
		let labelNode = SKLabelNode(fontNamed: "Chalkduster")
		labelNode.text = text
		labelNode.position = position
		labelNode.horizontalAlignmentMode = .left
		labelNode.fontSize = 48
		return labelNode
	}

	private func configureReloadButton() {
		reloadButton = SKSpriteNode(imageNamed: "reload")
		reloadButton.size = CGSize(width: 150, height: 150)
		reloadButton.position = CGPoint(x: 949, y: 75)
		reloadButton.blendMode = .replace
		reloadButton.name = "reload"
		reloadButton.isHidden = true
		addChild(reloadButton)
	}

	// MARK: - Game Logic
	private func createEnemy() {
		if time == 0 { return }

		let pathNumber = Int.random(in: 0..<paths.count)
		let path = paths[pathNumber]
		let isCorrectTarget = Bool.random()
		let targetSprite = SKSpriteNode(imageNamed: "target")
		targetSprite.size = CGSize(width: 100, height: 100)
		targetSprite.color = isCorrectTarget ? #colorLiteral(red: 0.2745098174, green: 0.4862745106, blue: 0.1411764771, alpha: 1) : .yellow
		targetSprite.colorBlendFactor = isCorrectTarget ? 0.9 : 0.0
		targetSprite.position = path.from
		targetSprite.name = isCorrectTarget ? "bad" : "good"
		if pathNumber == 1 { targetSprite.xScale.negate() }
		addChild(targetSprite)

		targetSprite.run(SKAction.move(to: path.to, duration: 3))
		DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) { targetSprite.removeFromParent() }
	}

	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard !isReloading, time > 0 else { return }
		guard let touch = touches.first else { return }

		let location = touch.location(in: self)
		let tappedNode = nodes(at: location).first

		if tappedNode?.name == "reload" {
			isReloading = true
			return
		}

		guard bullets > 0 else { return }
		bullets -= 1

		if tappedNode?.name == "bad" {
			drawBlood(at: location, isZombie: true)
			score += 1
		} else if tappedNode?.name == "good" {
			drawBlood(at: location, isZombie: false)
			score -= 5
		} else if tappedNode?.name == "background" {
			return
		}
		tappedNode?.removeFromParent()
	}

	private func drawBlood(at position: CGPoint, isZombie: Bool) {
		guard let blood = SKEmitterNode(fileNamed: "\(isZombie ? "Zombie" : "")Blood") else { return }
		blood.position = position
		addChild(blood)
	}

	private func gameOver() {
		clock?.invalidate()
		timer?.invalidate()
		timeLabel.text = "Game Over"
	}
}
