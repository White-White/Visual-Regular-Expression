//
//  GraphNode.swift
//  RegExSwift
//
//  Created by White on 2019/6/7.
//  Copyright © 2019 Ali-White. All rights reserved.
//

import Foundation

@objc
public protocol GraphNode {
    var nodeName: String { get }
    var inputCharactersDescription: String { get }
    var highLighted: Bool { get }
    var nextNodes: [GraphNode] { get }
}

extension BaseState: GraphNode {
//    var nodeName: String { return self.stateName }
    var nodeName: String { return self.debugDescription }
    var inputCharactersDescription: String { return self.inputSetDescription ?? "NEEDFIX" }
    var highLighted: Bool { return false }
    
    var nextNodes: [GraphNode] {
        switch self.stateType {
        case .value:
            return [(self as! ValueState).out as GraphNode]
        case .dumb:
            return [(self as! DumbState).out as GraphNode]
        case .split:
            return [(self as! SplitState).primaryOut, (self as! SplitState).secondaryOut]
        case .repeat:
            let repeatState = (self as! RepeatState)
            var ret: [GraphNode] = [repeatState.repeatingState as GraphNode]
            if repeatState.repeatChecker.repeatCriteriaHasBeenMet() {
                ret.append(repeatState.dummyEnd)
            }
            return ret
        case .accepted:
            return []
        case .class:
            return [(self as! ClassState).out as GraphNode]
        }
    }
}

//public class GraphNodeGenerator: NSObject {
//
//    private var pattern: String
//    private var matchString: String
//
//    private var regSwift: RegSwift
//
//    @objc
//    public init(withPattern pattern: String, matchString: String) throws {
//        self.pattern = pattern
//        self.matchString = matchString
//        self.regSwift = try RegSwift(pattern: pattern)
//    }
//
//    @objc
//    public func forward() {
//
//    }
//}
