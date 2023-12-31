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

// The custom WKWebView to capture .xcodeproj Drag&Drop to the WebView
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
    private(set) var created: Bool = false
    private var currentProjection: BuildGraphProjection
    private var projector: D3BuildGraphProjector
    @Binding var selection: Set<String>
    @Binding var focus: String?
    private var layout: GraphLayoutStyle = .standard
    @Binding var appAlternatives: AppAlternatives

    init(graph: Binding<BuildGraph>, graphUrl: Binding<URL?>, selection: Binding<Set<String>>, focus: Binding<String?>, appAlternatives: Binding<AppAlternatives>) {
        self._graph = graph
        self._selection = selection
        self._appAlternatives = appAlternatives
        let userContentController = WKUserContentController()
        let coordinator = GraphWebViewCoordinator()
        userContentController.add(coordinator, name: "bridge")

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userContentController

        let _wkwebview = MyWK(graphUrl: graphUrl, configuration: configuration)
        _wkwebview.navigationDelegate = coordinator
#if DEBUG
        if #available(macOS 13.3, *) {
            _wkwebview.isInspectable = true
        }
#endif
        self.webView = _wkwebview
        self.coordinator = coordinator

        let currentProjection = BuildGraphProjectionImpl.init(nodes: [], type: .flow, highlightedEdges: [])
        projector = D3BuildGraphProjector(projection: currentProjection)
        self.currentProjection = currentProjection
        self._focus = focus
        coordinator.onChange = { [weak self] action in
            self?.onUiAction(action: action)
        }
    }


    func reset() {
        currentProjection = BuildGraphProjectionImpl(nodes: [], type: .circular, highlightedEdges: []
        )
        refreshProjection(fresh: true)
    }

    func resetZoom() {
        sendMessage(true, nil, extra: getLayoutExtra())
    }

    func setLayout(_ layout: GraphLayoutStyle) {
        self.layout = layout
        sendMessage(true,  projector.build(), extra: getLayoutExtra())
    }

    func select(nodes: Set<String>, focus: String?) {
        guard !nodes.isEmpty  else {
            // TOOD: consider reset view, but now leave it as is as the user might just unselect by mistake
            return
        }
        let bgNodeIds = nodes.map(BuildGraphNodeId.init(id:))
        let highlightedNodeIds = focus.map(BuildGraphNodeId.init(id:))
        let filteredNodes = bgNodeIds.filter { nodeId in
            graph.nodes[nodeId] != nil
        }
        guard !filteredNodes.isEmpty else {
            // do nothing as left node in a graph means the selected node is a group (e.g. files)
            return
        }

        let newProjection = BuildGraphProjectionImpl(startingNodes: Set(filteredNodes), highlightedNodes: [highlightedNodeIds].compactMap({$0}))
        if filteredNodes.count > 1 {
            currentProjection = graph.expand(projection: newProjection, with: .path(nodes: Set(filteredNodes) ))
        } else {
            let bgNodeId = filteredNodes[0]
            // do not show all inputs/outputs if a cycle has been detected to not make too many lines that might make it less readable
            if graph.cycleNodes.contains(bgNodeId), let cycle = graph.cycles.first(where: {$0.contains(bgNodeId)}) {
                currentProjection = graph.expand(projection: newProjection, with: .cycle(of: bgNodeId, cycle: cycle ))
                currentProjection.highlightedEdges = Set(zip(cycle, cycle.dropFirst()).map { source, dest in
                    BuildGraphEdge(source: source, destination: dest)
                })
                // the cycle includes duplicated node
                currentProjection.type = .circular
            } else {
                currentProjection = graph.expand(projection: newProjection, with: .inputs(of: bgNodeId))
                currentProjection = graph.expand(projection: currentProjection, with: .outputs(of: bgNodeId))
            }
        }
        refreshProjection(fresh: false)
        resetZoom()
    }

    func highlight(nodeId: String?) {
        let bgNodeId = nodeId.map(BuildGraphNodeId.init(id:))

        // e.g. N5
        if let nodeId = nodeId {
            // only select the node in d3  - not regenerate the entire render
            sendRequest(D3PageRequest(option: .noop, highlight: nodeId))
            return
        }
        currentProjection = graph.highlight(nodeId: bgNodeId, projection: currentProjection)
        refreshProjection(fresh: false)
    }

    func onUiAction(action: GraphViewRequestAction) {
        switch action {
        case .extendIn(id: let d3Node):
            guard let bgNodeId = projector.d3GraphNodesMapping[d3Node.id] else {
                print("unknown d3 node. Probably the starting phase")
                return
            }
            currentProjection = graph.expand(projection: currentProjection, with: .inputs(of: bgNodeId, count: appAlternatives.command ? 100 : 3))
            refreshProjection(fresh: false)
        case .extendOut(id: let d3Node):
            guard let bgNodeId = projector.d3GraphNodesMapping[d3Node.id] else {
                print("unknown d3 node. Probably the starting phase")
                return
            }
            currentProjection = graph.expand(projection: currentProjection, with: .outputs(of: bgNodeId, count: appAlternatives.command ? 100 : 3))
            refreshProjection(fresh: false)
        case .set(let id):
            guard let nodeId = projector.d3GraphNodesMapping[id.id] else {
                print("unknown d3 node. Probably the starting phase")
                return
            }
            focus = nodeId.id
            highlight(nodeId: nodeId.id)
            currentProjection.highlightedNodes = Set([.init(id: nodeId.id)])
            break
        }
    }

    fileprivate func sendMessage(_ fresh: Bool, _ d3String: String?, extra: String) {
        let request = D3PageRequest(option: .init(reset: fresh), graph: d3String, extra: extra)
        sendRequest(request)
    }

    fileprivate func sendRequest(_ request: D3PageRequest) {
        do {
            let requestString = try coordinator.generateMessage(request).replacingOccurrences(of: "\"", with: "\\\"")
            webView.evaluateJavaScript("webkit.messageHandlers.bridge.onMessage = fromNative")
            webView.evaluateJavaScript("webkit.messageHandlers.bridge.onMessage('\(requestString)')")
        } catch {
            print("Error in sending from Swift \(error)")
        }
    }

    /// Rebuilds the projector and sends an event to JS
    /// - Parameter fresh: if true, a completely new view is generated and previous labels don't have to be reused
    private func refreshProjection(fresh: Bool) {
        // Experiment - reuse the same "Mapping" to reuse similar nodes and limit number of animations when new node IDs (dot-specific)
        // are assigned
        let startingMapping: [BuildGraphNodeId: D3BuildGraphNodeId] = projector.buildGraphNodesMapping
        projector = D3BuildGraphProjector(projection: currentProjection, buildGraphNodesMapping: startingMapping)
        let d3String = projector.build()
        sendMessage(fresh, d3String, extra: getLayoutExtra())
    }

    private func getLayoutExtra() -> String {
        layout == .circo ?  "layout=circo;" : ""
    }
}

class GraphWebViewCoordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    private var selection: Binding<Set<String>>?
    var onChange: ((GraphViewRequestAction) -> ())?
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()


    func setBinding(_ selection: Binding<Set<String>>) {
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
    }

    func generateMessage(_ message: D3PageRequest) throws -> String {
        return try String(data: encoder.encode(message), encoding: .utf8)!
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // finally ready to present without blinking black/white/background color
        webView.isHidden = false
    }
}


struct GraphWebView: NSViewRepresentable {
    let controller: GraphWebViewController

    init(graph: Binding<BuildGraph>, graphUrl: Binding<URL?>, selection: Binding<Set<String>>, focus: Binding<String?>, alternatives: Binding<AppAlternatives>) {
        let controller = GraphWebViewController(graph: graph, graphUrl: graphUrl, selection: selection, focus: focus, appAlternatives: alternatives)

        self.controller = controller
    }

    func makeNSView(context: Context) -> WKWebView {
        return controller.webView
    }


    func updateNSView(_ webView: WKWebView, context: Context) {
        // do not show initially to not "blink"
        webView.isHidden = true
        guard let path: String = Bundle.main.path(forResource: "index", ofType: "html") else { return }
        let localHTMLUrl = URL(fileURLWithPath: path, isDirectory: false)
        let resources = localHTMLUrl.deletingLastPathComponent()
        webView.loadFileURL(localHTMLUrl, allowingReadAccessTo: resources)
    }
}


class D3GraphMessageFactory {
    func generate(projection: BuildGraphProjection) -> String {
        return ""
    }
}

extension BuildGraphProjectionLayoutType {
    // the extra modifier that should be added to the digraph to generate a given projection
    var modifier: String {
        switch self {
        case .circular: "" // Circo layout is not great in finding a cycle "layout=circo;"
        case .flow: "" // it is a default
        }
    }
}
