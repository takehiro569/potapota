//
//  GameField.swift
//  Potapota
//
//  Created by noguchi on 2021/08/16.
//

import SpriteKit
import GameplayKit

class GameField<T: SKNode> {
    let columns: Int
    let rows: Int
    // #2
    var array: Array<T?>

    init(columns: Int, rows: Int) {
        self.columns = columns
        self.rows = rows
        // #3

        array = Array<T?>(repeating: nil, count: rows * columns)
    }

    // #4
    subscript(column: Int, row: Int) -> T? {
        get {
            return array[(row * columns) + column]
        }
        set(newValue) {
            array[(row * columns) + column] = newValue
        }
    }
}
