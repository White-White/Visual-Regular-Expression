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
    case split
    case `repeat`
    case accepted
}

class BaseState {
    let stateType: StateType
    init(_ stateType: StateType) { self.stateType = stateType }
    func forwardWithEmptyInput() -> [BaseState] { fatalError() }
    func forwardWithInput(_ character: Character) -> [BaseState] { fatalError() }
    func connect(_ state: BaseState) { fatalError() }
}

class ValueState: BaseState {
    let acceptanceChecker: AcceptanceChecker
    var out: BaseState
    
    convenience init(isForExclude: Bool, characters:Set<Character>) {
        let acceptanceChecker: AcceptanceChecker = AcceptanceChecker(type: isForExclude ? .exclude : .include, characters: characters)
        self.init(acceptanceChecker: acceptanceChecker)
    }
    
    private init(acceptanceChecker: AcceptanceChecker) {
        self.acceptanceChecker = acceptanceChecker
        self.out = AcceptState.shared
        super.init(.value)
    }
    
    //MARK: ValueState Operations
    override func forwardWithEmptyInput() -> [BaseState] {
        return [self]
    }
    override func forwardWithInput(_ character: Character) -> [BaseState] {
        return self.acceptanceChecker.canAccept(character) ? [self.out] : []
    }
    override func connect(_ state: BaseState) {
        self.out = state
    }
}

class SplitState: BaseState {
    var primaryOut: BaseState
    var secondaryOut: BaseState
    
    init(primaryOut: BaseState, secondaryOut: BaseState) {
        self.primaryOut = primaryOut
        self.secondaryOut = secondaryOut
        super.init(.split)
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

class RepeatState: BaseState {
    let repeatChecker: RepeatChecker
    let repeatingState: BaseState
    var out: BaseState
    
    init(with functionalSemanticUnit: FunctionalSemantic, repeatingState: BaseState) {
        self.repeatChecker = RepeatChecker(with: functionalSemanticUnit)
        self.repeatingState = repeatingState
        self.out = AcceptState.shared
        super.init(.repeat)
        self.repeatingState.connect(self)
    }
    
    //MARK: RepeatState Operations
    override func forwardWithEmptyInput() -> [BaseState] {
        if self.repeatChecker.repeatCriteriaHasBeenMet() {
            var result: [BaseState] = []
            result += self.out.forwardWithEmptyInput()
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
            result += self.out.forwardWithInput(character)
            if self.repeatChecker.canRepeat() {
                result += self.repeatingState.forwardWithInput(character)
            }
            return result
        } else {
            return self.repeatingState.forwardWithInput(character)
        }
    }
    
    override func connect(_ state: BaseState) {
        self.out = state
    }
}


class AcceptState: BaseState {
    static let shared = AcceptState(.accepted)
    
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

class StatesCreator {
    
    static func createHeadState(from semanticUnits: [SemanticUnit]) throws -> BaseState {
        let states = try self.createStates(from: semanticUnits)
        return states.first!
    }
    
    private static func createStates(from semanticUnits: [SemanticUnit]) throws -> [BaseState] {
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
                    
                    let statesAtRightSide = try self.createStates(from: [nextSemanticUnit])
                    let splitState = SplitState(primaryOut: previousState,
                                                secondaryOut: statesAtRightSide.first!)
                    stateStack.last?.connect(splitState)
                    stateStack.append(splitState)
                case .Dot:
                    let antiState = ValueState(isForExclude: true, characters: AcceptanceChecker.whiteSpaceCharacters())
                    stateStack.last?.connect(antiState)
                    stateStack.append(antiState)
                case .Plus:
                    fallthrough
                case .Star:
                    guard let previousState = stateStack.popLast() else { throw RegExSwiftError("SyntaxError: \(functionalSemanticUnit) 的前面没有内容") }
                    let repeatState = RepeatState(with: functionalSemanticUnit, repeatingState: previousState)
                    stateStack.last?.connect(repeatState)
                    stateStack.append(repeatState)
                }
            case .literalLexemeSequence:
                let literalState = try self.createState(fromLiteralSemanticUnit: semanticUnit as! LiteralSequenceSemantic)
                stateStack.last?.connect(literalState)
                stateStack.append(literalState)
            case .oneClass:
                let classState = ValueState(isForExclude: false, characters: (semanticUnit as! ClassExpressionSemantic).characterSet)
                stateStack.last?.connect(classState)
                stateStack.append(classState)
            case .oneGroup:
                let groupSemanticUnit = semanticUnit as! GroupExpressionSemantic
                let statesFromGroup = try self.createStates(from: groupSemanticUnit.semanticUnits)
                guard !statesFromGroup.isEmpty else { continue }
                stateStack.last?.connect(statesFromGroup.first!)
                stateStack.append(contentsOf: statesFromGroup)
            }
        }
        return  stateStack
    }
    
    private static func createState(fromLiteralSemanticUnit literalSemanticUnit: LiteralSequenceSemantic) throws -> BaseState {
        let state = literalSemanticUnit.literals.reduce(nil) { (previous, character) -> ValueState? in
            let valueState = ValueState(isForExclude: false, characters: [character])
            if let previous = previous {
                previous.connect(valueState)
                return previous
            } else {
                return valueState
            }
        }
        guard let literalStates = state else { throw RegExSwiftError("空的Literal 理论上不可能发生") }
        return literalStates
    }
}
