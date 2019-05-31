//
//  RepeatChecker.swift
//  RegExSwift
//
//  Created by White on 2019/5/30.
//  Copyright © 2019 Ali-White. All rights reserved.
//

import Foundation

class RepeatChecker {
    private let lowerBound: UInt
    private let upperBound: UInt
    private var repeatCount: UInt = 0
    
    private init(l: UInt, u: UInt) {
        self.lowerBound = l
        self.upperBound = u
    }
    
    convenience init(with functionalSemanticUnit: FunctionalSemantic) {
        switch functionalSemanticUnit.functionalSemanticType {
        case .Plus:
            self.init(l: 1, u: UInt.max)
        case .Star:
            self.init(l: 0, u: UInt.max)
        default:
            fatalError() //impossible case.
        }
    }
    
    func repeatCriteriaHasBeenMet() -> Bool {
        return repeatCount >= self.lowerBound && repeatCount <= self.upperBound
    }
    
    func canRepeat() -> Bool {
        return self.repeatCount < self.upperBound
    }

    func forward() {
        repeatCount += 1
    }
}
