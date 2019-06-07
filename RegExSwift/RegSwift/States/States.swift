//
//  State.swift
//  RegExSwift
//
//  Created by White on 2019/5/24.
//  Copyright © 2019 Ali-White. All rights reserved.
//

import Foundation

enum StateType {
    case value
    case dumb
    case split
    case `repeat`
    case accepted
}

class BaseState: NSObject {
    let stateName: String
    let stateType: StateType
    init(_ stateType: StateType, stateName: String) { self.stateType = stateType; self.stateName = stateName }
    func forwardWithEmptyInput() -> [BaseState] { fatalError() }
    func forwardWithInput(_ character: Character) -> [BaseState] { fatalError() }
    func connect(_ state: BaseState) { fatalError() }
}

class ValueState: BaseState {
    let acceptanceChecker: AcceptanceChecker
    var out: BaseState
    override var debugDescription: String { return String(format: "Value %@", self.stateName) }
    
    convenience init(isForExclude: Bool, characters:Set<Character>, stateName: String) {
        let acceptanceChecker: AcceptanceChecker = AcceptanceChecker(type: isForExclude ? .exclude : .include, characters: characters)
        self.init(acceptanceChecker: acceptanceChecker, stateName: stateName)
    }
    
    private init(acceptanceChecker: AcceptanceChecker, stateName: String) {
        self.acceptanceChecker = acceptanceChecker
        self.out = AcceptState.shared
        super.init(.value, stateName: stateName)
    }
    
    //MARK: ValueState Operations
    override func forwardWithEmptyInput() -> [BaseState] {
        return [self]
    }
    override func forwardWithInput(_ character: Character) -> [BaseState] {
        return self.acceptanceChecker.canAccept(character) ? [self.out] : []
    }
    override func connect(_ state: BaseState) {
        if self.out === AcceptState.shared {
            self.out = state
        } else {
            self.out.connect(state)
        }
    }
}

class SplitState: BaseState {
    var primaryOut: BaseState
    var secondaryOut: BaseState
    
    override var debugDescription: String { return String(format: "Split %@", self.stateName) }
    
    init(primaryOut: BaseState, secondaryOut: BaseState, stateName: String) {
        self.primaryOut = primaryOut
        self.secondaryOut = secondaryOut
        super.init(.split, stateName: stateName)
    }
    
    //MARK: SplitState Operations
    override func forwardWithEmptyInput() -> [BaseState] {
        return self.primaryOut.forwardWithEmptyInput() + self.secondaryOut.forwardWithEmptyInput()
    }
    override func forwardWithInput(_ character: Character) -> [BaseState] {
        fatalError() //SplitState is not designed to forward with input
    }
    override func connect(_ state: BaseState) {
        primaryOut.connect(state)
        secondaryOut.connect(state)
    }
}


//MARK: - Dummy

protocol DumbStateDelegate: NSObjectProtocol {
    func dummy_forwardWithEmptyInput() -> [BaseState]
    func dummy_forwardWithInput(_ character: Character) -> [BaseState]
}

class DumbState: BaseState {
    var out: BaseState
    weak var delegate: DumbStateDelegate?
    override var debugDescription: String { return String(format: "Dummy %@", self.stateName) }
    
    init(stateName: String) {
        self.out = AcceptState.shared
        super.init(.dumb, stateName: stateName)
    }
    
    override func forwardWithEmptyInput() -> [BaseState] {
        return self.delegate!.dummy_forwardWithEmptyInput()
    }
    override func forwardWithInput(_ character: Character) -> [BaseState] {
        return self.delegate!.dummy_forwardWithInput(character)
    }
    override func connect(_ state: BaseState) {
        guard self.out === AcceptState.shared else { fatalError() }
        self.out = state
    }
}

//MARK: - RepeatState

class RepeatState: BaseState {
    let repeatChecker: RepeatChecker
    let repeatingState: BaseState
    var dummyEnd: DumbState
    
    override var debugDescription: String { return String(format: "Repeat %@", self.stateName) }
    
    init(with functionalSemanticUnit: FunctionalSemantic, repeatingState: BaseState, stateName: String) {
        self.repeatChecker = RepeatChecker(with: functionalSemanticUnit)
        self.repeatingState = repeatingState
        self.dummyEnd = DumbState(stateName: stateName + "_end")
        super.init(.repeat, stateName: stateName)
        self.dummyEnd.delegate = self
        self.repeatingState.connect(self.dummyEnd)
    }
    
    //MARK: RepeatState Operations
    override func forwardWithEmptyInput() -> [BaseState] {
        if self.repeatChecker.repeatCriteriaHasBeenMet() {
            var result: [BaseState] = []
            result += self.dummyEnd.out.forwardWithEmptyInput()
            if self.repeatChecker.canRepeat() {
                result += self.repeatingState.forwardWithEmptyInput()
            }
            return result
        } else {
            return self.repeatingState.forwardWithEmptyInput()
        }
    }
    
    override func forwardWithInput(_ character: Character) -> [BaseState] {
        if self.repeatChecker.repeatCriteriaHasBeenMet() {
            var result: [BaseState] = []
            result += self.dummyEnd.out.forwardWithInput(character)
            if self.repeatChecker.canRepeat() {
                result += self.repeatingState.forwardWithInput(character)
            }
            return result
        } else {
            return self.repeatingState.forwardWithInput(character)
        }
    }
    
    override func connect(_ state: BaseState) {
        self.dummyEnd.connect(state)
    }
}

extension RepeatState: DumbStateDelegate {
    func dummy_forwardWithEmptyInput() -> [BaseState] {
        return self.forwardWithEmptyInput()
    }
    
    func dummy_forwardWithInput(_ character: Character) -> [BaseState] {
        return self.dummy_forwardWithInput(character)
    }
}


class AcceptState: BaseState {
    static let shared = AcceptState(.accepted, stateName: "Accept")
    
    override var debugDescription: String { return String(format: "Accept %@", self.stateName) }
    
    //MARK: AcceptState Operations
    override func forwardWithEmptyInput() -> [BaseState] {
        return [self]
    }
    override func forwardWithInput(_ character: Character) -> [BaseState] {
        fatalError()
    }
    override func connect(_ state: BaseState) {
        fatalError()
    }
}


private struct StateNameCreator {
    var start = 0
    mutating func nextName() -> String {
        let temp = start
        start += 1
        return "S\(temp)"
    }
}

class StatesCreator {
    
    static func createHeadState(from semanticUnits: [SemanticUnit]) throws -> BaseState {
        var stateNameCreator = StateNameCreator()
        let states = try self.createStates(from: semanticUnits, stateNameCreator: &stateNameCreator)
        return states.first!
    }
    
    private static func createStates(from semanticUnits: [SemanticUnit], stateNameCreator: inout StateNameCreator) throws -> [BaseState] {
        
        var semanticUnitIte = semanticUnits.makeIterator()
        var stateStack: [BaseState] = []
        
        while let semanticUnit = semanticUnitIte.next() {
            switch semanticUnit.semanticUnitType {
            case .functionalSymbol:
                let functionalSemanticUnit = semanticUnit as! FunctionalSemantic
                switch functionalSemanticUnit.functionalSemanticType {
                case .Alternation:
                    guard let previousState = stateStack.popLast() else { throw RegExSwiftError("SyntaxError: | 的前面没有内容") }
                    guard let nextSemanticUnit = semanticUnitIte.next() else { throw RegExSwiftError("SyntaxError: | 的后面没有内容") }
                    guard nextSemanticUnit.semanticUnitType != .functionalSymbol else {
                        throw RegExSwiftError("SyntaxError: | 右侧的内容非法")
                    }
                    
                    let statesAtRightSide = try self.createStates(from: [nextSemanticUnit], stateNameCreator: &stateNameCreator)
                    let splitState = SplitState(primaryOut: previousState,
                                                secondaryOut: statesAtRightSide.first!, stateName: stateNameCreator.nextName())
                    stateStack.last?.connect(splitState)
                    stateStack.append(splitState)
                case .Dot:
                    let antiState = ValueState(isForExclude: true, characters: AcceptanceChecker.whiteSpaceCharacters(), stateName: stateNameCreator.nextName())
                    stateStack.last?.connect(antiState)
                    stateStack.append(antiState)
                case .Plus:
                    fallthrough
                case .Star:
                    guard let previousState = stateStack.popLast() else { throw RegExSwiftError("SyntaxError: \(functionalSemanticUnit) 的前面没有内容") }
                    let repeatState = RepeatState(with: functionalSemanticUnit, repeatingState: previousState, stateName: stateNameCreator.nextName())
                    stateStack.last?.connect(repeatState)
                    stateStack.append(repeatState)
                }
            case .literalLexemeSequence:
                let state = (semanticUnit as! LiteralSequenceSemantic).literals.reduce(nil) { (previous, character) -> ValueState? in
                    let valueState = ValueState(isForExclude: false, characters: [character], stateName: stateNameCreator.nextName())
                    if let previous = previous {
                        previous.connect(valueState)
                        return previous
                    } else {
                        return valueState
                    }
                }
                guard let literalStates = state else { throw RegExSwiftError("空的Literal 理论上不可能发生") }
                stateStack.last?.connect(literalStates)
                stateStack.append(literalStates)
            case .oneClass:
                let classState = ValueState(isForExclude: false, characters: (semanticUnit as! ClassExpressionSemantic).characterSet, stateName: stateNameCreator.nextName())
                stateStack.last?.connect(classState)
                stateStack.append(classState)
            case .oneGroup:
                let groupSemanticUnit = semanticUnit as! GroupExpressionSemantic
                let statesFromGroup = try self.createStates(from: groupSemanticUnit.semanticUnits, stateNameCreator: &stateNameCreator)
                guard !statesFromGroup.isEmpty else { continue }
                stateStack.last?.connect(statesFromGroup.first!)
                stateStack.append(contentsOf: statesFromGroup)
            }
        }
        return  stateStack
    }
}
