//
//  State.swift
//  RegExSwift
//
//  Created by White on 2019/5/24.
//  Copyright © 2019 Ali-White. All rights reserved.
//

import Foundation

enum StateType {
    case InterState
    case ClassState
    case RepeatState
    case SplitState
}

class BaseState {
    var stateName: String?
    var acceptanceDesp: String?
    var stateType: StateType
    var isAccepted: Bool = true
    
    init(_ type: StateType) {
        self.stateType = type
    }
    
    var outs: [BaseState] = []
    
    //empty input
    func outsWithEmpty() -> [BaseState] { fatalError() }
    
    //find outs
    func outs(with c: Character) -> [BaseState] {
        return outs.filter { $0.canAccept(c: c) }
    }
    
    func canAccept(c: Character) -> Bool { fatalError() }
    
    //connect with other state
    func connect(_ state: BaseState) { fatalError() }
    
    //
    func graphicOuts() -> [BaseState] { return self.outs }
}

protocol InterStateOutDelegate where Self: AnyObject {
    func interState(_ inter: InterState, outsWith c: Character) -> [BaseState]
    func interStateWithEmpty(_ inter: InterState) -> [BaseState]
}

class InterState: BaseState {
    weak var delegate: InterStateOutDelegate?
    
    init() {
        super.init(.InterState)
        self.acceptanceDesp = "ε"
    }
    
    override func outs(with c: Character) -> [BaseState] {
        if let delegate = delegate {
            return delegate.interState(self, outsWith: c)
        }
        return super.outs(with: c)
    }
    
    override func outsWithEmpty() -> [BaseState] {
        if let delegate = delegate {
            return delegate.interStateWithEmpty(self)
        }
        return self.outs.reduce([], { $0 + $1.outsWithEmpty() })
    }
    
    override func connect(_ state: BaseState) {
        self.isAccepted = false
        self.outs.append(state)
    }
}

class ClassState: BaseState {
    let literalClass: LiteralsClass
    init(literalClass: LiteralsClass) {
        self.literalClass = literalClass
        super.init(.ClassState)
        self.acceptanceDesp = literalClass.criteriaDesp()
    }
    
    override func outsWithEmpty() -> [BaseState] { return [self] }
    
    override func canAccept(c: Character) -> Bool {
        return self.literalClass.accepts(c)
    }
    
    override func connect(_ state: BaseState) {
        self.isAccepted = false
        self.outs.append(state)
    }
}

class SplitState: BaseState {
    var splitStarts: [InterState] = []
    let splitEnd: InterState = InterState()
    
    init(_ outs: [BaseState]) {
        super.init(.SplitState)
        self.isAccepted = false
        outs.forEach {
            let splitStart = InterState()
            splitStart.connect($0)
            self.splitStarts.append(splitStart)
            $0.connect(self.splitEnd)
        }
        self.acceptanceDesp = "ε"
    }
    
    override func outsWithEmpty() -> [BaseState] {
        return self.splitStarts.reduce([], { $0 + $1.outsWithEmpty() })
    }
    
    override func outs(with c: Character) -> [BaseState] {
        return self.splitStarts.reduce([], { $0 + $1.outs(with: c) })
    }
    
    override func connect(_ state: BaseState) {
        self.splitEnd.connect(state)
    }
    
    override func graphicOuts() -> [BaseState] {
        return self.splitStarts
    }
}

class RepeatState: BaseState {
    let repeatChecker: RepeatChecker
    let repeatingState: BaseState
    private var endState: InterState = InterState()
    
    init(with quantifier: QuantifierMenifest, repeatingState: BaseState) {
        self.repeatChecker = RepeatChecker(with: quantifier)
        self.repeatingState = repeatingState
        self.repeatingState.connect(self.endState)
        super.init(.RepeatState)
        self.endState.delegate = self
        self.isAccepted = false
        self.acceptanceDesp = "ε"
    }
    
    override func outsWithEmpty() -> [BaseState] {
        if self.repeatChecker.needRepeat() {
            return self.repeatingState.outsWithEmpty()
        } else {
            var outs = self.endState.outs.reduce([], { $0 + $1.outsWithEmpty() })
            if self.repeatChecker.canRepeat() {
                outs += self.repeatingState.outsWithEmpty()
            }
            return outs
        }
    }
    
    override func outs(with c: Character) -> [BaseState] {
        if self.repeatChecker.needRepeat() {
            return self.repeatingState.outs(with: c)
        } else {
            var result: [BaseState] = []
            let realOuts = self.endState.outs.reduce([]) { return $0 + $1.outs(with: c) }
            result += realOuts
            if self.repeatChecker.canRepeat() {
                result += self.repeatingState.outs(with: c)
            }
            return result
        }
    }
    
    override func connect(_ state: BaseState) {
        self.endState.connect(state)
    }
    
    override func graphicOuts() -> [BaseState] {
        if self.repeatChecker.canZeroRepeat() {
            return [self.repeatingState, self.endState]
        } else {
            return [self.repeatingState]
        }
    }
}

extension RepeatState: InterStateOutDelegate {
    func interState(_ inter: InterState, outsWith c: Character) -> [BaseState] {
        return self.outs(with: c)
    }
    
    func interStateWithEmpty(_ inter: InterState) -> [BaseState] {
        return self.outsWithEmpty()
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
