//
//  Error.swift
//  RegExSwift
//
//  Created by White on 2019/5/24.
//  Copyright © 2019 Ali-White. All rights reserved.
//

import Foundation

public enum RegExSwiftErrorType {
    
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

public class RegExSwiftError: CustomNSError {
    let reason: String
    init(_ r: String, code: Int) {
        self.reason = r + "ErrCode: \(code)"
    }
    
    public static var errorDomain: String { return "RegExSwift" }
    public var errorCode: Int { return -1 }
    public var errorUserInfo: [String : Any] { return [:] }
    public var localizedDescription: String { return self.reason }
    
    public static func fromType(_ type: RegExSwiftErrorType) -> RegExSwiftError {
        switch type {
        case .LastCharEscape:
            return RegExSwiftError("Dangling backslash.", code: 1001)
        case .illegalEscape(let c):
            return RegExSwiftError("\(c) cant be escaped.", code: 1002)
        case .hyphenSematic:
            return RegExSwiftError("ClassSyntaxError: Invalid symbol between the hyphen", code: 1003)
        case .unexpectedSymbol(let c):
            return RegExSwiftError("Unexpected symbol: \(c)", code: 1004)
        case .unmatchedClassSymbol:
            return RegExSwiftError("number of [ and ] not matched", code: 1005)
        case .syntaxErrorInCurly:
            return RegExSwiftError("Syntax error in curly", code: 1006)
        case .invalidOperand(let s, let isL):
            return RegExSwiftError("Symbol at \(isL ? "left" : "right") side of \(s) is invalid.", code: 1007)
        case .invaludOperandAroundAlternation:
            return RegExSwiftError("Symbols around | are invalid.", code: 1008)
        }
    }
}
