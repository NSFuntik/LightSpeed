//
//  ProductCatalogCoordinator.swift
//  LightSpeed
//
//  Created by Dmitry Mikhailov on 25.10.2024.
//

import SwiftUI

// MARK: - Coordinator

final class AppCoordinator: NavigationModalCoordinator {
  enum Screen: ScreenProtocol {
    case productList
    case productDetails(Product)
  }

  @ViewBuilder
  func destination(for screen: Screen) -> some View {
    switch screen {
    case .productList:
      ProductListView()
    case let .productDetails(product):
      ProductDetails(product)
    }
  }

  enum ModalFlow: ModalProtocol {
    case filter
    case sort

    var style: ModalStyle {
      switch self {
      case .filter, .sort:
        return .sheet
      }
    }
  }

  // TODO: Add filter and sort
  typealias FilterView = EmptyView
  typealias SortView = EmptyView
  @ViewBuilder
  func destination(for flow: ModalFlow) -> some View {
    switch flow {
    case .filter:
      FilterView()
    case .sort:
      SortView()
    }
  }
}
