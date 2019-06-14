//
//  Error.swift
//  RegExSwift
//
//  Created by White on 2019/5/24.
//  Copyright © 2019 Ali-White. All rights reserved.
//

import Foundation

public class RegExSwiftError: CustomNSError {
    let reason: String
    init(_ r: String) { self.reason = r }
    
    public static var errorDomain: String { return "RegExSwift" }
    public var errorCode: Int { return 0 }
    public var errorUserInfo: [String : Any] { return [:] }
    public var localizedDescription: String { return self.reason }
}
