//
//  RegSwift.swift
//  RegExSwift
//
//  Created by White on 2019/5/29.
//  Copyright © 2019 Ali-White. All rights reserved.
//

import Foundation

struct StateNameCreator {
    var start = 0
    mutating func nextName() -> String {
        start += 1
        return "s\(start)"
    }
    
    var finStart = 0
    mutating func nextFin() -> String {
        finStart += 1
        return "FIN\(finStart)"
    }
}

public class RegSwift: NSObject {
    private let startState: InterState = InterState()
    private let parrern: String
    private let match: String
    private var nameCreator: StateNameCreator = StateNameCreator()
    
    @objc
    public private(set) var currentMatchIndex: Int = 0
    
    //evolve
    private var doEmptyInput = true
    private var isFirstRun = true
    private lazy var evolve: [BaseState] = [self.startState]
    
    @objc
    public init(pattern: String, match: String) throws {
        self.parrern = pattern
        self.match = match
        let lexer = Lexer(pattern: pattern)
        let lexemes = try lexer.createLexemes()
        let parser = try Parser(lexemes: lexemes)
        let semanticUnits = try parser.getSemanticUnits()
        let headState = try StatesCreator.createHeadState(from: semanticUnits)
        startState.stateName = "Start"
        startState.styleType = .Start
        startState.connect(headState)
        super.init()
    }
    
    @objc public func matchEnd() -> Bool {
        return currentMatchIndex < match.count
    }
    
    @objc public func didFindMatch() -> Bool {
        return evolve.reduce(false, { $0 || $1.isAccepted })
    }
    
    @objc public func forward() {
        evolve.forEach { $0.styleType = .Normal }
        if (doEmptyInput) {
            evolve = evolve.flatMap { $0.outs(with: nil) }
        } else {
            let c =  Array(match)[currentMatchIndex]
            evolve = evolve.flatMap { $0.outs(with: c) }
            currentMatchIndex += 1
        }
        evolve.forEach { $0.styleType = .Highlighted }
        
//        if (isFirstRun) {
//            isFirstRun = false;
//            doEmptyInput = true;
//        } else {
            doEmptyInput = !doEmptyInput
//        }
    }
}

//MARK: - Nodes
extension RegSwift {
    @objc
    public func getStartNode() -> GraphNode {
        return self.startState
    }
    
    @objc
    public func name(for o: AnyObject) -> String {
        let state = o as! BaseState
        if let stateName = state.stateName {
            return stateName
        } else {
            if (state.isAccepted) {
                state.stateName = nameCreator.nextFin()
                return state.stateName!
            }
            state.stateName = nameCreator.nextName()
            return state.stateName!
        }
    }
}
