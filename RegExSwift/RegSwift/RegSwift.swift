//
//  RegSwift.swift
//  RegExSwift
//
//  Created by White on 2019/5/29.
//  Copyright © 2019 Ali-White. All rights reserved.
//

import Foundation

public class RegSwift: NSObject {
    
    private let startState: BaseState
    private let entryNFA: BaseNFA
    private let patternString: String
    private let matchString: String
    
    @objc
    public private(set) var indexForNextInput: Int = 0
    
    //evolve
    private var doEmptyInput = true
    private var isFirstRun = true
    private lazy var evolve: [BaseState] = [self.startState]
    
    @objc
    public init(pattern: String, match: String) throws {
        self.patternString = pattern
        self.matchString = match
        let lexer = Lexer(pattern: pattern)
        let lexemes = try lexer.createLexemes()
        let parser = try Parser(lexemes: lexemes)
        let semanticUnits = try parser.getSemanticUnits()
        self.entryNFA = try NFACreator.createNFA(from: semanticUnits)
        self.startState = DumbState()
        self.startState.outs = [self.entryNFA.startState]
        super.init()
    }
    
    @objc public func matchEnd() -> Bool {
        return indexForNextInput < matchString.count
    }
    
    @objc public func didFindMatch() -> Bool {
        return evolve.reduce(false, { $0 || $1.isAcceptingState })
    }
    
    @objc public func forward() {
        evolve.forEach { $0.styleType = .Normal }
        if isFirstRun {
            isFirstRun = false
            doEmptyInput = true
        } else {
            //exclude accepting states from last run
            evolve = evolve.filter({ !$0.isAcceptingState })
            
            //
            if (doEmptyInput) {
                evolve = evolve.flatMap { $0.outsForNothing() }
            } else {
                let c =  Array(matchString)[indexForNextInput]
                evolve = evolve.flatMap { $0.outsFor(input: c) }
                indexForNextInput += 1
            }
            doEmptyInput = !doEmptyInput
        }
        evolve.forEach { $0.styleType = .Highlighted }
    }
}

//MARK: - Nodes
extension RegSwift {
    @objc
    public func getStartNode() -> GraphNode {
        return self.startState
    }
}
