//
//  File.swift
//  
//
//  Created by Bartosz Polaczyk on 9/4/23.
//

import Foundation
import XCTest
import BuildAnalyzerKit

final class BuildGraphNodeKindTests: XCTestCase {
    func testRecognizesFiles() throws {

        let node = "/SomePath/Preview Content/"
        XCTAssertEqual(BuildGraphNode.Kind.generateKind(name: node), .file(path: node))
    }

    func testRecognizesSimpleStep() throws {
        let node = "<CodeSign /Users/bartosz/Development/BuildAnalyzer/DerivedData/BuildAnalyzer/Build/Products/Debug/BuildAnalyzer.app>"
        XCTAssertEqual(BuildGraphNode.Kind.generateKind(name: node), .simpleStep(stepName: "CodeSign", file: "/Users/bartosz/Development/BuildAnalyzer/DerivedData/BuildAnalyzer/Build/Products/Debug/BuildAnalyzer.app"))
    }

    func testRecognizesSimpleStepWithMultiWordStep() throws {
        let node = "<Linked Binary /Some/Path/Build/Products/Debug/BuildAnalyzer.app/Contents/MacOS/BuildAnalyzer>"
        XCTAssertEqual(BuildGraphNode.Kind.generateKind(name: node), .simpleStep(stepName: "Linked Binary", file: "/Some/Path/Build/Products/Debug/BuildAnalyzer.app/Contents/MacOS/BuildAnalyzer"))
    }

    func testRecognizesSimpleStepWithDash() throws {
        let node = "<CreateBuildDirectory-/SomePath/DerivedData/BuildAnalyzer/Build/Products>"
        XCTAssertEqual(BuildGraphNode.Kind.generateKind(name: node), .simpleStep(stepName: "CreateBuildDirectory", file: "/SomePath/DerivedData/BuildAnalyzer/Build/Products"))
    }

    func testTriggerStep() throws {
        let node = "<TRIGGER: CodeSign /SomePath/DerivedData/BuildAnalyzer/Build/Products/Debug/BuildAnalyzer.app>"
        XCTAssertEqual(BuildGraphNode.Kind.generateKind(name: node), .triggerStep(stepName: "CodeSign", args: ["/SomePath/DerivedData/BuildAnalyzer/Build/Products/Debug/BuildAnalyzer.app"]))
    }

    func testTriggerStepWithMulitpleArgs() throws {
        let node = "<TRIGGER: Ld /SomePath/DerivedData/BuildAnalyzer/Build/Products/Debug/BuildAnalyzer.app/Contents/MacOS/BuildAnalyzer normal>"
        XCTAssertEqual(BuildGraphNode.Kind.generateKind(name: node), .triggerStep(stepName: "Ld", args: ["/SomePath/DerivedData/BuildAnalyzer/Build/Products/Debug/BuildAnalyzer.app/Contents/MacOS/BuildAnalyzer", "normal"]))
    }

    func testEnd() throws {
        let node = "<all>"
        XCTAssertEqual(BuildGraphNode.Kind.generateKind(name: node), .end)
    }

    func testComplexStep() throws {
        let node = "<target-BuildAnalyzer-be0c796e7ab161295c9e11c90ddae75a2b86e3aa1cc2f374c8ee86a36d7adc00--TAPISymbolExtractorTaskProducer>"
        XCTAssertEqual(BuildGraphNode.Kind.generateKind(name: node), .complexStep(stepName: "TAPISymbolExtractorTaskProducer", target: "BuildAnalyzer"))
    }

    func testPackageProductStep() throws {
        let node = "<target-BuildAnalyzerKit-PACKAGE-PRODUCT:BuildAnalyzerKit-Debug-macosx-arm64-build-headers-stale-file-removal>"
        XCTAssertEqual(BuildGraphNode.Kind.generateKind(name: node), .packageProductStep(stepName: "build-headers-stale-file-removal", target: "BuildAnalyzerKit"))
    }

    func testPackageProductStepWithSdkRoot() throws {
        let node = "<target-BuildAnalyzerKit-PACKAGE-PRODUCT:BuildAnalyzerKit-SDKROOT:macosx:SDK_VARIANT:macos-begin-compiling>"
        XCTAssertEqual(BuildGraphNode.Kind.generateKind(name: node), .packageProductStep(stepName: "begin-compiling", target: "BuildAnalyzerKit"))
    }

    func testPackageTargetStep() throws {
        let node = "<target-BuildAnalyzerKit-PACKAGE-TARGET:BuildAnalyzerKit-Debug-macosx-arm64-build-headers-stale-file-removal>"
        XCTAssertEqual(BuildGraphNode.Kind.generateKind(name: node), .packageTargetStep(stepName: "build-headers-stale-file-removal", target: "BuildAnalyzerKit"))
    }

    func testPackageTargetStepWithSdkRoot() throws {
        let node = "<target-BuildAnalyzerKit-PACKAGE-TARGET:BuildAnalyzerKit-SDKROOT:macosx:SDK_VARIANT:macos-begin-compiling>"
        XCTAssertEqual(BuildGraphNode.Kind.generateKind(name: node), .packageTargetStep(stepName: "begin-compiling", target: "BuildAnalyzerKit"))
    }

    func testGate() throws {
        let node = "P0:::Gate target-XcodeHasher-PACKAGE-TARGET:XcodeHasher-SDKROOT:macosx:SDK_VARIANT:macos-SwiftPackageCopyFilesTaskProducer"
        XCTAssertEqual(BuildGraphNode.Kind.generateKind(name: node), .gate(index: 0, kind: .packageTargetStep(stepName: "SwiftPackageCopyFilesTaskProducer", target: "XcodeHasher")))
    }


    func testGateWithConfiguration() throws {
        let node = "P0:target-BuildAnalyzer-be0c796e7ab161295c9e11c90ddae75a2b86e3aa1cc2f374c8ee86a36d7adc00-:Debug:Gate target-BuildAnalyzer-be0c796e7ab161295c9e11c90ddae75a2b86e3aa1cc2f374c8ee86a36d7adc00--entry"
        XCTAssertEqual(BuildGraphNode.Kind.generateKind(name: node), .gate(index: 0, kind: .complexStep(stepName: "entry", target: "BuildAnalyzer")))
    }

    func testArtificial() throws {
        let node = "P0:::CreateBuildDirectory /Some/DerivedData/BuildAnalyzer/Build/Intermediates.noindex"
        XCTAssertEqual(BuildGraphNode.Kind.generateKind(name: node), .artificial(stepName: "CreateBuildDirectory", args: ["/Some/DerivedData/BuildAnalyzer/Build/Intermediates.noindex"]))
    }

    func testArtificialWithMultipleArgs() throws {
        let node = "P0:::ClangStatCache /App/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang-stat-cache /someFile"
        XCTAssertEqual(BuildGraphNode.Kind.generateKind(name: node), .artificial(stepName: "ClangStatCache", args: ["/App/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang-stat-cache", "/someFile"]))
    }

    func testArtificialWithConfiguration() throws {
        let node = "P0:target-BuildAnalyzer-be0c796e7ab161295c9e11c90ddae75a2b86e3aa1cc2f374c8ee86a36d7adc00-:Debug:CpResource /Some/DerivedData/BuildAnalyzer/Build/Intermediates.noindex"
        XCTAssertEqual(BuildGraphNode.Kind.generateKind(name: node), .artificial(stepName: "CpResource", args: ["/Some/DerivedData/BuildAnalyzer/Build/Intermediates.noindex"]))
    }

    func testArtificialWithMultipleNonFileArgs() {
        let node = "P2:target-XcodeHasher-PACKAGE-TARGET:XcodeHasher-SDKROOT:macosx:SDK_VARIANT:macos:Debug:SwiftDriver Compilation Requirements XcodeHasher normal arm64 com.apple.xcode.tools.swift.compiler"
        XCTAssertEqual(BuildGraphNode.Kind.generateKind(name: node), .artificial(stepName: "SwiftDriver", args: ["Compilation","Requirements","XcodeHasher","normal","arm64","com.apple.xcode.tools.swift.compiler"]))

    }

    func testComplexStepWithConfigurationIsOther() {
        let node = "<target-BuildAnalyzer-be0c796e7ab161295c9e11c90ddae75a2b86e3aa1cc2f374c8ee86a36d7adc00-Debug-macosx-arm64-build-headers-stale-file-removal>"
        XCTAssertEqual(BuildGraphNode.Kind.generateKind(name: node), .other(value: "<target-BuildAnalyzer-be0c796e7ab161295c9e11c90ddae75a2b86e3aa1cc2f374c8ee86a36d7adc00-Debug-macosx-arm64-build-headers-stale-file-removal>"))

    }

    func testArtificialWithMultipleNoFileArgs() {
        let node = "P0:target-BuildAnalyzer-be0c796e7ab161295c9e11c90ddae75a2b86e3aa1cc2f374c8ee86a36d7adc00-:Debug:ExtractAppIntentsMetadata"
        XCTAssertEqual(BuildGraphNode.Kind.generateKind(name: node), .artificial(stepName: "ExtractAppIntentsMetadata", args: []))

    }
}
