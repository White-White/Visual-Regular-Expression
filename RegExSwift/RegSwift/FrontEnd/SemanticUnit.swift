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
    case Repeating       // * + {m,n} ?
    case Group           // ()
    case Class           // []
    case Alternation
    
    var readableDesp: String {
        switch self {
        case .Alternation:
            return "|"
        default:
            break
        }
        return "NULL"
    }
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

class RepeatingSemantic: SemanticUnit {
    let quantifier: QuantifierMenifest
    let semanticToRepeat: SemanticUnit
    init(_ repeatingSemanticUnit: SemanticUnit, quantifier: QuantifierMenifest) {
        self.semanticToRepeat = repeatingSemanticUnit
        self.quantifier = quantifier
        super.init(type: .Repeating)
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
    let literalClass: LiteralsClass
    init(literalClass: LiteralsClass) {
        self.literalClass = literalClass
        super.init(type: .Class)
    }
}
