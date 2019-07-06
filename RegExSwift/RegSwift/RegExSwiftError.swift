//
//  Error.swift
//  RegExSwift
//
//  Created by White on 2019/5/24.
//  Copyright © 2019 Ali-White. All rights reserved.
//

import Foundation

enum RegExSwiftErrorType {
    
    //lexer
    case LastCharEscape
    case illegalEscape(Character)

    //parse
    case hyphenSematic
    case unexpectedSymbol(Character)
    case unmatchedClassSymbol
    case syntaxErrorInCurly
    
    //syntax error
    case invalidOperand(s: String, isLeft: Bool)
    case invaludOperandAroundAlternation
}

class RegExSwiftError: LocalizedError {
    let reason: String
    init(_ r: String) { self.reason = r }
    
    public var errorDescription: String? {
        return self.reason
    }
    
    public static func fromType(_ type: RegExSwiftErrorType) -> RegExSwiftError {
        switch type {
        case .LastCharEscape:
            return RegExSwiftError("Dangling backslash")
        case .illegalEscape(let c):
            return RegExSwiftError("\(c) cant be escaped")
        case .hyphenSematic:
            return RegExSwiftError("ClassSyntaxError: Invalid symbol between the hyphen")
        case .unexpectedSymbol(let c):
            return RegExSwiftError("Unexpected symbol: \(c)")
        case .unmatchedClassSymbol:
            return RegExSwiftError("number of [ and ] not matched")
        case .syntaxErrorInCurly:
            return RegExSwiftError("Syntax error in curly")
        case .invalidOperand(let s, let isL):
            return RegExSwiftError("Invalid symbol at \(isL ? "left" : "right") side of \(s)")
        case .invaludOperandAroundAlternation:
            return RegExSwiftError("Symbols around | are invalid")
        }
    }
}
