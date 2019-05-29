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
    case accept
}

protocol BaseState {
    var stateType: StateType { get }
}

class ValueState: BaseState {
    let stateType: StateType = .value
    var outs: [BaseState]?
    let acceptanceChecker: AcceptanceChekcer
    
    init(acceptEmptyInput: Bool, acceptedCharacters:Set<Character>) {
        self.acceptanceChecker = AcceptanceChekcer(type: .include,
                                                   acceptedCharacters: acceptedCharacters,
                                                   canAcceptNil: acceptEmptyInput)
    }
}

class AntiValueState: BaseState {
    let stateType: StateType = .value
    var outs: [BaseState]?
    let acceptanceChecker: AcceptanceChekcer
    
    init(acceptEmptyInput: Bool, unacceptedCharacters:Set<Character>) {
        self.acceptanceChecker = AcceptanceChekcer(type: .exclude,
                                                   unacceptedCharacters: unacceptedCharacters,
                                                   canAcceptNil: acceptEmptyInput)
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
    let stateType: StateType = .accept
}

class StateHelper {
    func createStates(from semanticUnits: [SemanticUnit]) throws {
        
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
                    let splitState = ValueState(acceptEmptyInput: true, acceptedCharacters: [])
                    splitState.outs = [previousState, nextState]
                    stateStack.append(splitState)
                case .Dot:
                    let antiState = AntiValueState(acceptEmptyInput: false,
                                                   unacceptedCharacters: AcceptanceChekcer.whiteSpaceCharacters())
                    antiState.outs = [AcceptState()]
                    stateStack.append(antiState)
                case .Plus:
                    break
                case .Star:
                    break
                }
            default:
                let state = try self.createState(fromNonFunctionalSemanticUnit: semanticUnit)
                stateStack.append(state)
            }
        }
    }
    
    func createState(fromNonFunctionalSemanticUnit semanticUnit: SemanticUnit) throws -> BaseState {
        switch semanticUnit.semanticUnitType {
        case .functionalSymbol:
            fatalError()
        case .literalLexemeSequence:
            let literalSemanticUnit = semanticUnit as! LiteralSequenceSemantic
            let state = literalSemanticUnit.literals.reversed().reduce(nil) { (result, character) -> ValueState? in
                let valueState = ValueState(acceptEmptyInput: false, acceptedCharacters: [character])
                if let result = result {
                    valueState.outs = [result]
                } else {
                    valueState.outs = [AcceptState()]
                }
                return valueState
            }
            guard let literalStates = state else { throw RegExSwiftError("空的Literal 理论上不可能发生") }
            return literalStates
        case .oneClass:
            let classSemanticUnit = semanticUnit as! ClassExpressionSemantic
            let classState = ValueState(acceptEmptyInput: false, acceptedCharacters: classSemanticUnit.characterSet)
            classState.outs = [AcceptState()]
            return classState
        case .oneGroup:
            throw RegExSwiftError("tmp")
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
