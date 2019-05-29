//
//  Lexer.swift
//  RegExSwift
//
//  Created by White on 2019/5/14.
//  Copyright © 2019 Ali-White. All rights reserved.
//

import Foundation

enum LexemeType {
    case Functional
    case Literal
}

protocol Lexeme {
    var lexemeType: LexemeType { get }
}

//特殊控制字符
struct FunctionalLexeme: Lexeme {
    
    let lexemeType = LexemeType.Functional
    
    enum FunctionalLexemeSubType {
        case Dot // .
        case Alternation // | (pipe)
        case Star // *
        case Plus // +
        case Hyphen
        case ClassStart // [
        case ClassEnd // ]
        case GroupStart // (
        case GroupEnd // )
    }
    
    let subType: FunctionalLexemeSubType
}

//Literal
struct LiteralLexeme: Lexeme {
    let lexemeType = LexemeType.Literal
    let value: Character
}

//词法分析
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
        
        //重置
        currentIndex = 0
        return ls
    }
    
    private func lexemeFrom(_ character: Character) -> Lexeme {
        switch character {
        case "|":
            return FunctionalLexeme(subType: .Alternation)
        case "*":
            return FunctionalLexeme(subType: .Star)
        case ".":
            return FunctionalLexeme(subType: .Dot)
        case "+":
            return FunctionalLexeme(subType: .Plus)
        case "-":
            return FunctionalLexeme(subType: .Hyphen)
        case "[":
            return FunctionalLexeme(subType: .ClassStart)
        case "]":
            return FunctionalLexeme(subType: .ClassEnd)
        case "(":
            return FunctionalLexeme(subType: .GroupStart)
        case ")":
            return FunctionalLexeme(subType: .GroupEnd)
        default:
            return LiteralLexeme(value: character)
        }
    }
    
    private func lexemeFromEscaped(_ character: Character) throws -> Lexeme {
        if "|*.+[]()\\".contains(character) {
            return LiteralLexeme(value: character)
        } else {
            throw RegExSwiftError("非法的被逃逸字符")
        }
    }
    
    private func nextLexeme() throws -> Lexeme? {
        guard let nextCharacter = self.nextCharacter() else { return nil }
        //逃逸字符
        if (nextCharacter == "\\") {
            guard let peakCharacter = self.nextCharacter() else { throw RegExSwiftError("反斜杠不能是最后一个字符") }
            return try lexemeFromEscaped(peakCharacter)
        } else {
            let nextLexeme = lexemeFrom(nextCharacter)
            return nextLexeme
        }
    }
    
    //回滚
    private func rollBack() throws {
        guard currentIndex > 0 else { throw RegExSwiftError("Lexer回退超过数组边界") }
        currentIndex -= 1
    }
    
    //下一个字符
    private func nextCharacter() -> Character? {
        guard currentIndex < characters.count else { return nil }
        let nextCharacter = characters[currentIndex]
        currentIndex += 1
        return nextCharacter
    }
}
