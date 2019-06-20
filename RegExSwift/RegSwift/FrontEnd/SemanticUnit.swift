//
//  SemanticUnit.swift
//  RegExSwift
//
//  Created by White on 2019/6/20.
//  Copyright © 2019 Ali-White. All rights reserved.
//

import Foundation

struct QuantifierMenifest {
    let lowerBound: UInt
    let higherBound: UInt
}

enum SemanticUnitType {
    case Literal
    case Quantifier(qMeni: QuantifierMenifest)
    case Group           // ()
    case Class           // []
    case Alternation
}

class SemanticUnit {
    let type: SemanticUnitType
    init(type: SemanticUnitType) {
        self.type = type
    }
}

class LiteralSemantic: SemanticUnit {
    let literal: Character
    init(lexeme: LiteralLexeme) {
        self.literal = lexeme.value
        super.init(type: .Literal)
    }
}

class GroupSemantic: SemanticUnit {
    let semanticUnits: [SemanticUnit]
    init(semanticUnits: [SemanticUnit]) {
        self.semanticUnits = semanticUnits
        super.init(type: .Group)
    }
}

class ClassSemantic: SemanticUnit {
    enum ClassSemanticType {
        case Include
        case Exclude
    }
    
    let classCheckType: ClassSemanticType
    let characterSet: Set<Character>
    
    init(classLexeme: ClassLexeme) {
        switch classLexeme.literalClass.type {
        case .Include:
            self.classCheckType = .Include
        case .Exclude:
            self.classCheckType = .Exclude
        }
        self.characterSet = Set(classLexeme.literalClass.characters)
        super.init(type: .Class)
    }
    
    init(lexemesInsideClassSymbol: [Lexeme]) throws {
        self.classCheckType = .Include
        var ite = lexemesInsideClassSymbol.makeIterator()
        
        var lastLexeme: Lexeme?
        var characterSetBuffer: Set<Character> = []
        
        while let lexeme = ite.next() {
            switch lexeme.lexemeType {
            case .Hyphen:
                let peekLexeme = ite.next()
                if let nextLiteralLexeme = peekLexeme as? LiteralLexeme, let previousLiteralLexeme = lastLexeme as? LiteralLexeme {
                    let charactersBetween = try Parser.createLiteralsBetween(startLiteralLexeme: previousLiteralLexeme, endLiteralLexeme: nextLiteralLexeme)
                    characterSetBuffer.formUnion(charactersBetween)
                } else {
                    throw RegExSwiftError.fromType(RegExSwiftErrorType.hyphenSematic)
                }
                lastLexeme = peekLexeme as Lexeme?
            case .Literal:
                characterSetBuffer.insert((lexeme as! LiteralLexeme).value)
                lastLexeme = lexeme
            default:
                lastLexeme = nil //ignore unknown lexeme
            }
        }
        self.characterSet = characterSetBuffer
        super.init(type: .Class)
    }
}
