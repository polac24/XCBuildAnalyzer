//
//  File.swift
//  
//
//  Created by Bartosz Polaczyk on 6/18/23.
//

import Foundation


public struct BuildGraphNodeProjectionNode {
    let node: BuildGraphNodeId
    var inputNodes: Set<BuildGraphNodeId>
    var outputNodes: Set<BuildGraphNodeId>

    var hidesSomeInputs: Bool
    var hidesSomeOutputs: Bool

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
