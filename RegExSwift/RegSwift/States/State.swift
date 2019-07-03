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

class BaseState {
    var stateName: String?
    var acceptanceDesp: String?
    
    var isAcceptingState: Bool = true
    var styleType: NodeStyleType = NodeStyleType.Normal
    
    var outs: [BaseState] = []
    
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
        return [self] + self.outs.reduce([], { $0 + $1.outsForNothing() })
    }
    
    func addOut(_ state: BaseState) {
        if !(self.outs.contains(where: { $0 === state })) {
            self.outs.append(state)
        }
    }
    
    //
    func graphicOuts() -> [BaseState] { return self.outs }
}

protocol ConditionalOutDelegate: AnyObject {
    func canStateGotoConditionalOut(_ s: BaseState) -> Bool
}

class DumbState: BaseState {
    weak var delegate: ConditionalOutDelegate?
    var conditionalOut: BaseState?
    override init() {
        super.init()
        self.acceptanceDesp = "ε"
    }
    override func canAcceptNothing() -> Bool { return true }
    override func canAccept(input c: Character) -> Bool { return false }
    override func outsForNothing() -> [BaseState] {
        var ret = super.outsForNothing()
        if let delegate = delegate,
            let conditionalOut = conditionalOut,
            delegate.canStateGotoConditionalOut(self) {
            ret.append(conditionalOut)
        }
        return ret
    }
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
