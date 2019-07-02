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
    func connect(_ state: BaseState) { fatalError() }
    
    //
    func graphicOuts() -> [BaseState] { return self.outs }
}

protocol InterStateOutDelegate where Self: AnyObject {
    func interState(_ inter: InterState, outsWith c: Character?) -> [BaseState]
}

class InterState: BaseState {
    weak var delegate: InterStateOutDelegate?
    
    init() {
        super.init(.InterState)
        self.acceptanceDesp = "ε"
    }
    
    override func canAcceptNothing() -> Bool {
        return true
    }
    
    override func canAccept(input c: Character) -> Bool {
        return false
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
    
    override func canAcceptNothing() -> Bool {
        return false
    }
    
    override func canAccept(input c: Character) -> Bool {
        return self.literalClass.accepts(c)
    }
    
    override func connect(_ state: BaseState) {
        self.isAccepted = false
        if self.outs.isEmpty {
            self.outs.append(state)
        } else {
            self.outs.forEach { $0.connect(state) }
        }
    }
}

class SplitState: BaseState {
    let splitEnd: InterState = InterState()
    
    init(_ outs: [BaseState]) {
        super.init(.SplitState)
        self.isAccepted = false
        outs.forEach {
            $0.connect(self.splitEnd)
            self.outs.append($0)
        }
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
    
    override func canAcceptNothing() -> Bool {
        return true
    }
    
    override func canAccept(input c: Character) -> Bool {
        return false
    }
    
    override func outsForNothing() -> [BaseState] {
        if self.repeatChecker.needRepeat() {
            return self.repeatingState.canAcceptNothing() ? self.repeatingState.outsForNothing() : []
        } else {
            let endStateOuts = self.endState.outsForNothing()
            
            
            if self.repeatChecker.canRepeat() {
                outs += self.repeatingState.outsWithEmpty()
            }
            return outs
        }
    }
    
//    override func outsFor(input c: Character?) -> [BaseState] {
//        var ret: [BaseState] = []
//        if self.repeatChecker.needRepeat() {
//            if c == nil {
//                ret.append(self)
//            }
//            ret += self.repeatingState.outsFor(input: c)
//        } else { //dont need repeat
//            if c == nil {
//                ret.append(self)
//                ret.append(self.endState)
//                ret += self.endState.outs.reduce([], {$0 + $1.outsFor(input: c)})
//            }
//            if self.repeatChecker.canRepeat() {
//                ret += self.repeatingState.outsFor(input: c)
//            }
//        }
//        return ret;
//    }
    
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
    func interState(_ inter: InterState, outsWith c: Character?) -> [BaseState] {
//        var ret: [BaseState] = []
//        if self.repeatChecker.needRepeat() {
//            if c == nil {
//                ret.append(self)
//            }
//            ret += self.repeatingState.outs(with: c)
//        } else { //dont need repeat
//            if c == nil {
//                ret.append(self)
//                ret.append(self.endState)
//                ret += self.endState.outs(with: c)
//            }
//            if self.repeatChecker.canRepeat() {
//                ret += self.repeatingState.outs(with: c)
//            }
//        }
//        return ret;
        return self.outsFor(input: c);
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
