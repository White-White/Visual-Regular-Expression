//
//  RegSwift.swift
//  RegExSwift
//
//  Created by White on 2019/5/29.
//  Copyright © 2019 Ali-White. All rights reserved.
//

import Foundation

class RegSwift {
    let headState: BaseState
    init(pattern: String) throws {
        let lexer = Lexer(pattern: pattern)
        let lexemes = try lexer.createLexemes()
        let parser = try Parser(lexemes: lexemes)
        let semanticUnits = try parser.getSemanticUnits()
        let headState = try StatesCreator.createHeadState(from: semanticUnits)
        self.headState = headState
    }
    
    func match(_ m: String) throws -> Bool {
        guard !m.isEmpty else { throw RegExSwiftError("Error: Target string is empty") }
        var evolve: [BaseState] = [headState]
        for character in m {
            evolve = evolve.flatMap { $0.forwardWithEmptyInput() }
            evolve = evolve.flatMap { $0.forwardWithInput(character) }
            if evolve.contains(where: { $0 === AcceptState.shared }) {
                return true
            }
        }
        return false
    }
}
