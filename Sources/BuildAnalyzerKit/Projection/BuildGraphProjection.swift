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
    var highlightedEdges: Set<BuildGraphEdge> {get set}
}

public extension BuildGraphProjection {
    var highlightedNodes: Set<BuildGraphNodeId> {
        set {
            nodes = nodes.mapValues { node in
                var newNode = node
                newNode.highlighted = newValue.contains(node.node)
                return newNode
            }
        }
        get {
            Set(nodes.values.filter({$0.highlighted}).map(\.node))
        }
    }
}

// Consider skipping the Protocol/Impl
public class BuildGraphProjectionImpl: BuildGraphProjection {
    public let type: BuildGraphProjectionLayoutType
    public var nodes: [BuildGraphNodeId: BuildGraphNodeProjectionNode]
    public var highlightedEdges: Set<BuildGraphEdge>

    public init(nodes: [BuildGraphNodeProjectionNode], type: BuildGraphProjectionLayoutType, highlightedEdges: Set<BuildGraphEdge>) {
        self.nodes = nodes.reduce(into: [:], { hash, node in
            hash[node.node] = node
        })
        self.type = type
        self.highlightedEdges = highlightedEdges
    }
}


extension BuildGraphProjectionImpl {
    public static var empty: BuildGraphProjectionImpl {
        return BuildGraphProjectionImpl(nodes: [], type: .flow, highlightedEdges: [])
    }
}

extension BuildGraphProjectionImpl {
    public convenience init(startingNode: BuildGraphNodeId) {
        // Assume the node hides something by default. Otherwise, it wouldn't be considered in the appending flow
        self.init(nodes: [
            .init(node: startingNode, inputNodes: [], outputNodes: [], hidesSomeInputs: true, hidesSomeOutputs: true, level: 0, highlighted: false)
        ], type: .flow, highlightedEdges: [])
    }
}

extension BuildGraphProjectionImpl {
    public convenience init(startingNodes: Set<BuildGraphNodeId>, highlightedNodes: [BuildGraphNodeId]) {
        let allNodes = startingNodes.map { startingNodeId in
            BuildGraphNodeProjectionNode(node: startingNodeId, inputNodes: [], outputNodes: [], hidesSomeInputs: true, hidesSomeOutputs: true, level: 0, highlighted: highlightedNodes.contains(startingNodeId))
        }
        self.init(nodes: allNodes, type: .flow, highlightedEdges: [])
    }
}
