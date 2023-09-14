//
//  File.swift
//  
//
//  Created by Bartosz Polaczyk on 6/18/23.
//

import Foundation

struct BuildGraphPath: Hashable {
    let path: [BuildGraphNodeId]
    let nodes: Set<BuildGraphNodeId>

    init(path: [BuildGraphNodeId], nodes: Set<BuildGraphNodeId>) {
        self.path = path
        self.nodes = nodes
    }

    func withEnqueuedNode(_ node: BuildGraphNodeId) -> BuildGraphPath {
        return BuildGraphPath(path: path + [node], nodes: nodes.union([node]))
    }

    init(node: BuildGraphNodeId) {
        self.path = [node]
        self.nodes = [node]
    }
}

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
        case .cycle(_, let cycle):
            extraNodes = Set(cycle)
            break
        case .path(let nodes):
            // find path
            let path = nodeSwarm(nodes: nodes)
            extraNodes.formUnion(Set(path))
        }
        newProjection.nodes[node.id] = projectionNode

        let allNewNodes = extraNodes.union(newProjection.nodes.keys)
        // Add nodes that have been hoisted into the graph as an input/output
        for extraNodeId in extraNodes {
            guard let extraNode = nodes[extraNodeId] else {
                // consistency error
                fatalError("Extra node is not available in the graph. Consistency error")
            }
            let hasAllInputs = extraNode.inputs.allSatisfy(allNewNodes.contains)
            let hasAllOutputs = extraNode.outputs.allSatisfy(allNewNodes.contains)
            newProjection.nodes[extraNode.id] = BuildGraphNodeProjectionNode(
                node: extraNode.id,
                inputNodes: extraNode.inputs.filter({allNewNodes.contains($0)}),
                outputNodes: extraNode.outputs.filter({allNewNodes.contains($0)}),
                hidesSomeInputs: !hasAllInputs,
                hidesSomeOutputs: !hasAllOutputs,
                level: projectionNode.level + expansion.levelDirection,
                highlighted: projection.nodes[extraNode.id]?.highlighted == true // keep the highlight if it already been highlighted
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

    // Returns a smallest subgraph that includes all connected nodes
    private func nodeSwarm(nodes swarmNodes: Set<BuildGraphNodeId>) -> [BuildGraphNodeId] {
        // make n-direction BDF search

        guard swarmNodes.count > 1 else {
            return Array(swarmNodes)
        }

        var leftNodes = swarmNodes
        // the set of all nodes required to render nodes in a subset
        var resultNodes = Set<BuildGraphNodeId>()
        // from the source to the destination
        var shortestPaths: [BuildGraphNodeId: [BuildGraphNodeId: BuildGraphPath]] = [:]
        let pathsToProcess = Queue<BuildGraphPath>()

        // start with each nodes
        for swarmNode in swarmNodes{
            let path = BuildGraphPath(node: swarmNode)
            pathsToProcess.enqueue(path)
            shortestPaths[swarmNode] = [:]
        }


        while let path = pathsToProcess.dequeue(), !leftNodes.isEmpty {
            // we know there is at least 1 element in a path
            let startNode = path.path.first!
            let endNode = path.path.last!

            guard shortestPaths[startNode]?[endNode] == nil else {
                // we have already been here
                continue
            }
            shortestPaths[startNode]![endNode] = path
            guard let endNodeInfo = nodes[endNode] else {
                fatalError("Consistency error: missing \(endNode) in a projection")
            }
            // copying a set because in a loop we modify the set itself
            let iterationNodes = leftNodes
            for leftNode in iterationNodes {
                guard leftNodes.contains(leftNode) else {
                    // we don't want to double check nodes that have already been deleted in a previous iteration
                    continue
                }
                guard leftNode != startNode else {
                    // no need to find a path to itself
                    continue
                }
                if let leftNodeShortestPathToEnd = shortestPaths[leftNode]?[endNode] {
                    // we found the shortest path between leftNode and startNode
                    let nodesToAddToSwarm = path.nodes.union(leftNodeShortestPathToEnd.nodes)
                    // pick only the path if it is connected with the rest of the resultNodes
                    if resultNodes.isEmpty ||  !resultNodes.isDisjoint(with: nodesToAddToSwarm) {
                        leftNodes.remove(leftNode)
                        leftNodes.remove(startNode)
                        // add nodes from start->end
                        resultNodes.formUnion(nodesToAddToSwarm)
                        continue
                    }
                }
            }
            for neighbor in endNodeInfo.inputs.union(endNodeInfo.outputs) {
                guard !path.nodes.contains(neighbor) else {
                    // we are in a cycle - no need to check that infinite path
                    continue
                }
                if shortestPaths[startNode]![neighbor] != nil {
                    // we have already found not a worse path between them
                    continue
                }
                pathsToProcess.enqueue(path.withEnqueuedNode(neighbor))
            }
        }
        return Array(resultNodes)
    }
}
