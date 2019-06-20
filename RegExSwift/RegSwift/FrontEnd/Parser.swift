//
//  Parser.swift
//  RegExSwift
//
//  Created by White on 2019/5/24.
//  Copyright © 2019 Ali-White. All rights reserved.
//

import Foundation

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

        while let lexeme = self.nextLexeme() {
            switch lexeme.lexemeType {
            case .Literal:
                semanticUnitStack.append(LiteralSemantic(lexeme: lexeme as! LiteralLexeme))
            case .Alternation:
                semanticUnitStack.append(SemanticUnit(type: .Alternation))
            case .Plus:
                let qMeni = QuantifierMenifest(lowerBound: 1, higherBound: UInt.max)
                semanticUnitStack.append(SemanticUnit(type: .Quantifier(qMeni: qMeni)))
            case .Hyphen:
                throw RegExSwiftError.fromType(RegExSwiftErrorType.unexpectedSymbol("-"))
            case .Star:
                let qMeni = QuantifierMenifest(lowerBound: 0, higherBound: UInt.max)
                semanticUnitStack.append(SemanticUnit(type: .Quantifier(qMeni: qMeni)))
            case .GroupStart:
                let semanticUnitsOfThisGroup = try self.createSemanticUnits()
                guard !semanticUnitsOfThisGroup.isEmpty else { continue }
                let groupExpression = GroupSemantic(semanticUnits: semanticUnitsOfThisGroup)
                semanticUnitStack.append(groupExpression)
            case .GroupEnd:
                return semanticUnitStack
            case .ClassStart:
                semanticUnitStack.append(try self.createClassSemantic())
            case .ClassEnd:
                throw RegExSwiftError.fromType(RegExSwiftErrorType.unexpectedSymbol("]"))
            case .Comma:
                throw RegExSwiftError.fromType(RegExSwiftErrorType.unexpectedSymbol(","))
            case .CurlyStart:
                let quanti = try self.createQuantiferInCurly()
                semanticUnitStack.append(SemanticUnit(type: .Quantifier(qMeni: quanti)))
            case .CurlyEnd:
                throw RegExSwiftError.fromType(RegExSwiftErrorType.unexpectedSymbol("}"))
            case .LiteralClass:
                semanticUnitStack.append(ClassSemantic(classLexeme: lexeme as! ClassLexeme))
            }
        }
        return semanticUnitStack
    }
    
    private func createClassSemantic() throws -> ClassSemantic {
        var lexemeBuffer: [Lexeme] = []
        var numOfClassStartEncountered: Int = 0
        
        while let nextLexeme = self.nextLexeme() {
            switch nextLexeme.lexemeType {
            case .Literal:
                lexemeBuffer.append(nextLexeme)
            case .Hyphen:
                lexemeBuffer.append(nextLexeme)
            case .ClassStart:
                numOfClassStartEncountered += 1
            case .ClassEnd:
                if (numOfClassStartEncountered == 0) {
                    return try ClassSemantic(lexemesInsideClassSymbol: lexemeBuffer)
                } else {
                    numOfClassStartEncountered -= 1
                }
            default:
                break // ignore
            }
        }
        
        throw RegExSwiftError.fromType(RegExSwiftErrorType.unmatchedClassSymbol)
    }
    
    private func createQuantiferInCurly() throws -> QuantifierMenifest {
        var lexemeBuffer: [LiteralLexeme] = []
        var lowerBound: UInt?
        var hasMetComma: Bool = false
        
        while let lexeme = self.nextLexeme() {
            switch lexeme.lexemeType {
            case .Literal:
                let literalLexeme = lexeme as! LiteralLexeme
                guard LiteralsClass.digits.contains(literalLexeme.value) else {
                    throw RegExSwiftError.fromType(RegExSwiftErrorType.syntaxErrorInCurly)
                }
                lexemeBuffer.append(literalLexeme)
            case .Comma:
                guard !hasMetComma else {
                    throw RegExSwiftError.fromType(RegExSwiftErrorType.syntaxErrorInCurly)
                }
                hasMetComma = true
                let stringLeftComma = String(lexemeBuffer.map { $0.value })
                if let lower = UInt(stringLeftComma) {
                    lowerBound = lower
                    lexemeBuffer.removeAll()
                } else {
                    throw RegExSwiftError.fromType(RegExSwiftErrorType.syntaxErrorInCurly)
                }
            case .CurlyEnd:
                guard let lowerBound = lowerBound else {
                    throw RegExSwiftError.fromType(RegExSwiftErrorType.syntaxErrorInCurly)
                }
                if let higher = UInt(String(lexemeBuffer.map { $0.value })) {
                    return QuantifierMenifest(lowerBound: lowerBound, higherBound: higher)
                } else {
                    return QuantifierMenifest(lowerBound: lowerBound, higherBound: UInt.max)
                }
            default:
                throw RegExSwiftError.fromType(RegExSwiftErrorType.syntaxErrorInCurly)
            }
        }
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
    
    //helper
//    static func isLexemesEqual(_ l: Lexeme, r: Lexeme) -> Bool {
//        switch (l.lexemeType, r.lexemeType) {
//        case (LexemeType.Literal, LexemeType.Literal):
//            guard let l = l as? LiteralLexeme, let r = r as? LiteralLexeme else { return false }
//            return l.value == r.value
//        case (LexemeType.Functional, LexemeType.Functional):
//            guard let l = l as? FunctionalLexeme, let r = r as? FunctionalLexeme else { return false }
//            return l.subType == r.subType
//        default:
//            return false
//        }
//    }
    
    static func createLiteralsBetween(startLiteralLexeme: LiteralLexeme, endLiteralLexeme: LiteralLexeme) throws -> [Character] {
        
        guard let asciiStart = startLiteralLexeme.value.asciiValue, let asciiEnd = endLiteralLexeme.value.asciiValue else { throw RegExSwiftError("SyntaxErrorInClass: Both side of the hyphen must be a valid ascii value") }
        
        let numZero: UInt8 = 48
        let numNine: UInt8 = 57
        let lettera: UInt8 = 97
        let letterz: UInt8 = 122
        let letterA: UInt8 = 65
        let letterZ: UInt8 = 90
        
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
