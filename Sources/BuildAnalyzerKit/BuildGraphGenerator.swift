// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation


// MARK: Building a graph

public protocol BuildGraphGenerator  {
    func build() throws -> BuildGraphProtocol
}

public class FileGraphGenerator: BuildGraphGenerator {
    
    private let path: URL

    public init(_ path: URL){
        self.path = path
    }

    public func build() throws -> BuildGraphProtocol {
        return BuildGraph(nodes: [:], cycles: [], buildInterval: nil)
    }
}
