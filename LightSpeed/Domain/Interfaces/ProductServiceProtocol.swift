//
//  ProductServiceProtocol.swift
//  LightSpeed
//
//  Created by Dmitry Mikhailov on 25.10.2024.
//

import Foundation
@_exported import protocol Combine.ObservableObject

// MARK: - ProductService Protocol

protocol ProductServiceProtocol: ObservableObject {
  var products: [Product] { get }
  var isLoading: Bool { get }
  var error: NetworkError? { get }

  func loadNextPage() async
  func refresh() async
}
