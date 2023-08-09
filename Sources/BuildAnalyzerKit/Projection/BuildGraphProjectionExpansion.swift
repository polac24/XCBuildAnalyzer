//
//  File.swift
//  
//
//  Created by Bartosz Polaczyk on 6/18/23.
//

import Foundation

/// Describes how the projection should be expanded
public enum BuildGraphProjectionExpansion {
    /// user wants to see more inputs of a node
    case inputs(of: BuildGraphNodeId, count: Int = 100)
    /// user wants to see more outputs of a node
    case outputs(of: BuildGraphNodeId, count: Int = 100)
    /// include a cycle of nodes
    case cycle(of: BuildGraphNodeId, cycle: [BuildGraphNodeId])
}

extension BuildGraphProjectionExpansion {
    var nodeId: BuildGraphNodeId {
        switch self {
        case .inputs(of: let nodeId, _):
            return nodeId
        case .outputs(of: let nodeId, _):
            return nodeId
        case .cycle(of: let nodeId, _):
            return nodeId
        }
    }
}

extension BuildGraphProjectionExpansion {
    var levelDirection: Int {
        switch self {
        case .inputs:
            return -1
        case .outputs:
            return 1
        case .cycle:
            return -2
        }
    }
}
