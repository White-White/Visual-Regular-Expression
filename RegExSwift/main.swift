//
//  main.swift
//  RegExSwift
//
//  Created by White on 2019/5/14.
//  Copyright © 2019 Ali-White. All rights reserved.
//

import Foundation

let testPattern = "\\\\"
let matchTarget = "\\"


let rg = try! NSRegularExpression.init(pattern: testPattern, options: .caseInsensitive)

let matches = rg.matches(in: matchTarget, options: .anchored, range: NSMakeRange(0, (matchTarget as NSString).length))

print(matches.count)

do {
    let pattern = "sdf.[1-6a-z1-7]sdf(dsdsdf(a|b)|c*d\\\\)"
    let _ = try RegSwift(pattern: pattern)
} catch {
    
}



