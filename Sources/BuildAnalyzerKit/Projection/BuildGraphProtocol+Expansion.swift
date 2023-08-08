//
//  File.swift
//  
//
//  Created by Bartosz Polaczyk on 6/18/23.
//

import Foundation

public extension BuildGraphProtocol {

    func expand(projection: BuildGraphProjection, with expansion: BuildGraphProjectionExpansion) -> BuildGraphProjection {
        guard let node = nodes[expansion.nodeId] else {
            // TODO: log expansion nodeId misalignment (the nodeId is apparently invalid)
            return projection
        }
        var newProjection = projection
        guard var projectionNode = projection.nodes[expansion.nodeId] else {
            print("The expansion node is not visible: consistency error")
            return projection
        }
        var extraNodes = Set<BuildGraphNodeId>()
        switch expansion {
        case .inputs(_, let maxCount):
            guard projectionNode.hidesSomeInputs else {
                // TODO: log there is nothing to expand
                return projection
            }
            let previousInputs = projectionNode.inputNodes
            let actualInputs = node.inputs
            let hiddenInputs = actualInputs.subtracting(previousInputs)
            let expansionInputs = hiddenInputs.prefix(maxCount)
            extraNodes.formUnion(expansionInputs)

            // TODO: append up to n elements only
            projectionNode.inputNodes = projectionNode.inputNodes.union(expansionInputs)
            projectionNode.hidesSomeInputs = projectionNode.inputNodes.count != node.inputs.count
        case .outputs(_, let maxCount):
            guard projectionNode.hidesSomeOutputs else {
                // TODO: log there is nothing to expand
                return projection
            }
            let previousOutputs = projectionNode.outputNodes
            let actualOutputs = node.outputs
            let hiddenOutputs = actualOutputs.subtracting(previousOutputs)
            let expansionOutputs = hiddenOutputs.prefix(maxCount)
            extraNodes.formUnion(expansionOutputs)

            // TODO: append up to n
            projectionNode.outputNodes = projectionNode.outputNodes.union(expansionOutputs)
            projectionNode.hidesSomeOutputs = projectionNode.outputNodes.count != node.outputs.count
        }
        newProjection.nodes[node.id] = projectionNode

        let allNewNodes = extraNodes.union(newProjection.nodes.keys)
        // Add nodes that have been hoisted into the graph as an input/output
        for extraNodeId in extraNodes {
            guard newProjection.nodes[extraNodeId] == nil else {
                // it is already added to the graph projection (probably some other dependency already referenced it)
                continue
            }
            guard let extraNode = nodes[extraNodeId] else {
                // consistency error
                fatalError("Extra node is not available in the graph. Consistency error")
            }
            let hasAllInputs = extraNode.inputs.allSatisfy(allNewNodes.contains)
            let hasAllOutputs = extraNode.outputs.allSatisfy(allNewNodes.contains)
            newProjection.nodes[extraNode.id] = BuildGraphNodeProjectionNode(
                node: extraNode.id,
                inputNodes: [],
                outputNodes: [],
                hidesSomeInputs: !hasAllInputs,
                hidesSomeOutputs: !hasAllOutputs,
                level: projectionNode.level + expansion.levelDirection,
                highlighted: false
            )
        }

        return newProjection
    }

    func highlight(nodeId: BuildGraphNodeId?, projection: BuildGraphProjection) -> BuildGraphProjection {
        var newProjection = projection

        for (key, _) in projection.nodes {
            newProjection.nodes[key]?.highlighted = key == nodeId
        }
        return newProjection
    }
}
