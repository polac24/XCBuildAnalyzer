//
//  File.swift
//
//
//  Created by Bartosz Polaczyk on 6/18/23.
//

import Foundation


public class BuildGraph: BuildGraphProtocol{
    public private(set) var nodes: [BuildGraphNodeId: BuildGraphNode]

    public init(nodes: [BuildGraphNodeId: BuildGraphNode]) {
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
            let commandNodeId = BuildGraphNodeId(nodeName: commandName)

            // inputs
            let inputIds = (command.inputs ?? []).map { inputName in
                let nodeId = BuildGraphNodeId(nodeName: inputName)
                var input = visitedNodes[nodeId, default: .buildEmpty(id: nodeId, name: inputName)]
                input.outputs = input.outputs.union([commandNodeId])
                visitedNodes[nodeId] = input
                return nodeId
            }

            // outputs
            let outputIds = (command.outputs ?? []).map { outputName in
                let nodeId = BuildGraphNodeId(nodeName: outputName)
                var output = visitedNodes[nodeId, default: .buildEmpty(id: nodeId, name: outputName)]
                output.inputs = output.inputs.union([commandNodeId])
                visitedNodes[nodeId] = output
                return nodeId
            }

            // actual command node
            let node = BuildGraphNode(
                id: commandNodeId,
                tool: command.tool,
                name: commandName,
                properties: properties(from: command),
                inputs: Set(inputIds),
                outputs: Set(outputIds)
            )
            visitedNodes[commandNodeId] = node
        }
        return visitedNodes
    }

    private static func properties(from: BuildManifestCommand) -> [BuildGraphNode.Property: BuildGraphNode.PropertyValue] {
        // Implement reading all required and optional fields
        return [:]
    }
}
