//
//  File.swift
//  
//
//  Created by Bartosz Polaczyk on 6/18/23.
//

import Foundation


public protocol BuildGraphProtocol: AnyObject {
    var nodes: [BuildGraphNodeId: BuildGraphNode] { get }
    var cycles: [[BuildGraphNodeId]] {get}

    func expand(projection: BuildGraphProjection, with: BuildGraphProjectionExpansion) -> BuildGraphProjection
}

public extension BuildGraphProtocol {
    var cycleNodes: [BuildGraphNodeId] {
        return cycles.flatMap({$0})
    }
}
