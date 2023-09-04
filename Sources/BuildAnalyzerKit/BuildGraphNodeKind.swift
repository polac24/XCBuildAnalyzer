import Foundation

public extension BuildGraphNode {
    indirect enum Kind: Hashable, Comparable {
        // Group of the kind - used to group all nodes in the Hierarchy outline (left pane)
        public enum Group: Comparable {
            case file
            case simpleStep
            case complexStep
            case triggerStep
            case packageProductStep
            case packageTargetStep
            case artificial
            case gate
            case other
            case end
        }

        case simpleStep(stepName: String, file: String)
        case file(path: String)
        case triggerStep(stepName: String, args: [String])
        case end
        case complexStep(stepName: String, target: String)
        case packageProductStep(stepName: String, target: String)
        case packageTargetStep(stepName: String, target: String)
        case gate(index: Int, kind: BuildGraphNode.Kind)
        case artificial(stepName: String, args: [String])
        case other(value: String)

        public var group:  Group {
            switch self {
            case .file: return .file
            case .other: return .other
            case .simpleStep: return .simpleStep
            case .triggerStep: return .triggerStep
            case .end: return .end
            case .complexStep: return .complexStep
            case .packageProductStep: return .packageProductStep
            case .packageTargetStep: return .packageTargetStep
            case .gate: return .gate
            case .artificial: return .artificial
            }
        }

        public static func generateKind(name: String) -> Kind {
            do {
                if name.first == "/" {
                    // e.g. /Some/Path/DerivedData/ProjectName/Build/Intermediates.noindex/ProjectName.build/Debug-iphonesimulator/TargetName.build/TargetName-project-headers.hmap
                    return  .file(path: name)
                } else if name == "<all>" {
                    return  .end
                } else if let result = try /P(?<index>\d+):(?<some>.*):(?<configuration>[^:]*):Gate (?<gateName>.+)/.firstMatch(in: name) {
                    // e.g. P0:::Gate target-XcodeHasher-PACKAGE-TARGET:XcodeHasher-SDKROOT:macosx:SDK_VARIANT:macos-SwiftStandardLibrariesTaskProducer
                    // e.g. P0:target-BuildAnalyzer-be0c796e7ab161295c9e11c90ddae75a2b86e3aa1cc2f374c8ee86a36d7adc00-:Debug:Gate target-BuildAnalyzer-be0c796e7ab161295c9e11c90ddae75a2b86e3aa1cc2f374c8ee86a36d7adc00--entry
                    let o = result.output
                    // wrap the "gate" into <> to match the expected format in generateKind
                    let gateKind = generateKind(name: "<\(o.gateName)>")
                    return .gate(index: Int(o.index) ?? 0, kind: gateKind)
                } else if let result = try /P(?<index>\d+):(?<some>.*):(?<configuration>[^:]*):(?<stepName>\S+)(?: (?<args>.+))?/.firstMatch(in: name) {
                    // e.g. P0:::CreateBuildDirectory /Some/DerivedData/BuildAnalyzer/Build/Intermediates.noindex
                    // P0:target-BuildAnalyzer-be0c796e7ab161295c9e11c90ddae75a2b86e3aa1cc2f374c8ee86a36d7adc00-:Debug:CpResource /Users/bartosz/Development/BuildAnalyzer/DerivedData/BuildAnalyzer/Build/Products/Debug/BuildAnalyzer.app/Contents/Resources/img /Users/bartosz/Development/BuildAnalyzer/BuildAnalyzer/Resources/img

                    let o = result.output
                    // wrap the "gate" into <> to match the expected format in generateKind
                    return .artificial(stepName: String(o.stepName), args:o.args?.components(separatedBy: " ") ?? [])
                } else if let result = try /<TRIGGER: (?<stepName>[^-]+)[ \-](?<args>\/.+)>/.firstMatch(in: name) {
                    // e.g. <CodeSign /SomePath/Build/Products/Debug/BuildAnalyzer.app>
                    // e.g. <CreateBuildDirectory-/SomePath/DerivedData/BuildAnalyzer/Build/Products>>
                    let o = result.output
                    return .triggerStep(stepName: String(o.stepName), args: o.args.components(separatedBy: " "))
                } else if let result = try /<target-(?<targetName>[^-]+)-(?<hash>[0-9a-f]{64})--(?<stepName>.+)>/.firstMatch(in: name) {
                    // e.g. <target-BuildAnalyzer-be0c796e7ab161295c9e11c90ddae75a2b86e3aa1cc2f374c8ee86a36d7adc00--TAPISymbolExtractorTaskProducer>
                    let o = result.output
                    return .complexStep(stepName: String(o.stepName), target: String(o.targetName))
                } else if let result = try /<target-(?<targetName>[^-]+)-PACKAGE-PRODUCT:(?<target>[^-]+)-(?<configuration>[^-]+)-(?<platform>[^-]+)-(?<arch>[^-]+)-(?<stepName>.+)>/.firstMatch(in: name) {
                    // e.g. <target-BuildAnalyzerKit-PACKAGE-PRODUCT:BuildAnalyzerKit-Debug-macosx-arm64-build-headers-stale-file-removal>
                    let o = result.output
                    return .packageProductStep(stepName: String(o.stepName), target: String(o.targetName))
                } else if let result = try /<target-(?<targetName>[^-]+)-PACKAGE-PRODUCT:(?<target>[^-]+)-SDKROOT:(?<platform>[^-]+):SDK_VARIANT:(?<arch>[^-]+)-(?<stepName>.+)>/.firstMatch(in: name) {
                    // e.g. <target-BuildAnalyzerKit-PACKAGE-PRODUCT:BuildAnalyzerKit-SDKROOT:macosx:SDK_VARIANT:macos-begin-compiling>
                    let o = result.output
                    return .packageProductStep(stepName: String(o.stepName), target: String(o.targetName))
                } else if let result = try /<target-(?<targetName>[^-]+)-PACKAGE-TARGET:(?<target>[^-]+)-(?<configuration>[^-]+)-(?<platform>[^-]+)-(?<arch>[^-]+)-(?<stepName>.+)>/.firstMatch(in: name) {
                    // e.g. <target-BuildAnalyzerKit-PACKAGE-TARGET:BuildAnalyzerKit-Debug-macosx-arm64-build-headers-stale-file-removal>
                    let o = result.output
                    return .packageTargetStep(stepName: String(o.stepName), target: String(o.targetName))
                } else if let result = try /<target-(?<targetName>[^-]+)-PACKAGE-TARGET:(?<target>[^-]+)-SDKROOT:(?<platform>[^-]+):SDK_VARIANT:(?<arch>[^-]+)-(?<stepName>.+)>/.firstMatch(in: name) {
                    // e.g. <target-BuildAnalyzerKit-PACKAGE-TARGET:BuildAnalyzerKit-SDKROOT:macosx:SDK_VARIANT:macos-begin-compiling>
                    let o = result.output
                    return .packageTargetStep(stepName: String(o.stepName), target: String(o.targetName))
                } else if let result = try /<(?<stepName>[^-]+)[ \-](?<path>\/.+)>/.firstMatch(in: name) {
                    // e.g. <CodeSign /SomePath/Build/Products/Debug/BuildAnalyzer.app>
                    // e.g. <CreateBuildDirectory-/SomePath/DerivedData/BuildAnalyzer/Build/Products>>
                    let o = result.output
                    return .simpleStep(stepName: String(o.stepName), file: String(o.path))
                } else {
                    return .other(value: name)
                }
            } catch {
                // TODO: log unknown kind
                return .other(value: name)
            }
        }
    }
}

extension Array<String>: Comparable {
    public static func < (lhs: Array<Element>, rhs: Array<Element>) -> Bool {
        guard let l = lhs.first, let r = rhs.first else {
            return false
        }
        return l < r
    }
}
