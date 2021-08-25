//
//  Tsumo.swift
//  Potapota
//
//  Created by noguchi on 2021/08/24.
//

import SpriteKit
import GameplayKit

enum TsumoRotationState: Int {
    case portrait
    case landscapeRight
    case bottomToTop
    case landscapeLeft
    
    func turnRight() -> TsumoRotationState {
        if self == .landscapeLeft {
            return .portrait
        } else {
            return TsumoRotationState(rawValue: self.rawValue + 1)!
        }
    }
    
    func turnLeft() -> TsumoRotationState {
        if self == .portrait {
            return .landscapeLeft
        } else {
            return TsumoRotationState(rawValue: self.rawValue - 1)!
        }
    }
}

final class Tsumo: SKSpriteNode {
    var topPota: Pota
    var bottomPota: Pota
    var rotation: TsumoRotationState = .portrait {
        didSet {
            calibratePosition(rotation: rotation)
        }
    }
    
    // 物理演算用(※未使用)
    override var physicsBody: SKPhysicsBody? {
        didSet {
            topPota.physicsBody = physicsBody?.copy() as? SKPhysicsBody
            bottomPota.physicsBody = physicsBody?.copy() as? SKPhysicsBody
        }
    }
    
    override var position: CGPoint {
        didSet {
            topPota.position = position
            bottomPota.position = position
        }
    }
    
    init(top: Pota? = nil, bottom: Pota? = nil, zPosition: CGFloat = 1, potaSize: CGSize) {
        self.topPota = top ?? Pota.createRandom(size: potaSize)!
        self.bottomPota = bottom ?? Pota.createRandom(size: potaSize)!
        super.init(texture: SKTexture(cgImage: UIImage(named: "tsumo_back")!.cgImage!), color: .blue, size: .init(width: potaSize.width, height: potaSize.height * 2))
        self.rotation = .portrait
        calibratePosition(rotation: self.rotation)
        self.zPosition = zPosition
        self.topPota.zPosition = zPosition + 1
        self.bottomPota.zPosition = zPosition + 1
        self.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        self.topPota.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        self.bottomPota.anchorPoint = CGPoint(x: 0.5, y: 0.0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func run(_ action: SKAction) {
        topPota.run(action)
        bottomPota.run(action)
        super.run(action)
    }
    
    override func run(_ action: SKAction, completion block: @escaping () -> Void) {
        topPota.run(action)
        bottomPota.run(action)
        super.run(action, completion: block)
    }
    
    func addToParent(parent: SKNode) {
        parent.addChild(topPota)
        parent.addChild(bottomPota)
    }
    
    func moveBy(position: CGPoint, duration: TimeInterval = 0.02, completion: @escaping () -> Void = {}) {
        let move = SKAction.moveBy(x: position.x,
                                   y: position.y, duration: duration)
        self.run(move, completion: completion)
        calibratePosition(rotation: self.rotation)
    }
    
    func updatePosition(_ newPosition: CGPoint, duration: TimeInterval = 0.02) {
        let move = SKAction.move(to: newPosition, duration: duration)
        self.run(move)
        calibratePosition(rotation: self.rotation)
    }
    
    func rotate(isLeft: Bool = true) {
        if isLeft {
            rotation = rotation.turnLeft()
        } else {
            rotation = rotation.turnRight()
        }
    }
    
    private func calibratePosition(rotation: TsumoRotationState) {
        var topPosition: CGPoint
        let offset = self.size.height / 2
        switch rotation {
        case .portrait:
            topPosition = .init(x: bottomPota.position.x, y: bottomPota.position.y + offset)
        case .landscapeLeft:
            topPosition = .init(x: bottomPota.position.x - offset, y: bottomPota.position.y)
        case .landscapeRight:
            topPosition = .init(x: bottomPota.position.x + offset, y: bottomPota.position.y)
        case .bottomToTop:
            topPosition = .init(x: bottomPota.position.x, y: bottomPota.position.y - offset)
        }
        topPota.run(.move(to: topPosition, duration: 0.02))
    }
}
