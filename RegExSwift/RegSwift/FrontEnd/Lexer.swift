//
//  Lexer.swift
//  RegExSwift
//
//  Created by White on 2019/5/14.
//  Copyright © 2019 Ali-White. All rights reserved.
//

import Foundation

enum LexemeType {
    
    /*
     //    case Dot
     dot is represented by
     */
    
    case Alternation                // |
    
    //quantifier
    case Star                       // *
    case Plus                       // +
    case QuestionMark               // ?
    case CurlyStart                 // {
    case CurlyEnd                   // }
    case Comma                      // ,
    
    //class
    case Hyphen                     // -
    case ClassStart                 // [
    case ClassEnd                   // ]
    
    //group
    case GroupStart                 // (
    case GroupEnd                   // )
    
    //non functional
    case Literal
    case LiteralClass
    
    static func allFunctionalCharacters() -> String {
        return ".|*+-[](){},"
    }
    
    var readableCharDesk: Character {
        switch self {
        case .Alternation:
            return "|"
        case .Star:
            return "*"
        case .Plus:
            return "+"
        case .QuestionMark:
            return "?"
        case .CurlyStart:
            return "{"
        case .CurlyEnd:
            return "}"
        case .Comma:
            return ","
        case .Hyphen:
            return "-"
        case .ClassStart:
            return "["
        case .ClassEnd:
            return "]"
        case .GroupStart:
            return "("
        case .GroupEnd:
            return ")"
        default:
            return "!"
        }
    }
}

class Lexeme {
    let lexemeType: LexemeType
    init(type: LexemeType) {
        self.lexemeType = type
    }
}

class LiteralLexeme: Lexeme {
    let value: Character
    init(value: Character) {
        self.value = value
        super.init(type: .Literal)
    }
}

class ClassLexeme: Lexeme {
    let literalClass: LiteralsClass
    init(_ lclass: LiteralsClass) {
        self.literalClass = lclass
        super.init(type: .LiteralClass)
    }
}

class Lexer {
    private var characters: [Character]
    private var currentIndex = 0
    
    init(pattern: String) {
        self.characters = pattern.map { $0 }
    }
    
    func createLexemes() throws -> [Lexeme] {
        var ls: [Lexeme] = []
        
        while let nextLexeme = try self.nextLexeme() {
            ls.append(nextLexeme)
        }
        
        //reset
        currentIndex = 0
        return ls
    }
    
    private func nextLexeme() throws -> Lexeme? {
        guard let nextCharacter = self.nextCharacter() else { return nil }
        
        //escaping highest precedence
        if (nextCharacter == "\\") {
            guard let peakCharacter = self.nextCharacter() else {
                throw RegExSwiftError.fromType(.LastCharEscape)
            }
            if let literalClass = LiteralsClass(fromPreset: peakCharacter) {
                return ClassLexeme(literalClass)
            } else if LexemeType.allFunctionalCharacters().contains(peakCharacter) {
                return LiteralLexeme(value: peakCharacter)
            } else {
                throw RegExSwiftError.fromType(RegExSwiftErrorType.illegalEscape(peakCharacter))
            }
        } else {
            let nextLexeme = lexemeFrom(nextCharacter)
            return nextLexeme
        }
    }
    
    private func lexemeFrom(_ character: Character) -> Lexeme {
        switch character {
        case "|":
            return Lexeme(type: .Alternation)
        case "*":
            return Lexeme(type: .Star)
        case ".":
            let literalClass = LiteralsClass(type: .Exclude, characters: Set(arrayLiteral: "\n"))
            return ClassLexeme(literalClass)
        case "+":
            return Lexeme(type: .Plus)
        case "?":
            return Lexeme(type: .QuestionMark)
        case "-":
            return Lexeme(type: .Hyphen)
        case "[":
            return Lexeme(type: .ClassStart)
        case "]":
            return Lexeme(type: .ClassEnd)
        case "(":
            return Lexeme(type: .GroupStart)
        case ")":
            return Lexeme(type: .GroupEnd)
        case "{":
            return Lexeme(type: .CurlyStart)
        case "}":
            return Lexeme(type: .CurlyEnd)
        case ",":
            return Lexeme(type: .Comma)
        default:
            return LiteralLexeme(value: character)
        }
    }
    
    private func nextCharacter() -> Character? {
        guard currentIndex < characters.count else { return nil }
        let nextCharacter = characters[currentIndex]
        currentIndex += 1
        return nextCharacter
    }
}
