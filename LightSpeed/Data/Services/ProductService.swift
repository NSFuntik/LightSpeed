//
//  ProductService.swift
//  LightSpeed
//
//  Created by Dmitry Mikhailov on 25.10.2024.
//

import os.log
import Foundation

private let logger = Logger(subsystem: "com.LightSpeed.ProductsCatalog", category: "ProductService")

// MARK: - SortBy

enum SortBy: String, CaseIterable {
  case price
  case name
  case rating
}

// MARK: - ProductService

class ProductService: ProductServiceProtocol {
  @DI.Static(DI.networkService) private var networkService

  @Published private(set) var products: [Product] = []
  @Published private(set) var isLoading = false
  @Published var error: NetworkError?

  private let pageSize = 20
  private var currentPage = 0
  private(set) var canLoadMore = true

  @Sendable func loadNextPage() async {
    guard !isLoading && canLoadMore else { return }

    await MainActor.run { isLoading = true }

    do {
      let skip = skip(currentPage)

      let pageData: Data = try await networkService.fetch(
        .products(
          limit: pageSize,
          skip: skip)
      )

      guard let page = ProductParser.safeParse(jsonData: pageData)
      else { throw ModelParserError.invalidFormat("Failed to parse products page data") }

      logger.info("Successfully parsed \(page.products.count) products")

      await MainActor.run {
        products.append(contentsOf: page.products)
        currentPage += 1
        canLoadMore = skip + pageSize < page.total
        error = nil
      }
    } catch let networkError as NetworkError {
      await MainActor.run { error = networkError }
    } catch {
      await MainActor.run { self.error = .unknown(error) }
    }

    await MainActor.run { isLoading = false }
  }

  /// Calculates the `skip` for pagination
  private func skip(_ page: Int) -> Int {
    return page * pageSize
  }

  @Sendable
  func refresh() async {
    products = []
    currentPage = 0
    canLoadMore = true
    await loadNextPage()
  }

  func sort(by: SortBy) {
    products.sort(by: {
      switch by {
      case .name: $0.title < $1.title
      case .price: $0.price < $1.price
      case .rating: $0.rating < $1.rating
      }
    })
  }
}
