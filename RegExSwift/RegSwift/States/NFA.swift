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
        startState.addOut(l, withWeight: .Important)
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
        startState.addOut(repeatingNFA.startState, withWeight: .Important)
        let endState = DumbState()
        repeatingNFA.endState.addOut(endState, withWeight: .Important)
        startState.addOut(endState)
        repeatingNFA.endState.conditionalOut = repeatingNFA.startState
        super.init(startState: startState, endState: endState)
        repeatingNFA.endState.delegate = self;
    }
}

extension RepeatNFA: ConditionalOutDelegate {
    func canStateGotoConditionalOutForNothing(_ s: BaseState) -> Bool {
        return self.repeatChecker.canRepeat()
    }
}
