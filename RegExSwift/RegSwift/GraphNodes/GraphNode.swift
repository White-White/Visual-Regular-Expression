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
    var nodeFillColorHex: String { get }
    var nextNodes: [GraphNode] { get }
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
    var inputCharactersDescription: String { return self.inputsDesp ?? "NEEDFIX" }
    
    var nodeFillColorHex: String {
        if self is StartState {
            return "#2cbb4d" //some green
        }
        return self.isAccepted ? "#fd8c25" : "#ffffff" //some orange or white
    }
    
    var nextNodes: [GraphNode] { return self.possibleOuts() as [GraphNode] }
}
