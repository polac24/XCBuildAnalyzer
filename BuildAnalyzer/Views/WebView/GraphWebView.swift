//
//  GraphWebView.swift
//  BuildAnalyzer
//
//  Created by Bartosz Polaczyk on 6/19/23.
//

import Foundation
import SwiftUI
import WebKit
import BuildAnalyzerKit


enum GraphViewRequestAction {
    case extendIn(id: BuildGraphNodeId)
    case extendOut(id: BuildGraphNodeId)
    case set(id: BuildGraphNodeId)
}

class MyWK: WKWebView {
    @Binding var graphUrl: URL?

    init(graphUrl: Binding<URL?>, configuration: WKWebViewConfiguration) {
        self._graphUrl = graphUrl
        super.init(frame: .zero, configuration: configuration)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let object = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: nil), object.count > 0 else {
            return false
        }
        let objects = object as! [URL]
        print(objects)
        // Take only the first one
        graphUrl = objects[0]
        return true
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .copy
    }
}

class GraphWebViewController {
    let coordinator: GraphWebViewCoordinator
    var webView: WKWebView
    @Binding private var graph: BuildGraph
//    private let messageFactory = D3GraphMessageFactory()
    private(set) var created: Bool = false
    private var currentProjection: BuildGraphProjection
    private var projector: D3BuildGraphProjector
    @Binding var selection: String?

    init(graph: Binding<BuildGraph>, graphUrl: Binding<URL?>, selection: Binding<String?>) {
        self._graph = graph
        self._selection = selection
        let userContentController = WKUserContentController()
        let coordinator = GraphWebViewCoordinator()
        userContentController.add(coordinator, name: "bridge")

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userContentController

        let _wkwebview = MyWK(graphUrl: graphUrl, configuration: configuration)
        _wkwebview.isInspectable = true
        self.webView = _wkwebview
        self.coordinator = coordinator

        let currentProjection = BuildGraphProjectionImpl.init(nodes: [], type: .flow)
        projector = D3BuildGraphProjector(projection: currentProjection)
        self.currentProjection = currentProjection
        coordinator.onChange = { [weak self] action in
            self?.onUiAction(action: action)
        }
    }


    func reset() {
        currentProjection = BuildGraphProjectionImpl(nodes: [], type: .flow)
        refreshProjection(fresh: true)
    }

    func select(nodeId: String?) {
        guard let nodeId = nodeId else {
            // TOOD: consider reset view, but now leave it as is as the user might just unselect by mistake
            return
        }
        let bgNodeId = BuildGraphNodeId(id: nodeId)
        guard let node = graph.nodes[bgNodeId] else {
            // do nothing as left node in a graph means the selected node is a group (e.g. files)
            return
        }

        let newProjection = BuildGraphProjectionImpl(startingNode: bgNodeId)
        currentProjection = graph.expand(projection: newProjection, with: .inputs(of: bgNodeId ))
        currentProjection = graph.expand(projection: currentProjection, with: .outputs(of: bgNodeId ))
        refreshProjection(fresh: false)
    }

    func onUiAction(action: GraphViewRequestAction) {
        switch action {
        case .extendIn(id: let d3Node):
            guard let bgNodeId = projector.d3GraphNodesMapping[d3Node.id] else {
                print("unknown d3 node. Probably the starting phase")
                return
            }
            currentProjection = graph.expand(projection: currentProjection, with: .inputs(of: bgNodeId ))
            refreshProjection(fresh: false)
        case .extendOut(id: let d3Node):
            guard let bgNodeId = projector.d3GraphNodesMapping[d3Node.id] else {
                print("unknown d3 node. Probably the starting phase")
                return
            }
            currentProjection = graph.expand(projection: currentProjection, with: .outputs(of: bgNodeId ))
            refreshProjection(fresh: false)
        case .set(let id):
            guard let nodeId = projector.d3GraphNodesMapping[id.id] else {
                print("unknown d3 node. Probably the starting phase")
                return
            }
            selection = nodeId.id
            break
        }
    }

    /// Rebuilds the projector and sends an event to JS
    /// - Parameter fresh: if true, a completely new view is generated and previous labels don't have to be reused
    private func refreshProjection(fresh: Bool) {
        // Experiment - reuse the same "Mapping" to reuse similar nodes and limit number of animations when new node IDs (dot-specific)
        // are assigned
        let startingMapping: [BuildGraphNodeId: D3BuildGraphNodeId] = fresh ? [:] : projector.buildGraphNodesMapping
        projector = D3BuildGraphProjector(projection: currentProjection, buildGrapNodesMapping: startingMapping)
        let d3String = projector.build()
        do {
            let request = D3PageRequest(option: .init(reset: fresh), graph: d3String)
            let requestString = try coordinator.generateMessage(request).replacingOccurrences(of: "\"", with: "\\\"")//.replacingOccurrences(of: "\\\\\"", with: "\\\"")
            webView.evaluateJavaScript("webkit.messageHandlers.bridge.onMessage('\(requestString)')")
        } catch {
            print("Error in sending from Swift \(error)")
        }
    }
}

class GraphWebViewCoordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
//    @Binding var action: GraphViewRequestAction?
//    private var graph: BuildGraph
    private var selection: Binding<String?>?
    var onChange: ((GraphViewRequestAction) -> ())?
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

//    init(graph: BuildGraph) {
//        self._action = action
//        self.graph = graph
//        self.onChange = onChange
//        self._selection = Binding(get: {
//            selection.wrappedValue
//        }, set: { nodeId in
//            print(nodeId)
//        })
//    }

    func setBinding(_ selection: Binding<String?>) {
        self.selection = Binding(get: {
            selection.wrappedValue
        }, set: { s in
            selection.wrappedValue = s
        })
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {

        guard let body = message.body as? String else {
            print("Not a string")
            return
        }

        let response = try! decoder.decode(D3PageResponse.self, from: body.data(using: .utf8)!)

        // TODO: set action
        let action: GraphViewRequestAction
        let id: BuildGraphNodeId = .init(id: response.id)
        switch response.msg {
        case .selected:
            action = .set(id: id)
        case .expandIn:
            action = .extendIn(id: id)
        case .expandOut:
            action = .extendOut(id: id)
        }
        onChange?(action)
//        selection. = response.id
//        selection?.wrappedValue = "222"
        // find the graphNodeId from the D3's context
//        guard let nodeId = projector.d3GraphNodesMapping[response.id] else {
//            print("Missing nodeId")
//            return
//        }
//        currentProjection = graph.expand(projection: currentProjection, with: .inputs(of: nodeId))
//        projector = D3BuildGraphProjector(projection: currentProjection)
//        print(projector.build())
//        print(action)

//        let filteredManifest = processor?.analyzer?.filterManifest(node: response.id)
//        let formattedManifest = processor!.formatter.generate(filteredManifest!, focus: response.id)
//        self.webView?.evaluateJavaScript("webkit.messageHandlers.bridge.onMessage('\(formattedManifest.0)')")
    }

    func generateMessage(_ message: D3PageRequest) throws -> String {
        var safeMessage = message
        // the escape will be decoded when sending to JS. Extra
//        let safeD3 = message.graph.replacingOccurrences(of: "\"", with: "\"")
//        safeMessage.graph = safeD3
        return try String(data: encoder.encode(safeMessage), encoding: .utf8)!
    }

}


struct GraphWebView: NSViewRepresentable {
    let controller: GraphWebViewController
//    @Binding var projection: BuildGraphProjection
//    @Binding var action: GraphViewRequestAction?
//    @Binding var selection: String?

    init(graph: Binding<BuildGraph>, graphUrl: Binding<URL?>, selection: Binding<String?>) {
        let controller = GraphWebViewController(graph: graph, graphUrl: graphUrl, selection: selection)

        self.controller = controller
//        self._selection = selection
//        self._selection = Binding(get: {
//            selection.wrappedValue
//        }, set: { nodeId in
//            controller.select(nodeId: nodeId)
//        })
//        self._projection = Binding(get: {
//            projection.wrappedValue
//        }, set: { [controller] newValue in
//            controller.refresh(projection: newValue)
//            projection.wrappedValue = newValue
//        })
//        self._action = action
    }

    func makeNSView(context: Context) -> WKWebView {
        return controller.webView
    }


    func updateNSView(_ webView: WKWebView, context: Context) {
        guard let path: String = Bundle.main.path(forResource: "index", ofType: "html") else { return }
        let localHTMLUrl = URL(fileURLWithPath: path, isDirectory: false)
//        let html = try! String(contentsOf: localHTMLUrl)
        let resources = localHTMLUrl.deletingLastPathComponent()
        webView.loadFileURL(localHTMLUrl, allowingReadAccessTo: resources)
    }

//    func makeNSView(context: Context) -> NSView {
//        let v = NSView(frame: .init(x: 0, y: 0, width: 100, height: 100))
//        v.layer?.backgroundColor = .init(red: 1, green: 0, blue: 0, alpha: 0)
//        return v
//    }
//    func updateNSView(_ nsView: NSView, context: Context) {
//
//    }
}


class D3GraphMessageFactory {
    func generate(projection: BuildGraphProjection) -> String {
        print(projection.nodes)
        return ""
    }
}
