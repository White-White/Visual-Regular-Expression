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
    let characters: Set<Character>
    
    /*
     https://www.vogella.com/tutorials/JavaRegularExpressions/article.html
     */
    
    private static let whiteSpaces = Set(arrayLiteral:
        Character(UnicodeScalar(0x09)),  // \t
        Character(UnicodeScalar(0x0a)),  // \n
        Character(UnicodeScalar(0x0b)),  // VT
        Character(UnicodeScalar(0x0c)),  // \f
        Character(UnicodeScalar(0x0d))   // \r
        )
    
    static let digits = Set(Array("1234567890")) as Set<Character>
    private static let letters = Set(Array("abcdefghijklmnopqrstuvwxyz")) as Set<Character>
    private static let lettersUpper = Set(Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")) as Set<Character>
    
    init(type: LiteralsClassType, characters: Set<Character>) {
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
            self.characters = LiteralsClass.digits.union(LiteralsClass.letters).union(LiteralsClass.lettersUpper)
        case "W":
            self.type = .Exclude
            self.characters = LiteralsClass.digits.union(LiteralsClass.letters).union(LiteralsClass.lettersUpper)
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
    
    func criteriaDesp() -> String {
        let criteria = (Array(self.characters).map { String($0) }).joined(separator: ",")
        return String.init(format: "\(self.type == .Exclude ? "!" : "")%@", criteria)
    }
}
