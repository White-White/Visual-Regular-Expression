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

struct AcceptanceChekcer {
    private let acceptedCharacters: Set<Character>
    private let unacceptedCharacters: Set<Character>
    private let type: AcceptanceType
    private let _canAcceptNil: Bool
    
    init(type: AcceptanceType,
         acceptedCharacters: Set<Character> = [],
         unacceptedCharacters: Set<Character> = [],
         canAcceptNil: Bool) {
        self.acceptedCharacters = acceptedCharacters
        self.unacceptedCharacters = unacceptedCharacters
        self.type = type
        self._canAcceptNil = canAcceptNil
    }
    
    func canAcceptNil() -> Bool {
        return self._canAcceptNil
    }
    
    func canAccept(_ character: Character?) -> Bool {
        if self.canAcceptNil() { return true }
        if let c = character {
            switch self.type {
            case .include:
                return self.acceptedCharacters.contains(c)
            case .exclude:
                return !self.unacceptedCharacters.contains(c)
            }
        } else {
            return false
        }
    }
    
    static func whiteSpaceCharacters() -> Set<Character> {
        return Set(arrayLiteral: " ", "\t")
    }
}
