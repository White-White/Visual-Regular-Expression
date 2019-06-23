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
    var nodeName: String {
        if let stateName = self.stateName {
            return stateName
        } else {
            self.stateName = RegSwift.nameCreator!.nextName()
            return self.stateName!
        }
    }
    var inputCharactersDescription: String { return self.inputsDesp ?? "NEEDFIX" }
    var highLighted: Bool { return self.isAccepted }
    var nextNodes: [GraphNode] { return self.possibleOuts() as [GraphNode] }
}
