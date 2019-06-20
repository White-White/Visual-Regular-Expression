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
}

public class RegExSwiftError: CustomNSError {
    let reason: String
    init(_ r: String) { self.reason = r }
    
    public static var errorDomain: String { return "RegExSwift" }
    public var errorCode: Int { return 0 }
    public var errorUserInfo: [String : Any] { return [:] }
    public var localizedDescription: String { return self.reason }
    
    public static func fromType(_ type: RegExSwiftErrorType) -> RegExSwiftError {
        switch type {
        case .LastCharEscape:
            return RegExSwiftError("Dangling backslash")
        case .illegalEscape(let c):
            return RegExSwiftError("\(c) cant be escaped.")
        case .hyphenSematic:
            return RegExSwiftError("ClassSyntaxError: Invalid symbol between the hyphen")
        case .unexpectedSymbol(let c):
            return RegExSwiftError("Unexpected symbol: \(c)")
        case .unmatchedClassSymbol:
            return RegExSwiftError("number of [ and ] not matched")
        case .syntaxErrorInCurly:
            return RegExSwiftError("Syntax error in curly")
        }
    }
}
