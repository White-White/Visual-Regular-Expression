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
    var outs: [BaseState]?
    
    init(_ stateType: StateType) {
        self.stateType = stateType
    }
}

class ValueState: BaseState {
    let acceptanceChecker: AcceptanceChecker
    
    convenience init(isForExclude: Bool, characters:Set<Character>) {
        let acceptanceChecker: AcceptanceChecker = AcceptanceChecker(type: isForExclude ? .exclude : .include, characters: characters)
        self.init(acceptanceChecker: acceptanceChecker)
    }
    
    private init(acceptanceChecker: AcceptanceChecker) {
        self.acceptanceChecker = acceptanceChecker
        super.init(.value)
    }
}

class SplitState: BaseState {
    convenience init() {
        self.init(.split)
    }
}

class RepeatState: BaseState {
    convenience init() {
        self.init(.repeat)
    }
}


class AcceptState: BaseState {
    static let shared = AcceptState(.accepted)
}

class StateHelper {
    
    func createStates(from semanticUnits: [SemanticUnit]) throws -> BaseState {
        var semanticUnitIte = semanticUnits.makeIterator()
        var bufferedState: BaseState?
        
        while let semanticUnit = semanticUnitIte.next() {
            switch semanticUnit.semanticUnitType {
            case .functionalSymbol:
                let functionalSemanticUnit = semanticUnit as! FunctionalSemantic
                switch functionalSemanticUnit.functionalSemanticType {
                case .Alternation:
                    guard let previousState = bufferedState else { throw RegExSwiftError("SyntaxError: | 的前面没有内容") }
                    guard let nextSemanticUnit = semanticUnitIte.next() else { throw RegExSwiftError("SyntaxError: | 的后面没有内容") }
                    guard nextSemanticUnit.semanticUnitType != .functionalSymbol else {
                        throw RegExSwiftError("SyntaxError: | 右侧的内容非法")
                    }
                    
                    let nextState = try self.createState(fromNonFunctionalSemanticUnit: nextSemanticUnit)
                    let splitState = SplitState()
                    splitState.outs = [previousState, nextState]
                    bufferedState = splitState
                case .Dot:
                    let antiState = ValueState(isForExclude: true, characters: AcceptanceChecker.whiteSpaceCharacters())
                    if let previousState = bufferedState {
                        connect(previousState, antiState)
                        bufferedState = previousState
                    } else {
                        bufferedState = antiState
                    }
                case .Plus:
                    guard let previousState = bufferedState else { throw RegExSwiftError("SyntaxError: + 的前面没有内容") }
                case .Star:
                    guard let previousState = bufferedState else { throw RegExSwiftError("SyntaxError: * 的前面没有内容") }
                }
            default:
                let state = try self.createState(fromNonFunctionalSemanticUnit: semanticUnit)
                bufferedState = state
            }
        }
        
        guard let retState = bufferedState else {
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
                let valueState = ValueState(isForExclude: false, characters: [character])
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
            let classState = ValueState(isForExclude: false, characters: classSemanticUnit.characterSet)
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
    
    private func connect(_ preState: BaseState, _ nextState: BaseState) {
        if let outs = preState.outs {
            outs.forEach { connect($0, nextState) }
        } else {
            preState.outs = [nextState]
        }
    }
}
