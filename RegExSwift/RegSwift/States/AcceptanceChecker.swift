//
//  AcceptanceChekcer.swift
//  RegExSwift
//
//  Created by White on 2019/5/29.
//  Copyright © 2019 Ali-White. All rights reserved.
//

import Foundation

enum AcceptanceType {
    case include
    case exclude
}

struct AcceptanceChecker {
    private let characters: Set<Character>
    private let type: AcceptanceType
    
    init(type: AcceptanceType, characters: Set<Character>) {
        self.characters = characters
        self.type = type
    }
    
    func canAccept(_ character: Character) -> Bool {
        switch self.type {
        case .include:
            return self.characters.contains(character)
        case .exclude:
            return !self.characters.contains(character)
        }
    }
    
    //MARK: helper methods
    static func whiteSpaceCharacters() -> Set<Character> {
        return Set(arrayLiteral: " ", "\t")
    }
}
