//
//  NFACreator.swift
//  RegExSwift
//
//  Created by White on 2019/7/3.
//  Copyright © 2019 Ali-White. All rights reserved.
//

import Foundation

class NFACreator {
    
    static func createNFA(from semanticUnits: [SemanticUnit]) throws -> BaseNFA {
        //extract "|"
        let smticsSepByAlter = try (semanticUnits.split { $0.type == .Alternation }).map { (sUnits) -> Array<SemanticUnit> in
            guard !sUnits.isEmpty else {
                throw RegExSwiftError.fromType(RegExSwiftErrorType.invaludOperandAroundAlternation)
            }
            return Array(sUnits)
        }
        let nfas = try smticsSepByAlter.map { try self.createNFAWithoutAlter(from: $0) }
        return nfas.count == 1 ? nfas[0] : SplitNFA(outNFAs: nfas)
    }
    
    private static func createNFAWithoutAlter(from semanticUnits: [SemanticUnit]) throws -> BaseNFA {
        guard !semanticUnits.isEmpty else { fatalError() }
        
        //
        var semanticUnitIte = semanticUnits.makeIterator()
        var nfaStack: [BaseNFA] = []
        
        while let semanticUnit = semanticUnitIte.next() {
            switch semanticUnit.type {
            case .Literal:
                let literalSemantic = semanticUnit as! LiteralSemantic
                let literalClass = LiteralsClass(type: .Include, characters: Set(arrayLiteral: literalSemantic.literal))
                let classState = LiteralState(literalClass: literalClass)
                let literalNFA = LiteralNFA(classState)
                nfaStack.last?.connect(with: literalNFA)
                nfaStack.append(literalNFA)
            case .Class:
                let classSemantic = (semanticUnit as! ClassSemantic)
                let classState = LiteralState(literalClass: classSemantic.literalClass)
                let literalNFA = LiteralNFA(classState)
                nfaStack.last?.connect(with: literalNFA)
                nfaStack.append(literalNFA)
            case .Group:
                let groupSemanticUnit = semanticUnit as! GroupSemantic
                //there can be alter semantic units in a group
                let nfaFromGroup = try self.createNFA(from: groupSemanticUnit.semanticUnits)
                nfaStack.last?.connect(with: nfaFromGroup)
                nfaStack.append(nfaFromGroup)
            case .Repeating:
                let repeatingSemantic = semanticUnit as! RepeatingSemantic
                let quanti = repeatingSemantic.quantifier
                let nfaToRepeat = try self.createNFA(from: [repeatingSemantic.semanticToRepeat])
                let repeatNFA = RepeatNFA(repeatingNFA: nfaToRepeat, quantifier: quanti)
                nfaStack.last?.connect(with: repeatNFA)
                nfaStack.append(repeatNFA)
            case .Alternation:
                fatalError()
            }
        }
        
        return  nfaStack.first!
    }
}
