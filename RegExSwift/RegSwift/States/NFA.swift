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
    private let endState: BaseState
    var nextNFA: BaseNFA?
    
    init(startState: BaseState, endState: BaseState) {
        self.startState = startState
        self.endState = endState
    }
    
    func connect(with nextNFA: BaseNFA) {
        if let myNextNFA = self.nextNFA {
            myNextNFA.connect(with: nextNFA)
            return
        }
        
        self.nextNFA = nextNFA
        self.endState.outs.removeAll()
        
        if let nextLiteralNFA = nextNFA as? LiteralNFA {
            self.endState.addOut(nextLiteralNFA.endState)
        } else {
            self.endState.addOut(nextNFA.startState)
        }
    }
    
    func getEndState() -> BaseState {
        return nextNFA?.getEndState() ?? self.endState
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
        outNFAs.forEach({
            $0.getEndState().addOut(endState)
//            $0.endState.outs = [endState]
        })
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
        repeatingNFA.getEndState().addOut(endState, withWeight: .Important)
        startState.addOut(endState)
        repeatingNFA.getEndState().conditionalOut = repeatingNFA.startState
        super.init(startState: startState, endState: endState)
        repeatingNFA.getEndState().delegate = self;
    }
}

extension RepeatNFA: ConditionalOutDelegate {
    func canStateGotoConditionalOutForNothing(_ s: BaseState) -> Bool {
        return self.repeatChecker.canRepeat()
    }
}
