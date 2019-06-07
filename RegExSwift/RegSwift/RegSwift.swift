//
//  RegSwift.swift
//  RegExSwift
//
//  Created by White on 2019/5/29.
//  Copyright © 2019 Ali-White. All rights reserved.
//

import Foundation

public class RegSwift: NSObject {
    private let headState: BaseState
    private let parrern: String
    
    @objc
    public init(pattern: String) throws {
        self.parrern = pattern
        let lexer = Lexer(pattern: pattern)
        let lexemes = try lexer.createLexemes()
        let parser = try Parser(lexemes: lexemes)
        let semanticUnits = try parser.getSemanticUnits()
        let headState = try StatesCreator.createHeadState(from: semanticUnits)
        self.headState = headState
    }
    
    func match(_ m: String) throws -> Bool {
        print("开始匹配。预置pattern: \(self.parrern)")
        print("目标string: \(m)")
        
        guard !m.isEmpty else { throw RegExSwiftError("Error: Target string is empty") }
        var evolve: [BaseState] = [headState]
        for character in m {
            print("开始尝试匹配\(character)")
            print("当前结果: evolve包含\(evolve.count)个状态:")
            evolve.forEach { print($0) }
            
            //e演进
            print("ε 演进开始")
            evolve = evolve.flatMap { $0.forwardWithEmptyInput() }
            print("ε 演进结果: evolve包含\(evolve.count)个状态:")
            evolve.forEach { print($0) }
            
            //character演进
            print("\(character) 演进开始")
            evolve = evolve.flatMap { $0.forwardWithInput(character) }
            print("ε 演进结果: evolve包含\(evolve.count)个状态:")
            evolve.forEach { print($0) }
            
            //结果检查
            if evolve.contains(where: { $0 === AcceptState.shared }) {
                print("本次演进找到接受结果，演进结束")
                return true
            }
        }
        
        print("本次匹配未找到接受结果")
        return false
    }
}

//MARK: - Nodes
extension RegSwift {
    @objc
    public func getNodeHead() -> GraphNode {
        return self.headState as GraphNode
    }
}
