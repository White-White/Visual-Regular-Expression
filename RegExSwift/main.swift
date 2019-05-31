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

//print(matches.count)

do {
    let pattern = "sdf."
    let string = "sfn"
    let regSwift = try RegSwift(pattern: pattern)
    let match = try regSwift.match(string)
    print(match)
} catch {
    
}



