// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation



// MARK: Representation of a node/edge in the Graph

public struct BuildGraphNode: Hashable {
    public enum Kind {
        case file
        case action
        case step
        case artificial
        case unknown
    }

    public typealias Property = String
    public typealias PropertyValue = String

    let id: BuildGraphNodeId
    let kind: Kind
    /// Generic properties that should be presented in the "Details" section
    let properties: [Property: PropertyValue]
    let inputs: Set<BuildGraphNode>
    let outputs: Set<BuildGraphNode>
}

public struct BuildGraphNodeProjection {
    let node: BuildGraphNode
    let inputNodes: Set<BuildGraphNode>
    let outputNodes: Set<BuildGraphNode>

    let hidesSomeInputs: Bool
    let hidesSomeOutputs: Bool
}


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
    var nodes: [BuildGraphNode] { get }
    var edges: [BuildGraphEdge] { get }
}

public struct BuildGraphNodeId: Hashable {
    let id: String
}
// TODO: May be useful if a user wants to "select" an edge (not a case for now)
public struct BuildGraphEdge {
    let id: BuildGraphEdgeId
}
public typealias BuildGraphEdgeId = String


// MARK: Allowed API for projecting a graph in UI

public enum BuildGraphProtocolExtension {
    /// user wants to see more inputs of a node
    case inputs(of: BuildGraphNodeId)
    /// user wants to see more outputs of a node
    case outputs(of: BuildGraphNodeId)
}

public protocol BuildGraphProtocol {
    func extend(view: BuildGraphProjection, with: BuildGraphProtocolExtension) -> BuildGraphProjection
}

public class BuildGraph: BuildGraphProtocol {
    public func extend(view: BuildGraphProjection, with: BuildGraphProtocolExtension) -> BuildGraphProjection {
        // TOOD: implement
        return view
    }
}

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
        return BuildGraph()
    }
}
