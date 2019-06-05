//
//  Error.swift
//  RegExSwift
//
//  Created by White on 2019/5/24.
//  Copyright © 2019 Ali-White. All rights reserved.
//

import Foundation

public struct RegExSwiftError: Error {
    let reason: String
    init(_ r: String) { self.reason = r }
}
