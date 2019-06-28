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
    var nodeFillColorHex: String { get }
    
    var normalNextNodes: [GraphNode] { get }
    var extraNextNodes: [GraphNode] { get }
    func pathDeskForNextNode(_ node: GraphNode) -> String
}

extension BaseState: GraphNode {
    var nodeName: String {
        if let stateName = self.stateName {
            return stateName
        } else {
            self.stateName = RegSwift.nameCreator!.nextName()
            return self.stateName!
        }
    }
    
    var nodeFillColorHex: String {
        if self is StartState {
            return "#2cbb4d" //some green
        }
        let colorDesp = self.isAccepted ? "#fd8c25" : "#ffffff" //some orange or white
        return colorDesp
    }
    
    var normalNextNodes: [GraphNode] { return self.outs }
    var extraNextNodes: [GraphNode] {
        guard let splitOutState = self as? SplitOutState,
            let backSplitState = splitOutState.backingSplitState else { return [] }
        return [backSplitState]
    }
    
    func pathDeskForNextNode(_ node: GraphNode) -> String {
        if let splitOut = self as? SplitOutState,
            let repeatState = node as? RepeatState,
            splitOut.backingSplitState == repeatState {
            return "repeat"
        } else {
            return (node as! BaseState).inputsDesp ?? "NEEDFIX"
        }
    }
}
