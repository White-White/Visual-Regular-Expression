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
    case accepted
}

class BaseState {
    let stateType: StateType
    var outs: [BaseState]?
    func copy() -> BaseState { fatalError("Implementation needed") }
    
    init(_ stateType: StateType) {
        self.stateType = stateType
    }
}

class ValueState: BaseState {
    let acceptanceChecker: AcceptanceChekcer
    convenience init(acceptEmptyInput: Bool, isForExclude: Bool, characters:Set<Character>) {
        let acceptanceChecker: AcceptanceChekcer
        if isForExclude {
            acceptanceChecker = AcceptanceChekcer(type: .exclude,
                                                       unacceptedCharacters: characters,
                                                       canAcceptNil: acceptEmptyInput)
        } else {
            acceptanceChecker = AcceptanceChekcer(type: .include,
                                                       acceptedCharacters: characters,
                                                       canAcceptNil: acceptEmptyInput)
        }
        self.init(acceptanceChecker: acceptanceChecker)
    }
    
    private init(acceptanceChecker: AcceptanceChekcer) {
        self.acceptanceChecker = acceptanceChecker
        super.init(.value)
    }
    
    override func copy() -> BaseState {
        let newValueState = ValueState(acceptanceChecker: self.acceptanceChecker)
        newValueState.outs = self.outs
        return newValueState as BaseState
    }
}

class SplitState: BaseState {
    
    convenience init() {
        self.init(.split)
    }
    
    override func copy() -> BaseState {
        let newSplit = SplitState()
        newSplit.outs = self.outs
        return newSplit
    }
}

//class SplitState: BaseState {
//    let stateType: StateType = .split
//    let firstValueOut: ValueState
//    let secondValueOut: ValueState
//
//    init(firstValueOut: ValueState, secondValueOut: ValueState) {
//        self.firstValueOut = firstValueOut
//        self.secondValueOut = secondValueOut
//    }
//}

class AcceptState: BaseState {
    static let shared = AcceptState(.accepted)
    override func copy() -> BaseState {
        return AcceptState.shared
    }
}

class StateHelper {
    
    func createStates(from semanticUnits: [SemanticUnit]) throws -> BaseState {
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
                    
                    let nextState = try self.createState(fromNonFunctionalSemanticUnit: nextSemanticUnit)
                    let splitState = SplitState()
                    splitState.outs = [previousState, nextState]
                    stateStack.append(splitState)
                case .Dot:
                    let antiState = ValueState(acceptEmptyInput: false,
                               isForExclude: true,
                               characters: AcceptanceChekcer.whiteSpaceCharacters())
                    antiState.outs = [AcceptState.shared]
                    stateStack.append(antiState)
                case .Plus:
                    guard let previousState = stateStack.popLast() else { throw RegExSwiftError("SyntaxError: | 的前面没有内容") }
                    let sameState = previousState.copy()
                    sameState.outs = [sameState, AcceptState.shared]
                    previousState.outs = [sameState]
                    stateStack.append(previousState)
                case .Star:
                    guard let previousState = stateStack.popLast() else { throw RegExSwiftError("SyntaxError: | 的前面没有内容") }
                    previousState.outs = [previousState, AcceptState.shared]
                    stateStack.append(previousState)
                }
            default:
                let state = try self.createState(fromNonFunctionalSemanticUnit: semanticUnit)
                stateStack.append(state)
            }
        }
        
        guard let retState = stateStack.last else {
            throw RegExSwiftError("InternalError: There supposed to be at least one state in the stack")
        }
        
        return  retState
    }
    
    func createState(fromNonFunctionalSemanticUnit semanticUnit: SemanticUnit) throws -> BaseState {
        switch semanticUnit.semanticUnitType {
        case .functionalSymbol:
            fatalError()
        case .literalLexemeSequence:
            let literalSemanticUnit = semanticUnit as! LiteralSequenceSemantic
            let state = literalSemanticUnit.literals.reversed().reduce(nil) { (result, character) -> ValueState? in
                let valueState = ValueState(acceptEmptyInput: false, isForExclude: false, characters: [character])
                if let result = result {
                    valueState.outs = [result]
                } else {
                    valueState.outs = [AcceptState.shared]
                }
                return valueState
            }
            guard let literalStates = state else { throw RegExSwiftError("空的Literal 理论上不可能发生") }
            return literalStates
        case .oneClass:
            let classSemanticUnit = semanticUnit as! ClassExpressionSemantic
            let classState = ValueState(acceptEmptyInput: false, isForExclude: false, characters: classSemanticUnit.characterSet)
            classState.outs = [AcceptState.shared]
            return classState
        case .oneGroup:
            let groupSemanticUnit = semanticUnit as! GroupExpressionSemantic
            let stateFromGroup = try self.createStates(from: groupSemanticUnit.semanticUnits)
            return stateFromGroup
        }
    }
    
//    static func valueState(with value: Character) -> ValueState {
//        return ValueStateImp.init(value: value)
//    }
//
//    static func splitState(withOutPrimary outPrimary: BaseState, outSecondary: BaseState) -> SplitState {
//        return SplitStateImp.init(outPrimary: outPrimary, outSecondary: outSecondary)
//    }
//
//    static func createAcceptingState() -> AcceptingState {
//        return AcceptingStateImp()
//    }
}
