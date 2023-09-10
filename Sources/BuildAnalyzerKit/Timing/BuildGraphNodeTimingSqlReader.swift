//
//  File.swift
//
//
//  Created by Bartosz Polaczyk on 8/12/23.
//

import Foundation
import SQLite

public enum BuildGraphNodeTimingSqlReaderError: Error {
    case unexpectedRowFormat(Binding?)
}

public class BuildGraphNodeTimingSqlReader: BuildGraphNodeTimingReader {
    let file: URL

    public init(file: URL) {
        self.file = file
    }


    public func read() throws -> [BuildGraphNodeTimingId: BuildGraphNodeTiming] {

        var result: [BuildGraphNodeTimingId: BuildGraphNodeTiming] = [:]
        let db = try Connection(file.absoluteString, readonly: true)

        let iteration: Int64 = try read(try db.scalar("SELECT max(iteration) FROM info"))
        let buildStart = try readDate(try db.scalar("SELECT min(start) FROM rule_results where built_at = \(iteration)"))
        let buildEnd = try readDate(try db.scalar("SELECT max(end) FROM rule_results where built_at = \(iteration)"))
        let buildDuration = buildEnd - buildStart

        for row in try db.prepare("SELECT start, end, key_names.key, key_id from rule_results inner join key_names on rule_results.key_id = key_names.id where built_at = \(iteration)") {
            // first char in row[2] is a type (C,K etc). Example: "C<target-ManifestParser-bc75e606ed3b47368a6dc071f5ab1c32e9d992eb94ae6b73e7b9d19fb5bec30f-Debug-macosx-arm64-build-headers-stale-file-removal>
            let nodeId = try readNodeId(row[2])

            let start = try readDate(row[0])
            let end = try readDate(row[1])

            let node = nodeId
            let timing = BuildGraphNodeTiming(
                node: node,
                start: start,
                end: end,
                percentage: (start - buildStart)/(buildDuration)
            )
            result[node] = timing
        }
        return result
    }

    private func readDate(_ rowOptional: Binding?) throws -> Double {
        guard let row = rowOptional, let time = row as? Double  else {
            throw BuildGraphNodeTimingSqlReaderError.unexpectedRowFormat(rowOptional)
        }
        return time
    }

    private func readNodeId(_ rowOptional: Binding?) throws -> BuildGraphNodeTimingId {
        guard let row = rowOptional, let nodeId = row as? String  else {
            throw BuildGraphNodeTimingSqlReaderError.unexpectedRowFormat(rowOptional)
        }
        return BuildGraphNodeId(id: String(nodeId.dropFirst()))
    }

    private func read<T>(_ rowOptional: Binding?) throws -> T {
        guard let row = rowOptional, let value = row as? T  else {
            throw BuildGraphNodeTimingSqlReaderError.unexpectedRowFormat(rowOptional)
        }
        return value
    }
}
