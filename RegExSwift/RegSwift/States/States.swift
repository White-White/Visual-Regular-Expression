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
    case `class`
    case accepted
}

class BaseState: NSObject {
    var stateName: String?
    var inputSetDescription: String?
    
    let stateType: StateType
    init(_ stateType: StateType) {
        self.stateType = stateType
    }
    
    //Operations
    func forwardWithEmptyInput() -> [BaseState] { fatalError() }
    func forwardWithInput(_ character: Character) -> [BaseState] { fatalError() }
    func connect(_ state: BaseState) { fatalError() }
    
    override var debugDescription: String { return "\(self.stateType)" }
}

class ValueState: BaseState {
    let character: Character
    var out: BaseState
    
    init(_ c: Character) {
        self.character = c
        self.out = AcceptState.shared
        super.init(.value)
    }
    
    override func forwardWithEmptyInput() -> [BaseState] {
        return [self]
    }
    override func forwardWithInput(_ character: Character) -> [BaseState] {
        return self.character == character ? [self.out] : []
    }
    override func connect(_ state: BaseState) {
        if self.out === AcceptState.shared {
            self.out = state
        } else {
            self.out.connect(state)
        }
    }
}

class ClassState: BaseState {
    let literalClass: LiteralsClass
    var out: BaseState

    init(_ literalClass: LiteralsClass) {
        self.literalClass = literalClass
        self.out = AcceptState.shared
        super.init(.class)
    }
    
    override func forwardWithEmptyInput() -> [BaseState] {
        return [self]
    }
    override func forwardWithInput(_ character: Character) -> [BaseState] {
        return self.literalClass.accepts(character) ? [self.out] : []
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
    
    init(primaryOut: BaseState, secondaryOut: BaseState) {
        self.primaryOut = primaryOut
        self.secondaryOut = secondaryOut
        super.init(.split)
    }
    
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
    
    init() {
        self.out = AcceptState.shared
        super.init(.dumb)
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
    
    init(with quantifier: QuantifierMenifest, repeatingState: BaseState) {
        self.repeatChecker = RepeatChecker(with: quantifier)
        self.repeatingState = repeatingState
        self.dummyEnd = DumbState()
        super.init(.repeat)
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
        //try to extract "|" operator
        let groupByAlternation = try (semanticUnits.split { $0.type == .Alternation }).map { (sUnits) -> Array<SemanticUnit> in
            guard !sUnits.isEmpty else {
                throw RegExSwiftError.fromType(RegExSwiftErrorType.invaludOperandAroundAlternation)
            }
            return Array(sUnits)
        }
        
        if groupByAlternation.count > 1 {
            var splitState = SplitState(primaryOut: try self.createHeadState(from: groupByAlternation[0]),
                                        secondaryOut: try self.createHeadState(from: groupByAlternation[1]))

            for index in 2..<groupByAlternation.count {
                splitState = SplitState(primaryOut: splitState,
                                        secondaryOut: try self.createHeadState(from: groupByAlternation[index]))
            }
            return splitState
        }
        
        //
        var semanticUnitIte = semanticUnits.makeIterator()
        var currentState: BaseState?
        
        while let semanticUnit = semanticUnitIte.next() {
            let resultState: BaseState
            switch semanticUnit.type {
            case .Literal:
                let literalSemantic = semanticUnit as! LiteralSemantic
                let valueState = ValueState(literalSemantic.literal)
                resultState = valueState
            case .Class:
                let classSemantic = (semanticUnit as! ClassSemantic)
                let classState = ClassState(classSemantic.literalClass)
                resultState = classState
            case .Group:
                let groupSemanticUnit = semanticUnit as! GroupSemantic
                let headStateFromGroup = try self.createHeadState(from: groupSemanticUnit.semanticUnits)
                resultState = headStateFromGroup
            case .Repeating:
                let repeatingSemantic = semanticUnit as! RepeatingSemantic
                let repeatingState = RepeatState(with: repeatingSemantic.quantifier, repeatingState: try self.createHeadState(from: [repeatingSemantic.semanticToRepeat]))
                resultState = repeatingState
            case .Alternation:
                fatalError()
            }
            
            currentState?.connect(resultState)
            currentState = resultState
        }
        
        return  currentState!
    }
}
