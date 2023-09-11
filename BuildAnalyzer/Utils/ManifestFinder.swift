//
//  ManifestFinder2.swift
//  BuildAnalyzer
//
//  Created by Bartosz Polaczyk on 8/26/23.
//

import Foundation
import XcodeHasher

enum ManifestFinderError: Error {
    case projectDictNotFound
    case manifestNotFound
    case unknownPackageFormat(URL, Error?)
}

public struct ManifestFinderOptions {
    let project: URL
    let derivedData: URL?

    static func build(project: URL) -> Self {
        ManifestFinderOptions(project: project, derivedData: nil)
    }

    func guessProjectName() throws -> String  {
        switch project.lastPathComponent {
        case "Package.swift":
            // heuristic to find a name with
            /*

             let package = Package(
                name: "XCRemoteCache",
             ....
             */
            do {
                // assume the name is always at the top
                let content = try String(String(contentsOf: project, encoding: .utf8))
                guard let result = try /name\s*:\s*\"(?<name>\w+)\"/.firstMatch(in: content) else {
                    throw ManifestFinderError.unknownPackageFormat(project, nil)
                }
                return String(result.output.name)
            } catch {
                throw ManifestFinderError.unknownPackageFormat(project, error)
            }
        default:
            return project.deletingPathExtension().lastPathComponent
        }
    }
}

public struct ManifestLocation {
    let projectFile: URL?
    let manifest: URL
    let timingDatabase: URL?

    func withProjectFile(_ url: URL) -> Self {
        .init(projectFile: url, manifest: self.manifest, timingDatabase: self.timingDatabase)
    }
}

/// Helper methods to locate Xcode's DD directory and project's content
public struct ManifestFinder {
    let xcbuildDataDir = "/Build/Intermediates.noindex/XCBuildData/"

    var defaultDerivedData: URL {
        let homeDirURL = URL.homeDirectory
        return homeDirURL.appendingPathComponent("Library/Developer/Xcode/DerivedData", isDirectory: true)
    }

    public init() {}

    public func findLatestManifest(options: ManifestFinderOptions) throws -> ManifestLocation? {
       let file = options.project
        switch file.pathExtension {
        case "json":
            return .init(projectFile: nil, manifest: file, timingDatabase: nil)
        case "xcodeproj", "xcworkspace", "swift":
            // swift for Package.swift approach
            return try? findManifestFromProject(options: options)?.withProjectFile(options.project)
        default:
            return nil
        }

    }
    private func findManifestFromProject(options: ManifestFinderOptions) throws -> ManifestLocation? {
        // get project dir
        let projectDir = try getProjectDir(options)

        // manifests are in xcbuild dir
        let xcbuildDir = projectDir.appendingPathComponent(xcbuildDataDir)

        return try getLatestManifest(xcbuildDir)

    }


    private func getProjectDir(_ options: ManifestFinderOptions) throws -> URL {
        // get derivedDataDir
        guard let derivedDataDir = getDerivedDataDir(options) else {
            throw ManifestFinderError.projectDictNotFound
        }
        // get project dir
        return try getProjectDir(options: options, derivedData: derivedDataDir)
    }

    private func getDerivedDataDir(_ options: ManifestFinderOptions) -> URL? {
        if let explicitDerivedData = options.derivedData {
            return explicitDerivedData
        }

        let projectLocation = options.project.deletingLastPathComponent()
        if let customDerivedDataDir = getCustomDerivedDataDir(relativeTo: projectLocation) {
            return customDerivedDataDir
        }

        return defaultDerivedData
    }

    private func getProjectDir(options: ManifestFinderOptions,
                               derivedData: URL) throws -> URL {
        // when xcodebuild is run with -derivedDataPath or relative path the logs are at the root level
        let projectName = try options.guessProjectName()
        if FileManager.default.fileExists(atPath: derivedData.appendingPathComponent(projectName).path) {
            return derivedData.appendingPathComponent(projectName)
        }
        // look with project-hash directory
        let folderName = try getProjectFolderNameWithHash(options.project)
        let hashedProjectDir = derivedData.appendingPathComponent(folderName)
        if FileManager.default.fileExists(atPath: hashedProjectDir.path) {
            return hashedProjectDir
        }

        throw ManifestFinderError.projectDictNotFound
    }

    private func getCustomDerivedDataDir(relativeTo relative: URL) -> URL? {
        guard let xcodeOptions = UserDefaults.standard.persistentDomain(forName: "com.apple.dt.Xcode") else {
            return nil
        }
        guard let customLocation = xcodeOptions["IDECustomDerivedDataLocation"] as? String else {
            return nil
        }
        return URL(fileURLWithPath: customLocation, relativeTo: relative)
    }


    /// Returns the latest xcactivitylog file path in the given directory
    /// - parameter dir: The full path for the directory
    /// - returns: The path for the latest xcactivitylog file in it.
    /// - throws: An `Error` if the directory doesn't exist or if there are no xcactivitylog files in it.
    public func getLatestManifest(_ dir: URL) throws -> ManifestLocation {
        let fileManager = FileManager.default
        let files = try fileManager.contentsOfDirectory(at: dir,
                                                        includingPropertiesForKeys: [.contentModificationDateKey],
                                                        options: .skipsHiddenFiles)
        let sorted = try files.filter { $0.path.hasSuffix(".xcbuilddata") }.sorted {
            let lhv = try $0.resourceValues(forKeys: [.contentModificationDateKey])
            let rhv = try $1.resourceValues(forKeys: [.contentModificationDateKey])
            guard let lhDate = lhv.contentModificationDate, let rhDate = rhv.contentModificationDate else {
                return false
            }
            return lhDate.compare(rhDate) == .orderedDescending
        }
        guard let xcBuildData = sorted.first else {
            throw ManifestFinderError.manifestNotFound
        }
        // Find manifest.json

        let manifest = xcBuildData.appending(component: "manifest.json")
        // the "main" .db corresponds to the most recent manifest
        let timingDb = dir.appending(component: "build.db")
        return ManifestLocation(projectFile: nil, manifest: manifest, timingDatabase: timingDb)
    }

    public func getProjectFolderNameWithHash(_ project: URL) throws -> String {
        // require no / at the end
        let path = URL(fileURLWithPath: project.path, isDirectory: false)
        let projectName = path.deletingPathExtension().lastPathComponent
        let hash = try XcodeHasher.hashString(for: path.path)
        return "\(projectName)-\(hash)"
    }

}
