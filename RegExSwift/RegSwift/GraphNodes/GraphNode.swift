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
    var nodeName: String? { get }
    var nodeFillColorHex: String { get }
    
    var normalNextNodes: [GraphNode] { get }
    var extraNextNodes: [GraphNode] { get }
    func pathDespForNextNode(_ node: GraphNode) -> String
    func pathWeightForNextNode(_ node: GraphNode) -> Int
}

extension BaseState: GraphNode {
    
    var nodeName: String? { return self.stateName }
    
    var nodeFillColorHex: String {
        switch self.styleType {
        case .Start:
            return "#ffffff";
        case .Normal:
            return "#ffffff";
        case .Highlighted:
            return "#fd8c25";
        }
    }
    
    var normalNextNodes: [GraphNode] {
        return self.graphicOuts()
    }
    
    var extraNextNodes: [GraphNode] {
        guard let conditionalOut = self.conditionalOut else { return [] }
        return [conditionalOut]
    }
    
    func pathDespForNextNode(_ node: GraphNode) -> String {
        return (node as! BaseState).acceptanceDesp ?? "NEEDFIX"
    }
    
    func pathWeightForNextNode(_ node: GraphNode) -> Int {
        guard let weight = self.weightRecords[(node as! BaseState)] else { return 1 }
        switch weight {
        case .Important:
            return 2
        case .Normal:
            return 1
        }
    }
}
