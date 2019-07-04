//
//  RegSwift.swift
//  RegExSwift
//
//  Created by White on 2019/5/29.
//  Copyright © 2019 Ali-White. All rights reserved.
//

import Foundation

public class RegSwift: NSObject {
    private let entryNFA: BaseNFA
    private let parrern: String
    private let match: String
    
    @objc
    public private(set) var currentMatchIndex: Int = 0
    
    //evolve
    private var doEmptyInput = true
    private var isFirstRun = true
    private lazy var evolve: [BaseState] = [self.entryNFA.startState]
    
    @objc
    public init(pattern: String, match: String) throws {
        self.parrern = pattern
        self.match = match
        let lexer = Lexer(pattern: pattern)
        let lexemes = try lexer.createLexemes()
        let parser = try Parser(lexemes: lexemes)
        let semanticUnits = try parser.getSemanticUnits()
        self.entryNFA = try NFACreator.createNFA(from: semanticUnits)
        super.init()
    }
    
    @objc public func matchEnd() -> Bool {
        return currentMatchIndex < match.count
    }
    
    @objc public func didFindMatch() -> Bool {
        return evolve.reduce(false, { $0 || $1.isAcceptingState })
    }
    
    @objc public func forward() {
        evolve.forEach { $0.styleType = .Normal }
        if (doEmptyInput) {
            evolve = evolve.flatMap { $0.outsForNothing() }
        } else {
            let c =  Array(match)[currentMatchIndex]
            evolve = evolve.flatMap { $0.outsFor(input: c) }
            currentMatchIndex += 1
        }
        evolve.forEach { $0.styleType = .Highlighted }
    }
}

//MARK: - Nodes
extension RegSwift {
    @objc
    public func getStartNode() -> GraphNode {
        return self.entryNFA.startState
    }
}
