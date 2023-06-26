//
//  GraphViewModel.swift
//  BuildAnalyzer
//
//  Created by Bartosz Polaczyk on 6/19/23.
//

import Foundation
import BuildAnalyzerKit

class GraphViewModel: ObservableObject {
  @Published var graph: BuildGraph

  init(
    graph: BuildGraph
  ) {
      self.graph = graph
    self.bind()  // 👈
  }

  // Override delegate closures in all child models.
  private func bind() {

  }
}
