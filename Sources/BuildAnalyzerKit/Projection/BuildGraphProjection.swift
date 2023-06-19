//
//  File.swift
//  
//
//  Created by Bartosz Polaczyk on 6/18/23.
//

import Foundation

/// How should the graph be layout in the UI
public enum BuildGraphProjectionLayoutType {
    /// The standard graph layout
    case flow
    /// Show nodes in a circular manner (e.g. when a cycle has been found)
    case circular
}

/// Describes which part the build graph should be presented
/// The`BuildGraphView` might be a better name, but to not mislead with UI views
/// using a "projection" term
public protocol BuildGraphProjection {
    var type: BuildGraphProjectionLayoutType  { get }
    var nodes: [BuildGraphNodeId: BuildGraphNodeProjectionNode] { get set }
}

// Consider skipping the Protocol/Impl
public class BuildGraphProjectionImpl: BuildGraphProjection {
    public let type: BuildGraphProjectionLayoutType
    public var nodes: [BuildGraphNodeId: BuildGraphNodeProjectionNode]

    public init(nodes: [BuildGraphNodeProjectionNode], type: BuildGraphProjectionLayoutType) {
        self.nodes = nodes.reduce(into: [:], { hash, node in
            hash[node.node] = node
        })
        self.type = type
    }
}
