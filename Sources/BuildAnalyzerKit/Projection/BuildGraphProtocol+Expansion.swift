//
//  File.swift
//  
//
//  Created by Bartosz Polaczyk on 6/18/23.
//

import Foundation

public extension BuildGraphProtocol {

    func expand(projection: BuildGraphProjection, with expansion: BuildGraphProjectionExpansion) -> BuildGraphProjection {
        guard let node = nodes[expansion.nodeId], let projectionNode = projection.nodes[expansion.nodeId] else {
            // TODO: log expansion nodeId misalignment (the nodeId is apparently invalid)
            return projection
        }
        var newProjection = projection
        var newProjectionNode = projectionNode
        switch expansion {
        case .inputs(_, let maxCount):
            guard newProjectionNode.hidesSomeInputs else {
                // TODO: log there is nothing to expand
                return projection
            }
            let previousInputs = newProjectionNode.inputNodes
            let actualInputs = node.inputs
            let hiddenInputs = actualInputs.subtracting(previousInputs)
            let expansionInputs = hiddenInputs.prefix(maxCount)

            // append up to n
            newProjectionNode.inputNodes = projectionNode.inputNodes.union(expansionInputs)
            newProjectionNode.hidesSomeInputs = projectionNode.inputNodes.count != newProjectionNode.inputNodes.count
        case .outputs(_, let maxCount):
            guard newProjectionNode.hidesSomeOutputs else {
                // TODO: log there is nothing to expand
                return projection
            }
            let previousOutputs = newProjectionNode.outputNodes
            let actualOutputs = node.outputs
            let hiddenOutputs = actualOutputs.subtracting(previousOutputs)
            let expansionOutputs = hiddenOutputs.prefix(maxCount)

            // append up to n
            newProjectionNode.outputNodes = projectionNode.outputNodes.union(expansionOutputs)
            newProjectionNode.hidesSomeOutputs = projectionNode.outputNodes.count != newProjectionNode.outputNodes.count
        }
        newProjection.nodes[node.id] = newProjectionNode

        return newProjection
    }
}
