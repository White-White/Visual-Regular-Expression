//
//  RegSwift.swift
//  RegExSwift
//
//  Created by White on 2019/5/29.
//  Copyright © 2019 Ali-White. All rights reserved.
//

import Foundation

@objc
public enum MatchStatus: Int {
    case MatchStart
    case MatchNormal
    case MatchFail
    case MatchSuccess
}

@objc
public class MatchStatusDesp: NSObject {
    @objc public var matchStatus: MatchStatus = .MatchStart
    @objc public var log: String = "Just get Started!"
    @objc public var indexForNextInput: Int = 0
    @objc public private(set) var successedMatch: [String] = []

    var doEmptyInput = true
    var isFirstRun = true
    var matchString: String!
    
    var evolve: [BaseState] {
        set {
            self.p_evolve.forEach({ $0.styleType = .Normal })
            newValue.forEach({ $0.styleType = .Highlighted })
            self.p_evolve = newValue
            
            if newValue.isEmpty {
                self.matchStatus = .MatchFail
            } else if newValue.contains(where: { $0.isAcceptingState }) {
                self.matchStatus = .MatchSuccess
                let uptoIndex = String.Index.init(utf16Offset: self.indexForNextInput, in: self.matchString!)
                let successMatch = self.matchString!.prefix(upTo: uptoIndex)
                self.successedMatch.append(String(successMatch))
            } else {
                self.matchStatus = .MatchNormal
            }
        }
        get {
            return self.p_evolve
        }
    }
    private var p_evolve: [BaseState]
    
    init(_ e: [BaseState]) {
        self.p_evolve = e
    }
}

public class RegSwift: NSObject {
    
    private let startState: BaseState
    private let entryNFA: BaseNFA
    private let patternString: String
    private var matchString: String!
    
    @objc public
    let matchStatusDesp: MatchStatusDesp
    
    @objc public
    init(pattern: String) throws {
        self.patternString = pattern
        let lexer = Lexer(pattern: pattern)
        let lexemes = try lexer.createLexemes()
        let parser = try Parser(lexemes: lexemes)
        let semanticUnits = try parser.getSemanticUnits()
        self.entryNFA = try NFACreator.createNFA(from: semanticUnits)
        self.startState = DumbState()
        self.startState.styleType = .Highlighted
        self.startState.outs = [self.entryNFA.startState]
        self.matchStatusDesp = MatchStatusDesp([self.startState])
        super.init()
        
        //reset state name counter
        BaseState.counter = 0;
    }
    
    @objc public
    func resetWithMatch(_ m: String) {
        //has to be done before run
        self.matchStatusDesp.matchString = m;
        self.matchString = m;
    }
    
    @objc public func forward() {
        var currentEvolve = self.matchStatusDesp.evolve
        if self.matchStatusDesp.isFirstRun {
            self.matchStatusDesp.isFirstRun = false
            self.matchStatusDesp.doEmptyInput = true
        } else {
            //exclude accepting states from last run
            currentEvolve = currentEvolve.filter({ !$0.isAcceptingState })
            
            if (self.matchStatusDesp.doEmptyInput) {
                currentEvolve = currentEvolve.flatMap { $0.outsForNothing() }
                self.matchStatusDesp.log = "transition for ε"
            } else {
                let c =  Array(matchString)[self.matchStatusDesp.indexForNextInput]
                currentEvolve = currentEvolve.flatMap { $0.outsFor(input: c) }
                self.matchStatusDesp.indexForNextInput += 1
                self.matchStatusDesp.log = "transition for input: \(c)"
            }
            
            self.matchStatusDesp.evolve = currentEvolve
            self.matchStatusDesp.doEmptyInput = !self.matchStatusDesp.doEmptyInput
        }
    }
}

//MARK: - Nodes
extension RegSwift {
    @objc
    public func getStartNode() -> GraphNode {
        return self.startState
    }
}
