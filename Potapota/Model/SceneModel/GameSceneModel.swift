//
//  GameSceneModel.swift
//  Potapota
//
//  Created by noguchi on 2021/08/24.
//

import Foundation
import SpriteKit
import GameplayKit

enum PlayingPhase {
    case pause, interection
}

struct LogicalPosition {
    var x: Int
    var y: Int
}

// 論理マップ上のPotaの繋がりを表現するEntity
class CollectionMap {
    var collection = [Pota]()
    var positions = [LogicalPosition]()
    var color: PotaColor? {
        collection.first?.nodeColor
    }
}

enum CheckType {
    case unknown, valid, invalid
}

enum ResultType {
    case alive, delete
}

final class GameSceneModel {
    
    // event
    var didUpdateScore: ((Int) -> Void)?
    var didChangePhase: ((PlayingPhase) -> Void)?
    var didOverGame: (() -> Void)?
    var deletePota: ((Pota) -> Void)?
    var didDeletePotas: ((_ completion: @escaping (() -> Void)) -> Void)?
    
    // state
    private(set) var phase: PlayingPhase = .pause {
        didSet {
            didChangePhase?(phase)
        }
    }
    private var solutionCompleted = false
    private var duringSolution = false

    // score
    var scoreCalculator = ScoreCalculator()
    var currentChainCount = 0
    var currentScore = 0 {
        didSet {
            didUpdateScore?(currentScore)
        }
    }
    
    // screen
    var sceneFrame: CGRect
    var fieldFrame: CGRect {
        CGRect(x: 0, y: 0, width: sceneFrame.width * 0.7, height: sceneFrame.height * 0.8)
    }
    var potaSize: CGSize {
        CGSize(width: fieldFrame.width / 6, height: fieldFrame.height / 12)
    }

    // entity
    var fieldSize: (Int, Int) = (6, 12)
    var fieldPotaMap: [[Pota?]] = [[]]
    private var fieldCollections = [CollectionMap]()

    init(sceneFrame: CGRect) {
        self.sceneFrame = sceneFrame
        self.setup()
    }
    
    func startGame() {
        fieldPotaMap.flatMap({ $0 }).forEach({ $0?.removeFromParent() })
        setup()
        fieldCollections = []
        solutionCompleted = false
        duringSolution = false
        phase = .interection
    }
    
    func switchPhase() {
        if phase == .pause {
            phase = .interection
        } else {
            phase = .pause
        }
    }
    
    // ユーザー操作完了
    func didFinishUserInterection() {
        solutionField()
    }

    func validPosition(_ position: LogicalPosition) -> Bool {
        ( 0..<fieldSize.0 ).contains( position.x ) && ( 0..<fieldSize.1 ).contains( position.y )
    }
    
    func position(of pota: Pota) -> LogicalPosition {
        let calibrationPoint: (CGFloat, CGFloat) = (pota.position.x + fieldFrame.midX, pota.position.y + fieldFrame.midY)
        let xPoint = (calibrationPoint.0 >= 0 ? calibrationPoint.0 : 0) / potaSize.width
        let yPoint = (calibrationPoint.1 >= 0 ? calibrationPoint.1 : 0) / potaSize.height
        return LogicalPosition(x: Int(floor(xPoint)), y: Int(round(yPoint)))
    }

    func floorHeight(row: Int) -> CGFloat {
        guard row < fieldSize.0 else { return -fieldFrame.height / 2 }
        let floorHeight = CGFloat(fieldPotaMap[row].prefix(while: { $0 != nil }).count) * potaSize.height
        return floorHeight
    }
    
    // drop actions
    // Pota1つのdrop処理
    func drop(_ pota: Pota, completion: @escaping (() -> Void) = {}) {
        let position = position(of: pota)
        guard position.x < fieldSize.0, position.y < fieldSize.1 else { return }
        fieldPotaMap[position.x][position.y] = nil
        let height = floorHeight(row: position.x) - fieldFrame.height / 2
        let dropAction = SKAction.moveTo(y: height, duration: 0.1)
        pota.run(dropAction, completion: completion)
        
        guard let dropIndex = fieldPotaMap[position.x].firstIndex(of: nil) else { return }
        fieldPotaMap[position.x][dropIndex] = pota
    }
    
    // 1列分のdrop処理
    private func dropLine(at row: Int, completion: @escaping (() -> Void) = {}) {
        func floatPota(row: [Pota?]) -> Pota? {
            if let firstNilIndex = row.firstIndex(where: { $0 == nil }) {
                return row.suffix(from: firstNilIndex).first(where: { $0 != nil }) ?? nil
            } else {
                return nil
            }
        }
        
        guard row < fieldSize.0 else { return }
        let group = DispatchGroup()
        while let float = floatPota(row: fieldPotaMap[row]) {
            group.enter()
            drop(float, completion: {
                    group.leave()
            })
        }
        group.notify(queue: .main, execute: { completion() })
    }

    private func dropAllPota(completion: @escaping (() -> Void) = {}) {
        let group = DispatchGroup()
        for row in 0..<fieldSize.0 {
            group.enter()
            dropLine(at: row, completion: {
                        group.leave()
            })
        }
        group.notify(queue: .main, execute: completion)
    }

    private func setup() {
        fieldPotaMap = {
            let row = [Pota?](repeating: nil, count: fieldSize.1)
            let potas = [[Pota?]](repeating: row, count: fieldSize.0)
            return potas
        }()
    }
    
    private func deleteCollectionList() -> [CollectionMap] {
        var collections = [CollectionMap]()
        var resultMap = [[ResultType]](repeating: [ResultType](repeating: .alive, count: fieldSize.1), count: fieldSize.0)
        var checkMap = [[CheckType]](repeating: [CheckType](repeating: .unknown, count: fieldSize.1), count: fieldSize.0)
        
        // 再帰探索
        func checkAround(position: LogicalPosition, color: PotaColor) {
            guard validPosition(position),
                  checkMap[position.x][position.y] == .unknown,
                  resultMap[position.x][position.y] == .alive else { return }
            if let pota = fieldPotaMap[position.x][position.y], pota.nodeColor == color {
                checkMap[position.x][position.y] = .valid
            } else {
                checkMap[position.x][position.y] = .invalid
                return
            }
            
            checkAround(position: LogicalPosition(x: position.x + 1, y: position.y), color: color)
            checkAround(position: LogicalPosition(x: position.x - 1, y: position.y), color: color)
            checkAround(position: LogicalPosition(x: position.x, y: position.y + 1), color: color)
            checkAround(position: LogicalPosition(x: position.x, y: position.y - 1), color: color)
        }
        
        fieldPotaMap.forEach { row in
            row.forEach { item in
                guard let pota = item else { return }
                checkMap = [[CheckType]](repeating: [CheckType](repeating: .unknown, count: fieldSize.1), count: fieldSize.0)
                
                checkAround(position: position(of: pota), color: pota.nodeColor)
                // 削除対象であれば戻り値に追加
                if checkMap.flatMap({ $0 }).filter({ $0 == .valid }).count > 3 {
                    let map = CollectionMap()
                    checkMap.enumerated().forEach({ row in
                        row.element.enumerated().forEach { value in
                            if value.element == .valid {
                                let deletePota = fieldPotaMap[row.offset][value.offset]!
                                resultMap[row.offset][value.offset] = .delete
                                map.collection.append(deletePota)
                                map.positions.append(position(of: deletePota))
                            }
                        }
                    })
                    collections.append(map)
                }
            }
        }
        
        return collections
    }

    private func solutionField() {
        if duringSolution {
            return
        }
        
        duringSolution = true
        currentChainCount += 1
        // ゲームオーバー判定
        if fieldPotaMap[2][fieldSize.1 - 1] != nil {
            didOverGame?()
            phase = .pause
            return
        }

        // * Potaの消去判定 + 消去
        // ** 4つ以上連なっているPotaのチェック
        let deleteCollections = deleteCollectionList()

        // * スコア計算
        currentScore += scoreCalculator.calculateScore(deletePotas: deleteCollections, chainCount: currentChainCount)
        
        // ** 対象Potaの削除
        if !deleteCollections.isEmpty {
            deleteCollections.forEach({ map in
                map.positions.forEach { position in
                    if let pota = fieldPotaMap[position.x][position.y] {
                        deletePota?(pota)
                        fieldPotaMap[position.x][position.y] = nil
                    }
                }
            })
        } else {
            solutionCompleted = true
        }
        
        // 削除によるUI側の落下処理
        dropAllPota(completion: { [weak self] in
            guard let self = self else { return }
            self.duringSolution = false
            if self.solutionCompleted == true {
                self.solutionCompleted = false
                self.phase = .interection
                self.currentChainCount = 0
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now()+0.5) { [weak self] in
                    self?.solutionField()
                }
            }
        })
    }
}

