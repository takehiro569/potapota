//
//  Pota.swift
//  Potapota
//
//  Created by noguchi on 2021/08/16.
//

import SpriteKit
import GameplayKit

enum PotaColor: Int, CaseIterable {
    case red, blue, yellow, green, purple
    
    var color: UIColor {
        switch self {
        case .red: return .red
        case .blue: return .blue
        case .yellow: return .yellow
        case .green: return .green
        case .purple: return .purple
        }
    }
    
    var image: UIImage {
        switch self {
        case .red: return UIImage(named: "red")!
        case .blue: return UIImage(named: "blue")!
        case .yellow: return UIImage(named: "yellow")!
        case .green: return UIImage(named: "green")!
        case .purple: return UIImage(named: "purple")!
        }
    }
}

class Pota: SKSpriteNode {
    var nodeColor: PotaColor
    
    init(color: PotaColor, size: CGSize = .init(width: 40, height: 40)) {
        self.nodeColor = color
        super.init(texture: SKTexture(image: nodeColor.image), color: nodeColor.color, size: size)
        self.anchorPoint = self.centerRect.origin
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    static func createRandom(range: ClosedRange<Int>? = nil, size: CGSize = .init(width: 40, height: 40)) -> Pota? {
        if let arg = range, !arg.allSatisfy({ ($0 >= 0 && $0 < 5) }) {
            return nil
        }
        
        let color = PotaColor(rawValue: Int.random(in: 0..<5))!
        return Pota(color: color, size: size)
    }
    
    override func run(_ action: SKAction, completion block: @escaping () -> Void) {
        super.run(action, completion: block)
    }
}

