//
//  File.swift
//  
//
//  Created by Bartosz Polaczyk on 6/18/23.
//

import Foundation


/// The node identifier in the the Build Graph context
/// (Now, the id represents the command id string)
public struct BuildGraphNodeId: Hashable {
    public let id: String

    public init(id: String) {
        self.id = id
    }
}

// TODO: May be useful if a user wants to "select" an edge (not a case for now)
public struct BuildGraphEdge {
    let id: BuildGraphEdgeId
}
public typealias BuildGraphEdgeId = String

public struct BuildGraphNode: Hashable {
    public enum Kind: Hashable, Comparable {
        // Group of the kind - used to group all nodes in the Hierarchy outline (left pane)
        public enum Group: Comparable {
            case action
            case step
            case artificial
            case file
            case unknown
        }
        
        case action(actionName: String, target: String, hash: String, name: String)
        case step(stepName: String, path: String)
        case artificial(id: String, name: String)
        case file(path: String)
        case unknown
        
        public var group:  Group {
            switch self {
            case .action: return .action
            case .step: return .step
            case .artificial: return .artificial
            case .file: return .file
            case .unknown: return .unknown
            }
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
    public let env: [String: String]? = nil
    public let description: String? = nil
    public let roots: [String]? = nil
    public let expectedOutputs: [String]? = nil

    public var kind: Kind {
        do {
            if let result = try /<(?<g1>[^-]+)-(?<g2>[^-]+)-(?<hash>.*)-(?<unknown>.*)-(?<suf>.*)>/.firstMatch(in: name) {
                // e.g. <target-ProjectTarget-f7c7f4eb947860cad1bd0ac8da2fbab7b297c560689668aabd8feed2d35e08a1--HeadermapTaskProducer>
                let o = result.output
                return .action(actionName: String(o.g1), target: String(o.g2), hash: String(o.hash), name: String(o.suf))
            } else if let result = try /<(?<action>\S+)[\ -](?<input>.*)>/.firstMatch(in: name) {
                // e.g. <MkDir /Some/Path/DerivedData/ProjectName/Build/Products/Debug-iphonesimulator/AppName.app>
                let o = result.output
                return .step(stepName: String(o.action), path: String(o.input))
            } else if let result = try /P\d+:[^:]*:[^:]*:(?<action>\S+) ?(?<input>.*)/.firstMatch(in: name) {
                // e.g. P0:::Gate target-ProjectName-f7c7f4eb947860cad1bd0ac8da2fbab7ef7654ceda44fdc53d749a5dfb3f4596--ModuleMapTaskProducer
                let o = result.output
                return .artificial(id: String(o.action), name: String(o.input))
            }else if name.first == "/" {
                // e.g. /Some/Path/DerivedData/ProjectName/Build/Intermediates.noindex/ProjectName.build/Debug-iphonesimulator/TargetName.build/TargetName-project-headers.hmap
                return  .file(path: name)
            }
        } catch {
            // TODO: log unknown kind
        }
        return .unknown
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
            outputs: []
        )
    }
}

extension BuildGraphNodeId {
    init(nodeName: BuildManifestId) {
        self.id = nodeName
    }
}
