//
//  ManifestLoader.swift
//  BuildAnalyzer
//
//  Created by Bartosz Polaczyk on 8/25/23.
//

import Foundation
import XcodeHasher

class ManifestLoader {
    var defaultDerivedData: URL? {
       let homeDirURL = URL.homeDirectory
        return homeDirURL.appendingPathComponent("Library/Developer/Xcode/DerivedData", isDirectory: true)
    }

    var derivedData: URL? {
        // TODO: implement custom
        defaultDerivedData
    }

    func findManifest(_ file: URL?) -> URL? {
        guard let file = file else { return nil }
        switch file.pathExtension {
        case "json":
            return file
        case "xcodeproj", "xcworkspace":
            let manifests = try? findManifests(file)
            return manifests?.first
        default:
            return nil
        }
    }

    private func findProjectDerivedData(_ xcodeprojUrl: URL) throws -> URL? {
        var path = xcodeprojUrl.path
        if !xcodeprojUrl.isFileURL {
            // remote last "/"
            path = String(path.dropLast())
        }

        let projectName = xcodeprojUrl.lastPathComponent
            .replacingOccurrences(of: ".xcworkspace", with: "")
            .replacingOccurrences(of: ".xcodeproj", with: "")
        let hash = try XcodeHasher.hashString(for: path)
        return derivedData?.appendingPathComponent("\(projectName)-\(hash)")
    }

    private func findManifests(_ xcodeprojUrl: URL) throws -> [URL] {
        guard let dd = try findProjectDerivedData(xcodeprojUrl) else {
            return []
        }
        let xcbuildDataDir = dd.appending(components: "Build", "Intermediates.noindex","XCBuildData/")

        // TODO sort by date
        return listManifests(xcbuildDataDir)
    }

    // TODO: Optimize
    private func listManifests(_ xcbuildDir: URL) -> [URL] {
        var sum: [URL] = []
        if let enumerator = FileManager.default.enumerator(atPath: xcbuildDir.path) {
            for case let path as String in enumerator {
                if path.hasSuffix("manifest.json") && !path.contains("buildDebugging") {
                    sum.append(URL(filePath: path, relativeTo: xcbuildDir))
                }
            }
        }
        return sum
    }
}
