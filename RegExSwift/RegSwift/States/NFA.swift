//
//  NFA.swift
//  RegExSwift
//
//  Created by White on 2019/7/3.
//  Copyright © 2019 Ali-White. All rights reserved.
//

import Foundation

class BaseNFA {
    let startState: BaseState
    let endState: BaseState
    init(startState: BaseState, endState: BaseState) {
        self.startState = startState
        self.endState = endState
    }
    func connect(with nextNfa: BaseNFA) {
        nextNfa.startState.outs.forEach({ endState.addOut($0) })
    }
}

class LiteralNFA: BaseNFA {
    init(_ l: LiteralState) {
        let startState = DumbState()
        startState.addOut(l)
        super.init(startState: startState, endState: l)
    }
}

class SplitNFA: BaseNFA {
    init(outNFAs: [BaseNFA]) {
        let startState = DumbState()
        startState.outs = outNFAs.map({ $0.startState })
        let endState = DumbState()
        outNFAs.forEach({ $0.endState.addOut(endState) })
        super.init(startState: startState, endState: endState)
    }
}

class RepeatNFA: BaseNFA {
    let repeatChecker: RepeatChecker
    
    init(repeatingNFA: BaseNFA, quantifier: QuantifierMenifest) {
        self.repeatChecker = RepeatChecker(with: quantifier)
        let startState = DumbState()
        startState.addOut(repeatingNFA.startState)
        let endState = DumbState()
        repeatingNFA.endState.addOut(endState)
        startState.addOut(endState)
        
        repeatingNFA.endState.condi
        repeatingNFA.endState.addOut(repeatingNFA.startState) //potential recursive
        super.init(startState: startState, endState: endState)
    }
}


//class RepeatState: BaseState {
//    let repeatChecker: RepeatChecker
//    let repeatingState: BaseState
//    private var repeatEnd: RepeatEndState = RepeatEndState()
//
//    init(with quantifier: QuantifierMenifest, repeatingState: BaseState) {
//        self.repeatChecker = RepeatChecker(with: quantifier)
//        self.repeatingState = repeatingState
//        self.repeatingState.connect(self.repeatEnd)
//        super.init(.RepeatState)
//        self.repeatEnd.repeatState = self
//        self.isAccepted = false
//        self.acceptanceDesp = "ε"
//    }
//
//    override func canAcceptNothing() -> Bool {
//        return true
//    }
//
//    override func canAccept(input c: Character) -> Bool {
//        return false
//    }
//
//    override func outsForNothing() -> [BaseState] {
//        if self.repeatChecker.needRepeat() {
//            return self.repeatingState.outsForNothing()
//        } else {
//            return self.repeatEnd.outsForNothing()
//        }
//    }
//
//    override func outsFor(input c: Character) -> [BaseState] {
//        if self.repeatChecker.needRepeat() {
//            return self.repeatingState.outsFor(input: c)
//        } else {
//            return self.repeatEnd.outsFor(input: c)
//        }
//    }
//
//    override func connect(_ state: BaseState) {
//        self.repeatEnd.connect(state)
//    }
//
//    override func graphicOuts() -> [BaseState] {
//        return [self.repeatingState, self.repeatEnd]
//    }
//}

//class RepeatEndState: BaseState {
//    weak var repeatState: RepeatState!
//    init() {
//        super.init(.DumbState)
//        self.acceptanceDesp = "ε"
//    }
//    override func canAcceptNothing() -> Bool { return true }
//    override func canAccept(input c: Character) -> Bool { return false }
//    override func outsFor(input c: Character) -> [BaseState] {
//        if repeatState.repeatChecker.needRepeat() {
//            return repeatState.repeatingState.outsFor(input: c)
//        } else {
//            var ret = super.outsFor(input: c)
//            if repeatState.repeatChecker.canRepeat() {
//                ret += repeatState.repeatingState.outsFor(input: c)
//            }
//            return ret
//        }
//    }
//    override func outsForNothing() -> [BaseState] {
//
//
//        if repeatState.repeatChecker.needRepeat() {
//            return repeatState.repeatingState.outsForNothing()
//        } else {
//            var ret = super.outsForNothing()
//            if repeatState.repeatChecker.canRepeat() {
//                ret += repeatState.repeatingState.outsForNothing()
//            }
//            return ret
//        }
//    }
//}




