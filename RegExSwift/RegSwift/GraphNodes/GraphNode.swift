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
    var nodeFillColorHex: String { get }
    
    var normalNextNodes: [GraphNode] { get }
    var extraNextNodes: [GraphNode] { get }
    func pathDespForNextNode(_ node: GraphNode) -> String
}

extension BaseState: GraphNode {
    var nodeFillColorHex: String {
        if (self.isAccepted) {
            return "#ffffff";
        } else {
            switch self.styleType {
            case .Start:
                return "#ffffff";
            case .Normal:
                return "#ffffff";
            case .Highlighted:
                return "#fd8c25";
            }
        }
    }
    
    var normalNextNodes: [GraphNode] {
        return self.graphicOuts()
    }
    var extraNextNodes: [GraphNode] {
        guard let repeatOutState = self as? DumbState,
            let repeatState = repeatOutState.delegate as? RepeatState else { return [] }
        return [repeatState]
    }
    
    func pathDespForNextNode(_ node: GraphNode) -> String {
        if let repeatOut = self as? DumbState,
            let repeatState = node as? RepeatState,
            let delegateRepeat = repeatOut.delegate as? RepeatState,
            delegateRepeat === repeatState {
            return "repeat"
        } else {
            return (node as! BaseState).acceptanceDesp ?? "NEEDFIX"
        }
    }
}
