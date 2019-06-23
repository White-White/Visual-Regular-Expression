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
}

class BaseState: NSObject {
    var stateName: String?
    var inputsDesp: String?
    
    var outs: [BaseState] = []
    let stateType: StateType
    var isAccepted: Bool
    init(_ stateType: StateType, isAccepted: Bool) {
        self.stateType = stateType
        self.isAccepted = isAccepted
    }

    func connect(_ state: BaseState) {
        self.outs.forEach { $0.connect(state) }
        self.isAccepted = false
    }
    
    //find outs.
    //when input is nil, it's empty input
    func outs(with c: Character?) -> [BaseState] { fatalError() }
    func possibleOuts() -> [BaseState] { return self.outs }
    
    //Debug
    override var debugDescription: String { return "\(self.stateType)" }
}

class ClassState: BaseState {
    let literalClass: LiteralsClass
    init(_ literalClass: LiteralsClass) {
        self.literalClass = literalClass
        super.init(.class, isAccepted: true)
        self.inputsDesp = literalClass.criteriaDesp()
    }
    override func outs(with c: Character?) -> [BaseState] {
        if let c = c {
            return self.literalClass.accepts(c) ? self.outs : []
        } else {
            return [self]
        }
    }
    override func connect(_ state: BaseState) {
        super.connect(state)
        if self.outs.isEmpty {
            self.outs.append(state)
        }
    }
}

class ValueState: ClassState {
    init(_ c: Character) {
        super.init(LiteralsClass(type: .Include, characters: Set(arrayLiteral: c)))
    }
}

class SplitState: BaseState {
    init(primaryOut: BaseState, secondaryOut: BaseState) {
        super.init(.split, isAccepted: false)
        self.outs.append(contentsOf: [primaryOut, secondaryOut])
        self.inputsDesp = "ε"
    }
    
    override func outs(with c: Character?) -> [BaseState] {
        if let _ = c {
            fatalError() //SplitState is not designed to forward with any input
        } else {
            return self.outs.reduce([]) { return $0 + $1.outs(with: nil) }
        }
    }
}


//MARK: - Dummy
protocol SplitOutStateDelegate: NSObjectProtocol {
    func splitEnding_outs(with c: Character?) -> [BaseState]
}

private class SplitOutState: BaseState {
    weak var delegate: SplitOutStateDelegate?
    init() {
        super.init(.dumb, isAccepted: true)
    }
    
    override func outs(with c: Character?) -> [BaseState] {
        return self.delegate!.splitEnding_outs(with: c)
    }
    override func connect(_ state: BaseState) {
        super.connect(state)
        if self.outs.isEmpty {
            self.outs.append(state)
        }
    }
}

//MARK: - RepeatState

class RepeatState: BaseState {
    let repeatChecker: RepeatChecker
    let repeatingState: BaseState
    private var endingState: SplitOutState
    
    init(with quantifier: QuantifierMenifest, repeatingState: BaseState) {
        self.repeatChecker = RepeatChecker(with: quantifier)
        self.repeatingState = repeatingState
        self.endingState = SplitOutState()
        super.init(.repeat, isAccepted: false)
        self.endingState.delegate = self
        self.repeatingState.connect(self.endingState)
        self.outs.append(contentsOf: [self.repeatingState, self.endingState])
    }
    
    override func outs(with c: Character?) -> [BaseState] {
        if self.repeatChecker.needRepeat() {
            return self.repeatingState.outs(with: c)
        } else {
            var result: [BaseState] = []
            let realOuts = self.endingState.outs.reduce([]) { return $0 + $1.outs(with: nil) }
            result += realOuts
            if self.repeatChecker.canRepeat() {
                result += self.repeatingState.outs(with: c)
            }
            return result
        }
    }
    
    override func connect(_ state: BaseState) {
        self.endingState.connect(state)
    }
}

extension RepeatState: SplitOutStateDelegate {
    func splitEnding_outs(with c: Character?) -> [BaseState] {
        return self.outs(with: c)
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
            if currentState == nil {
                currentState = resultState
            }
        }
        
        return  currentState!
    }
}
