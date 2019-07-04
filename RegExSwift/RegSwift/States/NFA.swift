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
    var outNFAs: [BaseNFA] = []
    init(outNFAs: [BaseNFA]) {
        self.outNFAs = outNFAs
        let startState = DumbState()
        startState.outs = outNFAs.map({ $0.startState })
        let endState = DumbState()
        outNFAs.forEach({
            $0.getEndState().addOut(endState)
        })
        super.init(startState: startState, endState: endState)
    }
}

class RepeatNFA: BaseNFA {
    let repeatChecker: RepeatChecker
    let repeatingNFA: BaseNFA
    
    init(repeatingNFA: BaseNFA, quantifier: QuantifierMenifest) {
        self.repeatingNFA = repeatingNFA
        self.repeatChecker = RepeatChecker(with: quantifier)
        
        let endState = DumbState()
        repeatingNFA.getEndState().addOut(endState, withWeight: .Important)
        repeatingNFA.getEndState().conditionalOut = repeatingNFA.startState
        
        let startState = DumbState()
        startState.addOut(repeatingNFA.startState, withWeight: .Important)
        startState.conditionalOut = endState
        
        super.init(startState: startState, endState: endState)
        repeatingNFA.getEndState().delegate = self;
        startState.delegate = self
    }
}

extension RepeatNFA: ConditionalOutDelegate {
    func canStateGotoConditionalOutForNothing(_ s: BaseState) -> Bool {
        if self.startState === s {
            return !self.repeatChecker.needRepeat()
        } else {
            return self.repeatChecker.canRepeat()
        }
    }
}
