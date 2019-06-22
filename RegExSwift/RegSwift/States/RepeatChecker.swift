//
//  RepeatChecker.swift
//  RegExSwift
//
//  Created by White on 2019/5/30.
//  Copyright © 2019 Ali-White. All rights reserved.
//

import Foundation

class RepeatChecker {
    private let quantifier: QuantifierMenifest
    private var repeatCount: UInt = 0
    
    init(with quantifier: QuantifierMenifest) {
        self.quantifier = quantifier
    }
    
    func repeatCriteriaHasBeenMet() -> Bool {
        return repeatCount >= quantifier.lowerBound && repeatCount <= quantifier.higherBound
    }
    
    func canRepeat() -> Bool {
        return self.repeatCount < quantifier.higherBound
    }

    func forward() {
        repeatCount += 1
    }
}
