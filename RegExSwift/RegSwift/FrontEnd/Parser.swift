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
            let type = lexeme.lexemeType
            switch type {
            case .Literal:
                semanticUnitStack.append(LiteralSemantic(lexeme: lexeme as! LiteralLexeme))
            case .Alternation:
                semanticUnitStack.append(SemanticUnit(type: .Alternation))
                
                //Quantifier
            case .Plus:
                fallthrough
            case .Star:
                fallthrough
            case .QuestionMark:
                guard let lastSemanticUnit = semanticUnitStack.popLast() else { throw RegExSwiftError.fromType(RegExSwiftErrorType.invalidOperand(s: String(type.readableCharDesk), isLeft: true)) }
                let qMeni: QuantifierMenifest
                if type == .Plus {
                    qMeni = QuantifierMenifest(lowerBound: 1, higherBound: UInt.max)
                } else if type == .Star {
                    qMeni = QuantifierMenifest(lowerBound: 0, higherBound: UInt.max)
                } else { //theType == .QuestionMark
                    qMeni = QuantifierMenifest(lowerBound: 0, higherBound: 1)
                }
                let repeatingSeman = RepeatingSemantic(lastSemanticUnit, quantifier: qMeni)
                semanticUnitStack.append(repeatingSeman)
                //Quantifier
                
            case .Hyphen:
                throw RegExSwiftError.fromType(RegExSwiftErrorType.unexpectedSymbol(type.readableCharDesk))
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
                throw RegExSwiftError.fromType(RegExSwiftErrorType.unexpectedSymbol(type.readableCharDesk))
            case .Comma:
                throw RegExSwiftError.fromType(RegExSwiftErrorType.unexpectedSymbol(type.readableCharDesk))
            case .CurlyStart:
                guard let lastSemanticUnit = semanticUnitStack.popLast() else { throw RegExSwiftError.fromType(RegExSwiftErrorType.invalidOperand(s: String(type.readableCharDesk), isLeft: true)) }
                let repeatingSeman = RepeatingSemantic(lastSemanticUnit, quantifier: try self.createQuantiferInCurly())
                semanticUnitStack.append(repeatingSeman)
            case .CurlyEnd:
                throw RegExSwiftError.fromType(RegExSwiftErrorType.unexpectedSymbol(type.readableCharDesk))
            case .LiteralClass:
                semanticUnitStack.append(ClassSemantic(literalClass: (lexeme as! ClassLexeme).literalClass))
            }
        }
        return semanticUnitStack
    }
    
    private func createClassSemantic() throws -> ClassSemantic {
        
        var prevLexeme: Lexeme?
        var numOfClassStartEncountered: Int = 0
        var characterSetBuffer: Set<Character> = []
        
        while let lexeme = self.nextLexeme() {
            switch lexeme.lexemeType {
            case .Literal:
                characterSetBuffer.insert((lexeme as! LiteralLexeme).value)
                prevLexeme = lexeme
            case .Hyphen:
                let peekLexeme = self.nextLexeme()
                if let nextLiteralLexeme = peekLexeme as? LiteralLexeme, let previousLiteralLexeme = prevLexeme as? LiteralLexeme {
                    let charactersBetween = try Parser.createLiteralsBetween(startLiteralLexeme: previousLiteralLexeme, endLiteralLexeme: nextLiteralLexeme)
                    characterSetBuffer.formUnion(charactersBetween)
                } else {
                    throw RegExSwiftError.fromType(RegExSwiftErrorType.hyphenSematic)
                }
                prevLexeme = peekLexeme
            case .ClassStart:
                numOfClassStartEncountered += 1
            case .ClassEnd:
                if (numOfClassStartEncountered == 0) {
                    let liteClass = LiteralsClass(type: .Include, characters: characterSetBuffer)
                    return ClassSemantic(literalClass: liteClass)
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
        
        func numberFrom(_ lexemes: [Lexeme]) -> UInt? {
            guard let literals = lexemes as? [LiteralLexeme] else  { return nil }
            let literalString = String(literals.map { $0.value })
            return UInt(literalString)
        }
        
        var lexemeBuffer: [Lexeme] = []
        
        while let lexeme = self.nextLexeme() {
            switch lexeme.lexemeType {
            case .CurlyEnd:
                var indexOfComma: Int?
                for (index, value) in lexemeBuffer.enumerated() {
                    if value.lexemeType == .Comma {
                        indexOfComma = index
                    }
                }
                if let indexOfComma = indexOfComma {
                    guard let left = numberFrom(Array(lexemeBuffer[0..<indexOfComma])) else {
                        throw RegExSwiftError.fromType(RegExSwiftErrorType.syntaxErrorInCurly)
                    }
                    let rightLexemes = (indexOfComma < (lexemeBuffer.count - 1)) ? lexemeBuffer[(indexOfComma + 1)..<(lexemeBuffer.count - 1)] : nil
                    let right = rightLexemes == nil ? nil : numberFrom(Array(rightLexemes!))
                    return QuantifierMenifest(lowerBound: left, higherBound: right ?? UInt.max)
                } else {
                    guard let left = numberFrom(lexemeBuffer) else {
                        throw RegExSwiftError.fromType(RegExSwiftErrorType.syntaxErrorInCurly)
                    }
                    return QuantifierMenifest(lowerBound: left, higherBound: UInt.max)
                }
            default:
                lexemeBuffer.append(lexeme)
            }
        }
        
        //didn't find matched curly
        throw RegExSwiftError.fromType(RegExSwiftErrorType.syntaxErrorInCurly)
    }
    
    
    init(lexemes: [Lexeme]) throws {
        self.lexemes = lexemes
    }
    
    private func nextLexeme() -> Lexeme? {
        guard currentIndex < self.lexemes.count else { return nil }
        let targetIndex = currentIndex
        currentIndex += 1
        return self.lexemes[targetIndex]
    }
    
    static func createLiteralsBetween(startLiteralLexeme: LiteralLexeme, endLiteralLexeme: LiteralLexeme) throws -> [Character] {
        
        guard let asciiStart = startLiteralLexeme.value.asciiValue, let asciiEnd = endLiteralLexeme.value.asciiValue else { throw RegExSwiftError.fromType(RegExSwiftErrorType.hyphenSematic) }
        
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
            throw RegExSwiftError.fromType(RegExSwiftErrorType.hyphenSematic)
        }
    }
}
