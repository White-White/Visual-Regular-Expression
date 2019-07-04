//
//  State.swift
//  RegExSwift
//
//  Created by White on 2019/5/24.
//  Copyright © 2019 Ali-White. All rights reserved.
//

import Foundation

enum NodeStyleType {
    case Start
    case Normal
    case Highlighted
}

enum PathWeight {
    case Important
    case Normal
}

class BaseState: Hashable {
    /* Used for node names, path descriptions */
    static var counter = 0;
    var stateName: String? {
        if let name = _stateName {
            return name
        } else {
            let newName = "s\(BaseState.counter)"
            _stateName = newName
            BaseState.counter += 1
            return newName
        }
    }
    private var _stateName: String?
    var styleType: NodeStyleType = NodeStyleType.Normal
    
    var acceptanceDesp: String?
    /* Used for node names, node appearance and path descriptions */
    
    /* Hashable */
    private var uuid = UUID()
    func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
    static func == (lhs: BaseState, rhs: BaseState) -> Bool {
        return lhs.uuid == rhs.uuid
    }
    /* Hashable */
    
    var isAcceptingState: Bool = false
    var outs: [BaseState] = []
    var weightRecords: [BaseState:PathWeight] = [:]
    
    //find outs
    func canAccept(input c: Character) -> Bool {
        return false
    }
    func canAcceptNothing() -> Bool {
        return false
    }
    func outsFor(input c: Character) -> [BaseState] {
        return self.outs.filter { $0.canAccept(input: c) }
    }
    func outsForNothing() -> [BaseState] {
        if !self.canAcceptNothing() { return [] }
        var ret = [self] + self.outs.reduce([], { $0 + $1.outsForNothing() })
        if let delegate = delegate,
            let conditionalOut = conditionalOut,
            delegate.canStateGotoConditionalOutForNothing(self) {
            ret.append(conditionalOut)
        }
        return ret
    }
    
    func addOut(_ state: BaseState, withWeight w: PathWeight = .Normal) {
        if !(self.outs.contains(where: { $0 === state })) {
            self.isAcceptingState = false
            self.outs.append(state)
            self.weightRecords[state] = w
        }
    }
    
    func addOutToTail(_ state: BaseState, withWeight w: PathWeight = .Normal) {
        if self.outs.isEmpty {
            self.addOut(state, withWeight: w)
            return
        }
        self.outs.forEach({ $0.addOutToTail(state, withWeight: w) })
    }
    
    //
    func graphicOuts() -> [BaseState] { return self.outs }
    
    
    //Conditional out
    weak var delegate: ConditionalOutDelegate?
    var conditionalOut: BaseState?
}

protocol ConditionalOutDelegate: AnyObject {
    func canStateGotoConditionalOutForNothing(_ s: BaseState) -> Bool
}

class DumbState: BaseState {
    override init() {
        super.init()
        self.acceptanceDesp = "ε"
    }
    override func canAcceptNothing() -> Bool { return true }
    override func canAccept(input c: Character) -> Bool { return false }
}

class LiteralState: BaseState {
    let literalClass: LiteralsClass
    init(literalClass: LiteralsClass) {
        self.literalClass = literalClass
        super.init()
        self.acceptanceDesp = literalClass.criteriaDesp()
    }
    
    override func canAcceptNothing() -> Bool {
        return false
    }
    override func canAccept(input c: Character) -> Bool {
        return self.literalClass.accepts(c)
    }
}
