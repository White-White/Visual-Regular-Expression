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
    case MatchEnd
}

@objc
public class MatchStatusDesp: NSObject {
    @objc public var matchStatus: MatchStatus = .MatchStart
    @objc private var logs: [String] = ["Just get Started!"]
    @objc public var indexForNextInput: Int = 0

    var doEmptyInput = true
    var isFirstRun = true
    var matchString: String! {
        didSet {
            self.logs = ["Just get Started!"]
            self.indexForNextInput = 0
            if self.evolve != nil && self.startEvolve != nil {
                self.evolve.forEach({ $0.styleType = .Normal })
                self.evolve = self.startEvolve
            }
            self.isFirstRun = true
            self.doEmptyInput = true
        }
    }
    
    private var startEvolve: [BaseState]!
    private(set) var evolve: [BaseState]!
    
    func startWithEvolve(_ e: [BaseState]) {
        self.startEvolve = e
        self.evolve = e
        self.evolve.forEach({ $0.styleType = .Highlighted })
    }
    
    func updateEvolve(_ newEvolve: [BaseState], forChar c: Character?) {
        if let c = c {
            self.indexForNextInput += 1
            self.logs.append("transition for input: \(c)")
        } else {
            self.logs.append("transition for ε")
        }
        
        let newValue = newEvolve
        self.evolve.forEach({ $0.styleType = .Normal })
        newValue.forEach({ $0.styleType = .Highlighted })
        self.evolve = newValue
        
        if newValue.isEmpty {
            self.logs.append("Failed to find a match")
            self.matchStatus = .MatchFail
            return
        }
            
        if newValue.contains(where: { $0.isAcceptingState }) {
            self.matchStatus = .MatchSuccess
            let uptoIndex = String.Index.init(utf16Offset: self.indexForNextInput, in: self.matchString!)
            let successMatch = self.matchString!.prefix(upTo: uptoIndex)
            if successMatch.isEmpty {
                self.logs.append("Did find match. This regular expression matches any empty input.")
            } else {
                self.logs.append("Did find match: \"\(successMatch)\", range: 0,\(self.indexForNextInput)")
            }
        } else {
            self.matchStatus = .MatchNormal
        }
        
        //check if match ended
        if c == nil && self.indexForNextInput == self.matchString.count {
            //match end
            self.logs.append("Match end")
            self.matchStatus = .MatchEnd
        }
    }
    
    @objc public
    func extractLogsAndClear() -> [String] {
        let _logs = self.logs
        self.logs.removeAll()
        return _logs
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
        self.startState.outs = [self.entryNFA.startState]
        self.matchStatusDesp = MatchStatusDesp()
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
        
        if self.matchStatusDesp.isFirstRun {
            self.matchStatusDesp.isFirstRun = false
            self.matchStatusDesp.doEmptyInput = true
            self.matchStatusDesp.startWithEvolve([startState])
        } else {
            var currentEvolve = self.matchStatusDesp.evolve!
            //exclude accepting states from last run
            currentEvolve = currentEvolve.filter({ !$0.isAcceptingState })
            
            if (self.matchStatusDesp.doEmptyInput) {
                currentEvolve = currentEvolve.flatMap { $0.outsForNothing() }
                self.matchStatusDesp.updateEvolve(currentEvolve, forChar: nil)
            } else {
                let c =  Array(matchString)[self.matchStatusDesp.indexForNextInput]
                currentEvolve = currentEvolve.flatMap { $0.outsFor(input: c) }
                self.matchStatusDesp.updateEvolve(currentEvolve, forChar: c)
            }
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
