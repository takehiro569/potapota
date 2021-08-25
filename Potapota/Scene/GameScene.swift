//
//  GameScene.swift
//  Potapota
//
//  Created by noguchi on 2021/08/14.
//

import SpriteKit
import GameplayKit

enum ControlCommand {
    case rotateLeft, rotateRight, left, right, drop
}

private enum NodesZPosition: CGFloat {
    case scene = 0
    case field = 1
    case tapo = 2
    case effects = 5
    case next = 8
    case nextTsumo = 9
    case buttons = 10
    case score = 20
    case gameOver = 99
}

class GameScene: SKScene {
    
    lazy var model = GameSceneModel(sceneFrame: frame)
    
    private var currentTsumo: Tsumo?
    private var nextTsumo: Tsumo?
    
    private var scoreLabelNode: SKLabelNode?
    private var fieldNode: SKSpriteNode!
    private var nextPotaArea: SKSpriteNode?
    private var holdDropButton = false
    

    var currentBottomPotaPosition: LogicalPosition {
        guard let bottomPota = currentTsumo?.bottomPota else { return LogicalPosition(x: 2, y: 11) }
        let calibrationPoint: (CGFloat, CGFloat) = (bottomPota.position.x + model.fieldFrame.midX, bottomPota.position.y + model.fieldFrame.midY)
        let xPoint = (calibrationPoint.0 >= 0 ? calibrationPoint.0 : 0) / model.potaSize.width
        let yPoint = (calibrationPoint.1 >= 0 ? calibrationPoint.1 : 0) / model.potaSize.height
        return LogicalPosition(x: Int(floor(xPoint)), y: Int(round(yPoint)))
    }
    
    var currentTopPotaPosition: LogicalPosition {
        // TODO: bottomに依存するように修正してみる
        guard let topPota = currentTsumo?.topPota else { return LogicalPosition(x: 2, y: 11) }
        let calibrationPoint: (CGFloat, CGFloat) = (topPota.position.x + model.fieldFrame.midX, topPota.position.y + model.fieldFrame.midY)
        let xPoint = (calibrationPoint.0 >= 0 ? calibrationPoint.0 : 0) / model.potaSize.width
        let yPoint = (calibrationPoint.1 >= 0 ? calibrationPoint.1 : 0) / model.potaSize.height
        return LogicalPosition(x: Int(floor(xPoint)), y: Int(round(yPoint)))
    }
    
    override func sceneDidLoad() {
        super.sceneDidLoad()
        setupSubviews()
        setupCallbacks()
        model.startGame()
    }
    
    override func update(_ currentTime: TimeInterval) {
        updatePhase()
    }
    
    private func setupSubviews() {
        self.backgroundColor = #colorLiteral(red: 0.9568627477, green: 0.6588235497, blue: 0.5450980663, alpha: 1)
        self.physicsWorld.contactDelegate = self
        self.physicsWorld.gravity = CGVector(dx: 0.0, dy: -0.1)
        
        // 操作領域
        fieldNode = SKSpriteNode(color: UIColor.lightGray, size: model.fieldFrame.size)
        fieldNode.position = CGPoint(x: -(frame.width / 10), y: (frame.height / 10 * 1.5) - 80)
        fieldNode.zPosition = NodesZPosition.field.rawValue
        self.addChild(fieldNode)
         
        // NEXT
        let rightTopPosition = CGPoint(x: frame.width / 2, y: frame.height / 2)
        nextPotaArea = SKSpriteNode(texture: SKTexture(imageNamed: "next_back"), size: .init(width: model.potaSize.width + 30, height: model.potaSize.height * 2 + 40))
        nextPotaArea?.position = .init(x: rightTopPosition.x - nextPotaArea!.size.width, y: rightTopPosition.y - nextPotaArea!.size.height - 100)
        nextPotaArea?.zPosition = NodesZPosition.next.rawValue
        addChild(nextPotaArea!)
        createNextTsumo()

        createScoreDisplayNode()
        // buttons
        createRotationButtonNode()
        createCursorButtonNode()
        createPauseButtonNode()
    }
    
    private func setupCallbacks() {
        model.didUpdateScore = { [weak self] score in
            self?.scoreLabelNode?.text = "\(score)"
        }
        model.didChangePhase = { [weak self] phase in
            self?.switchPhase(phase: phase)
        }
        model.didOverGame = { [weak self] in
            self?.showGameOverNode()
        }
        model.deletePota = { [weak self] pota in
            // Potaが消えた箇所にparticleを表示する
            guard let self = self else { return }
            if let emitter = SKEmitterNode(fileNamed: "AscensionParticle.sks") {
                emitter.position = pota.position
                emitter.zPosition = NodesZPosition.effects.rawValue
                self.fieldNode.addChild(emitter)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    emitter.removeFromParent()
                }
            }

            pota.removeFromParent()
        }
    }
    
    private func createScoreDisplayNode() {
        let base = SKSpriteNode(texture: SKTexture(imageNamed: "score_back"), size: .init(width: frame.width / 2, height: 60))
        base.zPosition = NodesZPosition.buttons.rawValue
        scoreLabelNode = SKLabelNode(text: "0")
        scoreLabelNode?.numberOfLines = 1
        scoreLabelNode?.fontColor = #colorLiteral(red: 0.9732960811, green: 0.7837712294, blue: 0.5154668068, alpha: 1)
        scoreLabelNode?.fontName = "HiraMaruProN-W4"
        scoreLabelNode?.fontSize = 30
        scoreLabelNode?.horizontalAlignmentMode = .right
        scoreLabelNode?.zPosition = NodesZPosition.score.rawValue
        scoreLabelNode?.position = .init(x: base.size.width / 2 - 80, y: -10)
        base.addChild(scoreLabelNode!)
        base.position = .init(x: 0, y: -(frame.height / 2) + (frame.height - (model.fieldFrame.height + 40)))
        addChild(base)
    }
    
    private func createRotationButtonNode() {
        let buttonBaseSize = CGSize(width: frame.width / 4, height: frame.height / 8.5)
        let leftButtonBase = SKSpriteNode(texture: SKTexture(imageNamed: "button_back"), size: .init(width: buttonBaseSize.height / 2 + 10, height: buttonBaseSize.height / 2 + 10))
        let leftTurnButton = ClosurableSpriteNode(texture: SKTexture(image: UIImage(systemName: "arrow.counterclockwise.circle")!),
                                              color: .white,
                                              size: .init(width: buttonBaseSize.height / 2, height: buttonBaseSize.height / 2))
        leftTurnButton.zPosition = NodesZPosition.buttons.rawValue
        leftTurnButton.isUserInteractionEnabled = true
        leftTurnButton.touchesEnded = { [unowned self] (_, _) in
            self.controlTsumo(.rotateLeft)
        }
        leftButtonBase.addChild(leftTurnButton)
        
        let rightButtonBase = SKSpriteNode(texture: SKTexture(imageNamed: "button_back"), size: .init(width: buttonBaseSize.height / 2 + 10, height: buttonBaseSize.height / 2 + 10))
        let rightTurnButton = ClosurableSpriteNode(texture: SKTexture(image: UIImage(systemName: "arrow.clockwise.circle")!),
                                               color: .white,
                                               size: .init(width: buttonBaseSize.height / 2, height: buttonBaseSize.height / 2))
        rightTurnButton.zPosition = NodesZPosition.buttons.rawValue
        rightTurnButton.isUserInteractionEnabled = true
        rightTurnButton.touchesEnded = { [unowned self] (_, _) in
            self.controlTsumo(.rotateRight)
        }
        rightButtonBase.addChild(rightTurnButton)
        
        let rightBottomPosition = CGPoint(x: frame.width / 2, y: -frame.height / 2)
        
        leftButtonBase.position = .init(x: rightBottomPosition.x - (buttonBaseSize.width / 2) * 2 ,
                                        y: rightBottomPosition.y + buttonBaseSize.height)
        rightButtonBase.position = .init(x: rightBottomPosition.x - (buttonBaseSize.width / 2) ,
                                         y: rightBottomPosition.y + buttonBaseSize.height)
        self.addChild(leftButtonBase)
        self.addChild(rightButtonBase)
    }
    
    private func createCursorButtonNode() {
        let buttonBaseSize = CGSize(width: frame.width / 3, height: frame.height / 9)
        let leftButton = ClosurableSpriteNode(texture: SKTexture(image: UIImage(named: "button_left")!),
                                              color: .white,
                                              size: .init(width: buttonBaseSize.width / 3, height: buttonBaseSize.height / 2))
        leftButton.zPosition = NodesZPosition.buttons.rawValue
        leftButton.isUserInteractionEnabled = true
        leftButton.touchesEnded = { [unowned self] (_, _) in
            self.controlTsumo(.left)
        }
        let rightButton = ClosurableSpriteNode(texture: SKTexture(image: UIImage(named: "button_right")!),
                                               color: .white,
                                              size: .init(width: buttonBaseSize.width / 3, height: buttonBaseSize.height / 2))
        rightButton.zPosition = NodesZPosition.buttons.rawValue
        rightButton.isUserInteractionEnabled = true
        rightButton.touchesEnded = { [unowned self] (_, _) in
            self.controlTsumo(.right)
        }
        let dropButton = ClosurableSpriteNode(texture: SKTexture(image: UIImage(named: "button_left")!),
                                              color: .white,
                                              size: .init(width: buttonBaseSize.width / 3, height: buttonBaseSize.height / 2))
        dropButton.zRotation = 1.57
        dropButton.zPosition = NodesZPosition.buttons.rawValue
        dropButton.isUserInteractionEnabled = true
        dropButton.touchsBegan = { [unowned self] (_, _) in
            self.holdDropButton = true
        }
        dropButton.touchesEnded = { [unowned self] (_, _) in
            self.holdDropButton = false
        }
        
        let rightBottomPosition = CGPoint(x: -(frame.width / 2), y: -frame.height / 2)
        
        leftButton.position = .init(x: rightBottomPosition.x + (buttonBaseSize.width / 3),
                                    y: rightBottomPosition.y + buttonBaseSize.height)
        rightButton.position = .init(x: rightBottomPosition.x + (buttonBaseSize.width / 3) * 3 ,
                                     y: rightBottomPosition.y + buttonBaseSize.height)
        dropButton.position = .init(x: rightBottomPosition.x + (buttonBaseSize.width / 3) * 2 ,
                                    y: rightBottomPosition.y + buttonBaseSize.height / 2)
        
        self.addChild(leftButton)
        self.addChild(rightButton)
        self.addChild(dropButton)
    }
    
    private func createPauseButtonNode() {
        let pauseButtonBase = SKSpriteNode(texture: SKTexture(imageNamed: "button_back"), size: .init(width: 60, height: 60))

        let pauseButton = ClosurableSpriteNode(texture: SKTexture(image: UIImage(systemName: "pause.circle.fill")!),
                                              color: .white,
                                              size: .init(width: 50, height: 50))
        pauseButton.zPosition = NodesZPosition.buttons.rawValue
        pauseButton.isUserInteractionEnabled = true
        pauseButton.touchesEnded = { [unowned self] (_, _) in
            self.model.switchPhase()
        }
        pauseButtonBase.addChild(pauseButton)

        let rightTopPosition = CGPoint(x: (frame.width / 2), y: frame.height / 2)
        pauseButtonBase.position = .init(x: rightTopPosition.x - pauseButtonBase.size.width - 20 ,
                                         y: rightTopPosition.y - pauseButtonBase.size.height - 30)
        
        self.addChild(pauseButtonBase)
    }
    
    private func setupCurrentTsumo() {
        if let next = nextTsumo {
            next.removeFromParent()
            next.bottomPota.removeFromParent()
            next.topPota.removeFromParent()
            currentTsumo = next
        } else {
            currentTsumo = nil
            currentTsumo = Tsumo(top: nil, bottom: nil, potaSize: CGSize(width: model.fieldFrame.width / 6, height: model.fieldFrame.height / 12))
        }
        currentTsumo?.position = CGPoint(x: -(model.fieldFrame.width / 12), y: model.fieldFrame.height / 2)
        fieldNode.addChild(currentTsumo!)
        currentTsumo?.addToParent(parent: fieldNode)
        currentTsumo?.updatePosition(CGPoint(x: -(model.fieldFrame.width / 12), y: model.fieldFrame.height / 2), duration: 0.0)
        
        // Next補充
        createNextTsumo()
    }
    
    private func createNextTsumo() {
        nextTsumo = Tsumo(top: nil, bottom: nil, potaSize: CGSize(width: model.fieldFrame.width / 6, height: model.fieldFrame.height / 12))
        nextTsumo?.zPosition = NodesZPosition.nextTsumo.rawValue
        nextTsumo?.position = .init(x: 0, y: -model.potaSize.height)
        nextTsumo?.topPota.position = .init(x: 0, y: -model.potaSize.height * 2)
        nextPotaArea?.addChild(nextTsumo!)
        nextTsumo?.addToParent(parent: nextPotaArea!)
        nextTsumo?.updatePosition(.init(x: 0, y: -model.potaSize.height), duration: 0.0)
    }
    
    private func switchPhase(phase: PlayingPhase) {
        switch phase {
        case .pause: break
        case .interection:
            if currentTsumo == nil {
                setupCurrentTsumo()
            }
        }
    }
    
    private func checkDrop() -> (Bool, Bool) {
        guard let tsumo = currentTsumo else { return (false, false) }
        // 補正後のツモの下端y座標
        let calibrationBottom = ((tsumo.rotation != .bottomToTop) ? tsumo.bottomPota.position.y : tsumo.topPota.position.y) + model.fieldFrame.height / 2
        let bottomFloorHeight = model.floorHeight(row: currentBottomPotaPosition.x)
        let mainDropCheck = (calibrationBottom <= bottomFloorHeight)
        var subDropCheck = false
        if tsumo.rotation == .landscapeLeft {
            let leftFloorHeight = model.floorHeight(row: currentBottomPotaPosition.x - 1)
            subDropCheck = (calibrationBottom <= leftFloorHeight)
        } else if tsumo.rotation == .landscapeRight {
            let rightFloorHeight = model.floorHeight(row: currentBottomPotaPosition.x + 1)
            subDropCheck = (calibrationBottom <= rightFloorHeight)
        }
        
        return (mainDropCheck, subDropCheck)
    }
        
    private func didDropTsumo(main: Bool, sub: Bool, completion: @escaping (() -> Void) = {}) {
        guard let tsumo = currentTsumo else { return }

        // ちぎり処理
        if tsumo.rotation == .bottomToTop {
            model.drop(tsumo.topPota) { [unowned self] in
                self.model.drop(tsumo.bottomPota) { [unowned self] in
                    self.removeChildren(in: [tsumo])
                    self.currentTsumo = nil
                    completion()
                }
            }
        } else {
            model.drop(tsumo.bottomPota) { [unowned self] in
                self.model.drop(tsumo.topPota) { [unowned self] in
                    self.removeChildren(in: [tsumo])
                    self.currentTsumo = nil
                    completion()
                }
            }
        }
    }
    
    private func controlTsumo(_ command: ControlCommand) {
        guard let tsumo = currentTsumo else { return }
        switch command {
        case .rotateLeft:
            if currentTsumo?.rotation == .landscapeLeft &&
                model.floorHeight(row: currentBottomPotaPosition.x) > tsumo.position.y - tsumo.size.height + model.fieldFrame.height / 2 {
                return
            }
            
            if currentTsumo?.rotation == .portrait &&
                (currentBottomPotaPosition.x == 0 ||
                    model.floorHeight(row: currentBottomPotaPosition.x - 1) > tsumo.position.y + model.fieldFrame.height / 2) {
                return
            }
            
            if currentTsumo?.rotation == .bottomToTop &&
                (currentBottomPotaPosition.x == model.fieldSize.0 - 1 ||
                    model.floorHeight(row: currentBottomPotaPosition.x + 1) > tsumo.position.y + model.fieldFrame.height / 2) {
                return
            }
            
            currentTsumo?.rotate(isLeft: true)
        case .rotateRight:
            if currentTsumo?.rotation == .landscapeRight &&
                model.floorHeight(row: currentBottomPotaPosition.x) > tsumo.position.y - tsumo.size.height + model.fieldFrame.height / 2 {
                return
            }
            
            if currentTsumo?.rotation == .bottomToTop &&
                (currentBottomPotaPosition.x == 0 ||
                    model.floorHeight(row: currentBottomPotaPosition.x - 1) > tsumo.position.y + model.fieldFrame.height / 2) {
                return
            }
            
            if currentTsumo?.rotation == .portrait &&
                (currentBottomPotaPosition.x == model.fieldSize.0 - 1 ||
                    model.floorHeight(row: currentBottomPotaPosition.x + 1) > tsumo.position.y + model.fieldFrame.height / 2) {
                return
            }
            
            currentTsumo?.rotate(isLeft: false)
        case .left:
            // 操作可能かどうかの判定
            if currentTopPotaPosition.y > model.fieldSize.1 - 1 { return } // 既に左端
            if currentBottomPotaPosition.x == 0 { return } // 既に左端
            if currentTsumo?.rotation == .landscapeLeft, currentBottomPotaPosition.x < 2 { return } // ツモが左向きのとき
            if model.fieldPotaMap[currentBottomPotaPosition.x - 1][currentBottomPotaPosition.y] != nil { return } // 左にPotaがある
            let move = SKAction.moveBy(x: -(model.fieldFrame.width / 6), y: 0, duration: 0.00)
            tsumo.run(move)
        case .right:
            // 操作可能かどうかの判定
            if currentTopPotaPosition.y > model.fieldSize.1 - 1 { return } // 既に左端
            if currentBottomPotaPosition.x >= 5 { return } // 既に右端
            if currentTsumo?.rotation == .landscapeRight, currentBottomPotaPosition.x > 3 { return } // ツモが右向きのとき
            if model.fieldPotaMap[currentBottomPotaPosition.x + 1][currentBottomPotaPosition.y] != nil { return } // 右にPotaがある
            let move = SKAction.moveBy(x: (model.fieldFrame.width / 6), y: 0, duration: 0.00)
            tsumo.run(move)
        case .drop:
            let isDrop = checkDrop()
            if isDrop.0 || isDrop.1 {
                didDropTsumo(main: isDrop.0, sub: isDrop.1) { [weak self] in
                    self?.model.didFinishUserInterection()
                }
                model.switchPhase()

                return
            }
            tsumo.moveBy(position: .init(x: 0, y: -30), duration: 0.00)
        }
    }
        
    private func updatePhase() {
        switch model.phase {
        case .pause: break
        case .interection: //break
            guard let tsumo = currentTsumo else { break }
            // 地面衝突判定
            let isDrop = checkDrop()
            if isDrop.0 || isDrop.1 {
                // Tsumoの落下
                didDropTsumo(main: isDrop.0, sub: isDrop.1) { [weak self] in
                    self?.model.didFinishUserInterection()
                }

                model.switchPhase()
                return
            }
            
            // Tsumoの落下処理
            if holdDropButton {
                tsumo.moveBy(position: CGPoint(x: 0, y: -7), duration: 0.1)
            } else {
                tsumo.moveBy(position: CGPoint(x: 0, y: -2), duration: 0.1)
            }
        }
    }
    
    private func showGameOverNode() {
        let base = SKSpriteNode(texture: .init(imageNamed: "window"), size: .init(width: frame.width / 3 * 2, height: frame.height / 4))
        base.zPosition = NodesZPosition.gameOver.rawValue

        let text = SKLabelNode(text: "Game Over!")
        text.fontColor = .black
        text.color = .darkGray
        text.fontSize = 60
        text.zPosition = NodesZPosition.gameOver.rawValue + 1
        base.addChild(text)
        
        let retryButton = ClosurableSpriteNode(texture: .init(imageNamed: "parts_gray"), size: .init(width: base.size.width / 3 * 2, height: 80))
        retryButton.isUserInteractionEnabled = true
        retryButton.zPosition = NodesZPosition.gameOver.rawValue + 2
        retryButton.position = .init(x: 0, y: -100)
        retryButton.touchesEnded = { [weak self] (_, _) in
            base.removeFromParent()
            self?.model.startGame()
        }
        let retryText = SKLabelNode(text: "もういちど")
        retryText.fontColor = .white
        retryText.fontSize = 35
        retryText.zPosition = NodesZPosition.gameOver.rawValue + 2
        retryText.position = .init(x: 0, y: -10)
        retryButton.addChild(retryText)
        base.addChild(retryButton)

        addChild(base)
    }
}

//extension GameScene:

extension GameScene: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        print("contact! A:\(contact.bodyA) B:\(contact.bodyB)")
    }
}
