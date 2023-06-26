//
//  File.swift
//  
//
//  Created by Bartosz Polaczyk on 6/18/23.
//

import Foundation


public struct BuildGraphNodeProjectionNode: Comparable {
    // An opinionated sorting order - it is used to have a deterministic projection in the UI
    public static func < (lhs: BuildGraphNodeProjectionNode, rhs: BuildGraphNodeProjectionNode) -> Bool {
        lhs.node.id < rhs.node.id
    }

    public let node: BuildGraphNodeId
    public internal(set) var inputNodes: Set<BuildGraphNodeId>
    public internal(set) var outputNodes: Set<BuildGraphNodeId>

    public internal(set) var hidesSomeInputs: Bool
    public internal(set) var hidesSomeOutputs: Bool

    public init(
        node: BuildGraphNodeId,
        inputNodes: Set<BuildGraphNodeId>,
        outputNodes: Set<BuildGraphNodeId>,
        hidesSomeInputs: Bool,
        hidesSomeOutputs: Bool
    ) {
        self.node = node
        self.inputNodes = inputNodes
        self.outputNodes = outputNodes
        self.hidesSomeInputs = hidesSomeInputs
        self.hidesSomeOutputs = hidesSomeOutputs
    }
}

extension BuildGraphNodeProjectionNode {
    /// Builds an isolated projection node that contracts all input and outpus
    func buildIsolated(for node: BuildGraphNode) -> Self {
        return .init(
            node: node.id,
            inputNodes: [],
            outputNodes: [],
            hidesSomeInputs: !node.inputs.isEmpty,
            hidesSomeOutputs: !node.outputs.isEmpty
        )
    }
}
