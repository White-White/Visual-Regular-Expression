//
//  State.swift
//  RegExSwift
//
//  Created by White on 2019/5/24.
//  Copyright © 2019 Ali-White. All rights reserved.
//

import Foundation

enum StateType {
    case DumbState
    case ClassState
    case RepeatState
    case SplitState
}

enum NodeStyleType {
    case Start
    case Normal
    case Highlighted
}

class BaseState {
    var stateName: String?
    var acceptanceDesp: String?
    var stateType: StateType
    
    var isAccepted: Bool = true
    var styleType: NodeStyleType = NodeStyleType.Normal
    
    init(_ type: StateType) {
        self.stateType = type
    }
    
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
        if self.outs.isEmpty { fatalError() }
        let ret = self.outs.filter { $0.canAcceptNothing() }
        if ret.count == self.outs.count {
            return ret.reduce([], { $0 + $1.outsForNothing() })
        } else {
            return [self] + ret.reduce([], { $0 + $1.outsForNothing() })
        }
    }
    
    //connect with other state
    func connect(_ state: BaseState) {
        self.isAccepted = false
        if self.outs.isEmpty {
            self.outs.append(state)
        } else {
            self.outs.forEach({ $0.connect(state) })
        }
    }
    
    //
    func graphicOuts() -> [BaseState] { return self.outs }
}

class DumbState: BaseState {
    init() {
        super.init(.DumbState)
        self.acceptanceDesp = "ε"
    }
    override func canAcceptNothing() -> Bool { return true }
    override func canAccept(input c: Character) -> Bool { return false }
}

class ClassState: BaseState {
    let literalClass: LiteralsClass
    init(literalClass: LiteralsClass) {
        self.literalClass = literalClass
        super.init(.ClassState)
        self.acceptanceDesp = literalClass.criteriaDesp()
    }
    
    override func canAcceptNothing() -> Bool {
        return false
    }
    override func canAccept(input c: Character) -> Bool {
        return self.literalClass.accepts(c)
    }
}

class SplitState: BaseState {
    let splitEnd: DumbState = DumbState()
    
    init(_ outs: [BaseState]) {
        super.init(.SplitState)
        self.isAccepted = false
        self.outs = outs
        self.outs.forEach({ $0.connect(self.splitEnd) })
        self.acceptanceDesp = "ε"
    }
    
    override func canAcceptNothing() -> Bool {
        return true
    }
    
    override func canAccept(input c: Character) -> Bool {
        return false
    }
    
    override func connect(_ state: BaseState) {
        self.splitEnd.connect(state)
    }
}

class RepeatEndState: BaseState {
    weak var repeatState: RepeatState!
    init() {
        super.init(.DumbState)
        self.acceptanceDesp = "ε"
    }
    override func canAcceptNothing() -> Bool { return true }
    override func canAccept(input c: Character) -> Bool { return false }
    override func outsFor(input c: Character) -> [BaseState] {
        if repeatState.repeatChecker.needRepeat() {
            return repeatState.repeatingState.outsFor(input: c)
        } else {
            var ret = super.outsFor(input: c)
            if repeatState.repeatChecker.canRepeat() {
                ret += repeatState.repeatingState.outsFor(input: c)
            }
            return ret
        }
    }
    override func outsForNothing() -> [BaseState] {
        
        
        if repeatState.repeatChecker.needRepeat() {
            return repeatState.repeatingState.outsForNothing()
        } else {
            var ret = super.outsForNothing()
            if repeatState.repeatChecker.canRepeat() {
                ret += repeatState.repeatingState.outsForNothing()
            }
            return ret
        }
    }
}

class RepeatState: BaseState {
    let repeatChecker: RepeatChecker
    let repeatingState: BaseState
    private var repeatEnd: RepeatEndState = RepeatEndState()
    
    init(with quantifier: QuantifierMenifest, repeatingState: BaseState) {
        self.repeatChecker = RepeatChecker(with: quantifier)
        self.repeatingState = repeatingState
        self.repeatingState.connect(self.repeatEnd)
        super.init(.RepeatState)
        self.repeatEnd.repeatState = self
        self.isAccepted = false
        self.acceptanceDesp = "ε"
    }
    
    override func canAcceptNothing() -> Bool {
        return true
    }
    
    override func canAccept(input c: Character) -> Bool {
        return false
    }
    
    override func outsForNothing() -> [BaseState] {
        if self.repeatChecker.needRepeat() {
            return self.repeatingState.outsForNothing()
        } else {
            return self.repeatEnd.outsForNothing()
        }
    }
    
    override func outsFor(input c: Character) -> [BaseState] {
        if self.repeatChecker.needRepeat() {
            return self.repeatingState.outsFor(input: c)
        } else {
            return self.repeatEnd.outsFor(input: c)
        }
    }
    
    override func connect(_ state: BaseState) {
        self.repeatEnd.connect(state)
    }
    
    override func graphicOuts() -> [BaseState] {
        return [self.repeatingState, self.repeatEnd]
    }
}

class StatesCreator {
    
    static func createHeadState(from semanticUnits: [SemanticUnit]) throws -> BaseState {
        //extract "|"
        let smticsSepByAlter = try (semanticUnits.split { $0.type == .Alternation }).map { (sUnits) -> Array<SemanticUnit> in
            guard !sUnits.isEmpty else {
                throw RegExSwiftError.fromType(RegExSwiftErrorType.invaludOperandAroundAlternation)
            }
            return Array(sUnits)
        }
        
        let headStates = try smticsSepByAlter.map { try self.createStatesWithoutAlter(from: $0) }
        return headStates.count == 1 ? headStates[0] : SplitState(headStates)
    }
    
    private static func createStatesWithoutAlter(from semanticUnits: [SemanticUnit]) throws -> BaseState {
        guard !semanticUnits.isEmpty else { fatalError() }
        
        //
        var semanticUnitIte = semanticUnits.makeIterator()
        var stateStack: [BaseState] = []
        
        while let semanticUnit = semanticUnitIte.next() {
            switch semanticUnit.type {
            case .Literal:
                let literalSemantic = semanticUnit as! LiteralSemantic
                let literalClass = LiteralsClass(type: .Include, characters: Set(arrayLiteral: literalSemantic.literal))
                let classState = ClassState(literalClass: literalClass)
                stateStack.last?.connect(classState)
                stateStack.append(classState)
            case .Class:
                let classSemantic = (semanticUnit as! ClassSemantic)
                let classState = ClassState(literalClass: classSemantic.literalClass)
                stateStack.last?.connect(classState)
                stateStack.append(classState)
            case .Group:
                let groupSemanticUnit = semanticUnit as! GroupSemantic
                //there can be alter semantic units in a group
                let headStateFromGroup = try self.createHeadState(from: groupSemanticUnit.semanticUnits)
                stateStack.last?.connect(headStateFromGroup)
                stateStack.append(headStateFromGroup)
            case .Repeating:
                let repeatingSemantic = semanticUnit as! RepeatingSemantic
                let stateToRepeat = try self.createHeadState(from: [repeatingSemantic.semanticToRepeat])
                let repeatingState = RepeatState(with: repeatingSemantic.quantifier, repeatingState: stateToRepeat)
                stateStack.last?.connect(repeatingState)
                stateStack.append(repeatingState)
            case .Alternation:
                fatalError()
            }
        }
        
        return  stateStack.first!
    }
}
