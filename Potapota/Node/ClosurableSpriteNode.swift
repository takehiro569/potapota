//
//  ClosurableSpriteNode.swift
//  Potapota
//
//  Created by noguchi on 2021/08/21.
//

import SpriteKit

class ClosurableSpriteNode: SKSpriteNode {
    
    var touchsBegan: ((_ touches: Set<UITouch>, _ event: UIEvent?) -> Void)?
    var touchsMoved: ((_ touches: Set<UITouch>, _ event: UIEvent?) -> Void)?
    var touchesEnded: ((_ touches: Set<UITouch>, _ event: UIEvent?) -> Void)?
    var touchesCancelled: ((_ touches: Set<UITouch>, _ event: UIEvent?) -> Void)?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        touchsBegan?(touches, event)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        touchsMoved?(touches, event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        touchesEnded?(touches, event)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        touchesCancelled?(touches, event)
    }
}
