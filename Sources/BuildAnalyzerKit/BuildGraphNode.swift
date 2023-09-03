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
    public enum Kind: Hashable, Comparable {
        // Group of the kind - used to group all nodes in the Hierarchy outline (left pane)
        public enum Group: Comparable {
            case action
            case targetAction
            case step
            case artificial
            case file
            case other
        }
        
        case action(actionName: String, target: String, hash: String, name: String)
        case targetAction(actionName: String, target: String, package: String, packageType: String, sdkRoot: String, sdkVariant: String, name: String)
        case step(stepName: String, path: String)
        case artificial(id: String, target: String, name: String)
        case file(path: String)
        case other(value: String)

        public var group:  Group {
            switch self {
            case .action: return .action
            case .targetAction: return .targetAction
            case .step: return .step
            case .artificial: return .artificial
            case .file: return .file
            case .other: return .other
            }
        }

        public static func generateKind(name: String) -> Kind {
            do {
                if let result = try /<(?<g1>[^-]+)-(?<g2>[^-]+)-(?<hash>[^-]*)--(?<suf>.*)>/.firstMatch(in: name) {
                    // e.g. <target-ProjectTarget-f7c7f4eb947860cad1bd0ac8da2fbab7b297c560689668aabd8feed2d35e08a1--HeadermapTaskProducer>
                    let o = result.output
                    return .action(actionName: String(o.g1), target: String(o.g2), hash: String(o.hash), name: String(o.suf))
                } else if let result = try /<(?<g1>[^-]+)-(?<g2>[^-]+)-PACKAGE-(?<packageType>[^:]+):(?<package>[^-]+)-SDKROOT:(?<sdkRoot>[^:]*):SDK_VARIANT:(?<sdkVariant>[^-]*)-(?<suf>.*)>/.firstMatch(in: name) {
                    // e.g. <target-ProjectTarget-f7c7f4eb947860cad1bd0ac8da2fbab7b297c560689668aabd8feed2d35e08a1--HeadermapTaskProducer>
                    let o = result.output
                    return .targetAction(actionName: String(o.g1), target: String(o.g2), package: String(o.package), packageType: String(o.packageType), sdkRoot: String(o.sdkRoot), sdkVariant: String(o.sdkVariant), name: String(o.suf))
                } else if let result = try /<(?<g1>[^-]+)-(?<g2>[^-]+)-(?<hash>.*)-(?<unknown>.*)-(?<suf>.*)>/.firstMatch(in: name) {
                    // e.g. <target-ProjectTarget-f7c7f4eb947860cad1bd0ac8da2fbab7b297c560689668aabd8feed2d35e08a1--HeadermapTaskProducer>
                    let o = result.output
                    return .action(actionName: String(o.g1), target: String(o.g2), hash: String(o.hash), name: String(o.suf))
                } else if let result = try /<(?<action>\S+)[\ -](?<input>.*)>/.firstMatch(in: name) {
                    // e.g. <MkDir /Some/Path/DerivedData/ProjectName/Build/Products/Debug-iphonesimulator/AppName.app>
                    let o = result.output
                    return .step(stepName: String(o.action), path: String(o.input))
                } else if let result = try /P\d+:.*target-(?<target>[^-]+).*-(?<action>\S+) ?(?<input>.*)/.firstMatch(in: name) {
                    // e.g. P0:::Gate target-ProjectName-f7c7f4eb947860cad1bd0ac8da2fbab7ef7654ceda44fdc53d749a5dfb3f4596--ModuleMapTaskProducer
                    let o = result.output
                    return .artificial(id: String(o.action), target: String(o.target), name: String(o.input))
                }else if name.first == "/" {
                    // e.g. /Some/Path/DerivedData/ProjectName/Build/Intermediates.noindex/ProjectName.build/Debug-iphonesimulator/TargetName.build/TargetName-project-headers.hmap
                    return  .file(path: name)
                }
            } catch {
                // TODO: log unknown kind
            }
            return .other(value: name)
        }
    }


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
    public let description: String? = nil
    public let roots: [String]? = nil
    public let expectedOutputs: [String]? = nil
    public let timing: BuildGraphNodeTiming?
    public let kind: Kind

    public init(id: BuildGraphNodeId, tool: String, name: String, properties: [Property : PropertyValue], inputs: Set<BuildGraphNodeId>, outputs: Set<BuildGraphNodeId>, env: [String: String]?, timing: BuildGraphNodeTiming?) {
        self.id = id
        self.tool = tool
        self.name = name
        self.properties = properties
        self.inputs = inputs
        self.outputs = outputs
        self.env = env
        self.timing = timing
        self.kind = Kind.generateKind(name: name)
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
            env: [:],
            timing: nil
        )
    }
}

extension BuildGraphNodeId {
    init(nodeName: BuildManifestId) {
        self.id = nodeName
    }
}
