//
//  LiteralClass.swift
//  RegExSwift
//
//  Created by White on 2019/6/20.
//  Copyright © 2019 Ali-White. All rights reserved.
//

import Foundation

enum LiteralsClassType {
    case Include
    case Exclude
}

struct LiteralsClass {
    let type: LiteralsClassType
    let characters: [Character]
    
    /*
     https://www.vogella.com/tutorials/JavaRegularExpressions/article.html
     */
    
    private static let whiteSpaces = [
        0x09,  // \t
        0x0a,  // \n
        0x0b,  // VT
        0x0c,  // \f
        0x0d   // \r
        ].map{ Character(UnicodeScalar($0)) }
    
    static let digits = Array("1234567890")
    private static let letters = Array("abcdefghijklmnopqrstuvwxyz")
    private static let lettersUpper = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
    
    init(type: LiteralsClassType, characters: [Character]) {
        self.type = type
        self.characters = characters
    }
    
    init?(fromPreset c: Character) {
        switch c {
        case "d":  //Any digit, short for [0-9]
            self.type = .Include
            self.characters = LiteralsClass.digits
        case "D":  //A non-digit, short for [^0-9]
            self.type = .Exclude
            self.characters = LiteralsClass.digits
        case "s": //A whitespace character, short for [ \t\n\x0b\r\f]
            self.type = .Include
            self.characters = LiteralsClass.whiteSpaces
        case "S":
            self.type = .Exclude
            self.characters = LiteralsClass.whiteSpaces
        case "w":
            self.type = .Include
            self.characters = LiteralsClass.digits + LiteralsClass.letters + LiteralsClass.lettersUpper
        case "W":
            self.type = .Exclude
            self.characters = LiteralsClass.digits + LiteralsClass.letters + LiteralsClass.lettersUpper
//        case "b":
//        case "S+"
        default:
            return nil
        }
    }
    
    func accepts(_ character: Character) -> Bool {
        switch self.type {
        case .Include:
            return self.characters.contains(character)
        case .Exclude:
            return !self.characters.contains(character)
        }
    }
}
