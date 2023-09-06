//
//  File.swift
//  
//
//  Created by Bartosz Polaczyk on 6/18/23.
//

import Foundation


/// The node identifier in the the Build Graph context
/// (Now, the id represents the command id string)
public struct BuildGraphNodeId: Hashable, Equatable {
    public let id: String

    public init(id: String) {
        self.id = id
    }
}

// Not in use for now
public typealias BuildGraphEdgeId = String
public struct BuildGraphEdge: Hashable, Equatable {
    let source: BuildGraphNodeId
    let destination: BuildGraphNodeId

    public init(source: BuildGraphNodeId, destination: BuildGraphNodeId) {
        self.source = source
        self.destination = destination
    }
}

public struct BuildGraphNode: Hashable, Equatable {
    public typealias Property = String
    public typealias PropertyValue = String

    public let id: BuildGraphNodeId
    public let tool: String
    public let name: String
    /// Generic properties that should be presented in the "Details" section
    public var properties: [Property: PropertyValue]
    public var inputs: Set<BuildGraphNodeId>
    public var outputs: Set<BuildGraphNodeId>
    public let env: [String: String]?
    public let description: String?
    public let roots: [String]?
    public let expectedOutputs: [String]?
    public let args: [String]?
    public let signature: String?
    public let workingDirectory: String?
    public let timing: BuildGraphNodeTiming?
    public let kind: BuildGraphNode.Kind

    public init(id: BuildGraphNodeId, tool: String, name: String, properties: [Property : PropertyValue], inputs: Set<BuildGraphNodeId>, outputs: Set<BuildGraphNodeId>, expectedOutputs: [String]?, roots: [String]?, env: [String: String]?, description: String?, args: [String]?, signature: String?, workingDirectory: String?, timing: BuildGraphNodeTiming?) {
        self.id = id
        self.tool = tool
        self.name = name
        self.properties = properties
        self.inputs = inputs
        self.outputs = outputs
        self.env = env
        self.timing = timing
        self.kind = Kind.generateKind(name: name)
        self.args = args
        self.signature = signature
        self.workingDirectory = workingDirectory
        self.description = description
        self.roots = roots
        self.expectedOutputs = expectedOutputs
    }
}

// MARK: Helper static methods to build Node and NodeId

extension BuildGraphNode {
    static func buildEmpty(id: BuildGraphNodeId, name: String) -> Self {
        return .init(
            id: id,
            tool: "",
            name: name,
            properties: [:],
            inputs: [],
            outputs: [],
            expectedOutputs: nil,
            roots: nil, 
            env: [:],
            description: nil,
            args: nil,
            signature: nil,
            workingDirectory: nil,
            timing: nil
        )
    }
}

extension BuildGraphNodeId {
    init(nodeName: BuildManifestId) {
        self.id = nodeName
    }
}
