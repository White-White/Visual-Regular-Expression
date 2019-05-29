//
//  Parser.swift
//  RegExSwift
//
//  Created by White on 2019/5/24.
//  Copyright © 2019 Ali-White. All rights reserved.
//

import Foundation

enum SemanticUnitType {
    case literalLexemeSequence //普通字符序列
    case functionalSymbol //控制符号
    case oneGroup
    case oneClass
}

protocol SemanticUnit {
    var semanticUnitType: SemanticUnitType { get }
}

struct LiteralSequenceSemantic: SemanticUnit {
    var semanticUnitType = SemanticUnitType.literalLexemeSequence
    let literals: [Character]
    
    init(lexemes: [LiteralLexeme]) {
        self.literals = lexemes.map { $0.value }
    }
}

struct GroupExpressionSemantic: SemanticUnit {
    var semanticUnitType = SemanticUnitType.oneGroup
    let semanticUnits: [SemanticUnit]
    init(semanticUnits: [SemanticUnit]) {
        self.semanticUnits = semanticUnits
    }
}

struct ClassExpressionSemantic: SemanticUnit {
    var semanticUnitType = SemanticUnitType.oneClass
    let characterSet: Set<Character>
    
    init(lexemes: [Lexeme]) throws {
        var ite = lexemes.makeIterator()
        
        var lastLexeme: Lexeme?
        var characterSetBuffer: Set<Character> = []
        
        while let lexeme = ite.next() {
            switch lexeme.lexemeType {
            case .Functional:
                guard let functionLexeme = lexeme as? FunctionalLexeme else { fatalError() }
                switch functionLexeme.subType {
                case .Hyphen:
                    let peekLexeme = ite.next()
                    if let nextLiteralLexeme = peekLexeme as? LiteralLexeme, let previousLiteralLexeme = lastLexeme as? LiteralLexeme {
                        let charactersBetween = try Parser.createLiteralsBetween(startLiteralLexeme: previousLiteralLexeme, endLiteralLexeme: nextLiteralLexeme)
                        characterSetBuffer.formUnion(charactersBetween)
                    } else {
                        throw RegExSwiftError("ClassSyntaxError: Invalid symbol between the hyphen")
                    }
                    lastLexeme = peekLexeme as Lexeme?
                default:
                    lastLexeme = lexeme //ignore
                }
            case .Literal:
                characterSetBuffer.insert((lexeme as! LiteralLexeme).value)
                lastLexeme = lexeme
            }
        }
        
        self.characterSet = characterSetBuffer
    }
}

struct FunctionalSemantic: SemanticUnit {
    var semanticUnitType = SemanticUnitType.functionalSymbol
    
    enum FunctionalSemanticSubType {
        case Dot // .
        case Alternation // | (pipe)
        case Star // *
        case Plus // +
    }
    
    let functionalSemanticType: FunctionalSemanticSubType
    
    init(_ functionalSemanticType: FunctionalSemanticSubType) {
        self.functionalSemanticType = functionalSemanticType
    }
}

class Parser {
    private let lexemes: [Lexeme]
    private var currentIndex: Int = 0
    private var semanticUnits: [SemanticUnit]? //cache
    
    func getSemanticUnits() throws -> [SemanticUnit] {
        if let semanticUnits = semanticUnits {
            return semanticUnits
        } else {
            let created = try self.createSemanticUnits()
            self.semanticUnits = created
            return created
        }
    }
    
    private func createSemanticUnits() throws -> [SemanticUnit] {
        var semanticUnitStack: [SemanticUnit] = []
        var literalLexemeStack: [LiteralLexeme] = []
        
        func _dumpLexemesToSemanticStack() {
            if !literalLexemeStack.isEmpty {
                let literalSequence = LiteralSequenceSemantic(lexemes: literalLexemeStack)
                semanticUnitStack.append(literalSequence)
                literalLexemeStack.removeAll()
            }
        }
        
        while let nextLexeme = self.nextLexeme() {
            switch nextLexeme.lexemeType {
            case .Functional:
                let nextFunctionLexeme = nextLexeme as! FunctionalLexeme
                switch nextFunctionLexeme.subType {
                case .Dot:
                    _dumpLexemesToSemanticStack()
                    semanticUnitStack.append(FunctionalSemantic(.Dot))
                case .Plus:
                    _dumpLexemesToSemanticStack()
                    semanticUnitStack.append(FunctionalSemantic(.Plus))
                case .Alternation:
                    _dumpLexemesToSemanticStack()
                    semanticUnitStack.append(FunctionalSemantic(.Alternation))
                case .Star:
                    _dumpLexemesToSemanticStack()
                    semanticUnitStack.append(FunctionalSemantic(.Star))
                case .Hyphen:
                    throw RegExSwiftError("SyntaxError: unexpected -")
                case .GroupStart:
                    _dumpLexemesToSemanticStack()
                    let semanticUnitsOfThisGroup = try self.createSemanticUnits()
                    guard !semanticUnitsOfThisGroup.isEmpty else { continue }
                    let groupExpression = GroupExpressionSemantic(semanticUnits: semanticUnitsOfThisGroup)
                    semanticUnitStack.append(groupExpression)
                case .GroupEnd:
                    _dumpLexemesToSemanticStack()
                    return semanticUnitStack
                case .ClassStart:
                    _dumpLexemesToSemanticStack()
                    semanticUnitStack.append(try self.createClassExpression())
                case .ClassEnd:
                    throw RegExSwiftError("SyntaxError: unexpected ]")
                }
            case .Literal:
                literalLexemeStack.append(nextLexeme as! LiteralLexeme)
            }
        }
        
        _dumpLexemesToSemanticStack()
        
        return semanticUnitStack
    }
    
    private func createClassExpression() throws -> ClassExpressionSemantic {
        var lexemeBuffer: [Lexeme] = []
        var numOfClassStartEncountered: Int = 0
        
        while let nextLexeme = self.nextLexeme() {
            switch nextLexeme.lexemeType {
            case .Literal:
                lexemeBuffer.append(nextLexeme)
            case .Functional:
                let nextFunctionLexeme = nextLexeme as! FunctionalLexeme
                switch nextFunctionLexeme.subType {
                case .Hyphen:
                    lexemeBuffer.append(nextLexeme)
                case .ClassStart:
                    numOfClassStartEncountered += 1
                case .ClassEnd:
                    if (numOfClassStartEncountered == 0) {
                        return try ClassExpressionSemantic(lexemes: lexemeBuffer)
                    } else {
                        numOfClassStartEncountered -= 1
                    }
                default:
                    continue //ignore
                }
            }
        }
        
        throw RegExSwiftError("ClassSyntaxError: number of [ and ] not matched")
    }
    
    
    init(lexemes: [Lexeme]) throws {
        self.lexemes = lexemes
    }
    
    //
    private func nextLexeme() -> Lexeme? {
        guard currentIndex < self.lexemes.count else { return nil }
        let targetIndex = currentIndex
        currentIndex += 1
        return self.lexemes[targetIndex]
    }
    
    //回滚
    private func rollBack() throws {
        guard currentIndex > 0 else { throw RegExSwiftError("Parser回退超过数组边界") }
        currentIndex -= 1
    }
    
    //helper
    static func isLexemesEqual(_ l: Lexeme, r: Lexeme) -> Bool {
        switch (l.lexemeType, r.lexemeType) {
        case (LexemeType.Literal, LexemeType.Literal):
            guard let l = l as? LiteralLexeme, let r = r as? LiteralLexeme else { return false }
            return l.value == r.value
        case (LexemeType.Functional, LexemeType.Functional):
            guard let l = l as? FunctionalLexeme, let r = r as? FunctionalLexeme else { return false }
            return l.subType == r.subType
        default:
            return false
        }
    }
    
    static func createLiteralsBetween(startLiteralLexeme: LiteralLexeme, endLiteralLexeme: LiteralLexeme) throws -> [Character] {
        
        guard let asciiStart = startLiteralLexeme.value.asciiValue, let asciiEnd = endLiteralLexeme.value.asciiValue else { throw RegExSwiftError("SyntaxErrorInClass: Both side of the hyphen must be a valid ascii value") }
        
        let numZero: uint8 = 48
        let numNine: uint8 = 57
        let lettera: uint8 = 97
        let letterz: uint8 = 122
        let letterA: uint8 = 65
        let letterZ: uint8 = 90
        
        //ascii table reference:
        //https://www.cs.cmu.edu/~pattis/15-1XX/common/handouts/ascii.html
        
        let smaller = min(asciiStart, asciiEnd)
        let bigger = max(asciiStart, asciiEnd)
        
        let isNum = (smaller >= numZero && smaller <= numNine)
            && (bigger >= numZero && bigger <= numNine)
        let isLetterLower = (smaller >= lettera && smaller <= letterz)
            && (bigger >= lettera && bigger <= letterz)
        let isLetterUpper = (smaller >= letterA && smaller <= letterZ)
            && (bigger >= letterA && bigger <= letterZ)
        
        if isNum || isLetterLower || isLetterUpper {
            return (smaller...bigger).map { Character(Unicode.Scalar($0)) }
        } else {
            throw RegExSwiftError("SyntaxErrorInClass: Values between the hyphen are not semantically  sequenced values")
        }
    }
}
