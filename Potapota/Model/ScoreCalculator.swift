//
//  ScoreCalculator.swift
//  Potapota
//
//  Created by noguchi on 2021/08/24.
//

import Foundation
import SpriteKit

enum ChainBonus: Int, CaseIterable {
    case i      = 0
    case ii     = 8
    case iii    = 16
    case iv     = 32
    case v      = 64
    case vi     = 96
    case vii    = 128
    case viii   = 160
    case ix     = 192
    case x      = 224
    case xi     = 256
    case xii    = 288
    case xiii   = 320
    case xiv    = 352
    case xv     = 384
    case xvi    = 416
    case xvii   = 448
    case xviii  = 480
    case xix    = 512
}

enum UnionBonus: Int, CaseIterable {
    case four   = 0
    case five   = 2
    case six    = 3
    case seven  = 4
    case eight  = 5
    case nine   = 6
    case ten    = 7
    case more   = 10
    
    // 4個が最低消去数なので消去数カウント-4
    static func bonus(count: Int) -> UnionBonus {
        if UnionBonus.allCases.count <= count - 4 { return .more }
        return UnionBonus.allCases[count - 4]
    }
}

enum ColorBonus: Int, CaseIterable {
    case one    = 0
    case two    = 3
    case three  = 6
    case four   = 12
    case five   = 24
}


final class ScoreCalculator {
    
    func calculateScore(deletePotas: [CollectionMap], chainCount: Int = 1) -> Int {
        guard !deletePotas.isEmpty else { return 0 }
        
        var result = 0
        var colors = Set<PotaColor>()
        var colorBonus: ColorBonus
        
        // まず色数合計を抜き出す
        deletePotas.forEach({
            if let color = $0.color {
                colors.insert(color)
            }
        })
        
        colorBonus = ColorBonus.allCases[colors.count - 1]
        
        deletePotas.forEach { map in
            guard !map.collection.isEmpty else { return }
            let count = map.collection.count
            
            result += foundationFomula(count: count, union: UnionBonus.bonus(count: count), color: colorBonus, chain: ChainBonus.allCases[chainCount - 1])
        }
        
        
        return result
    }
    
    /// 基本計算式
    //  @param count: 消えた数
    //  @param union: 連結数ボーナス
    //  @param color: 色数ボーナス
    //  @param chain: 連鎖数ボーナス
    private func foundationFomula(count: Int, union: UnionBonus, color: ColorBonus, chain: ChainBonus) -> Int {
        let bonus = union.rawValue + color.rawValue + chain.rawValue
        return count * 10 * ((bonus == 0) ? 1 : bonus)
    }
}
