//
//  File.swift
//
//
//  Created by Bartosz Polaczyk on 6/18/23.
//

import Foundation


public class BuildGraph: BuildGraphProtocol{
    public private(set) var nodes: [BuildGraphNodeId: BuildGraphNode]

    init(nodes: [BuildGraphNodeId: BuildGraphNode]) {
        self.nodes = nodes
    }
}



public extension BuildGraph {
    convenience init(manifest: BuildManifest) {
        self.init(nodes: Self.buildAllNodes(commands: manifest.commands))
    }

    private static func buildAllNodes(commands: [String: BuildManifestCommand]) ->  [BuildGraphNodeId: BuildGraphNode] {
        var visitedNodes: [BuildGraphNodeId: BuildGraphNode] = [:]
        for (commandName, command) in commands {
            // inputs
            let inputIds = (command.inputs ?? []).map { inputName in
                let nodeId = BuildGraphNodeId(nodeName: inputName)
                var input = visitedNodes[nodeId, default: .buildEmpty(id: nodeId, name: inputName)]
                input.outputs = input.outputs.union([nodeId])
                visitedNodes[nodeId] = input
                return nodeId
            }

            // outputs
            let outputIds = (command.outputs ?? []).map { outputName in
                let nodeId = BuildGraphNodeId(nodeName: outputName)
                var output = visitedNodes[nodeId, default: .buildEmpty(id: nodeId, name: outputName)]
                output.inputs = output.inputs.union([nodeId])
                visitedNodes[nodeId] = output
                return nodeId
            }

            // actual command node
            let nodeId = BuildGraphNodeId(nodeName: commandName)
            let node = BuildGraphNode(
                id: nodeId,
                tool: command.tool,
                name: commandName,
                properties: properties(from: command),
                inputs: Set(inputIds),
                outputs: Set(outputIds)
            )
            visitedNodes[nodeId] = node
        }
        return visitedNodes
    }

    private static func properties(from: BuildManifestCommand) -> [BuildGraphNode.Property: BuildGraphNode.PropertyValue] {
        // Implement reading all required and optional fields
        return [:]
    }
}
