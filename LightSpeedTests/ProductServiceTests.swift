//
//  ProductServiceTests.swift
//  LightSpeed
//
//  Created by Dmitry Mikhailov on 25.10.2024.
//

import XCTest
@testable import ProductCatalogApp

final class ProductServiceTests: XCTestCase {
  var productService: ProductService!

  override func setUp() {
    super.setUp()
    productService = ProductService()
  }

  override func tearDown() {
    productService = nil
    super.tearDown()
  }

  func testFetchProductsSuccess() async throws {
    let products = try await productService.fetchProducts(page: 1, limit: 20)
    XCTAssertFalse(products.isEmpty, "Products should not be empty")
  }

  func testFetchProductsCancellation() async throws {
    let expectation = XCTestExpectation(description: "Cancellation")
    productService.cancelFetch()
    do {
      _ = try await productService.fetchProducts(page: 1, limit: 20)
      XCTFail("Fetch should have been cancelled")
    } catch {
      XCTAssertEqual((error as? URLError)?.code, .cancelled, "Error should be cancellation")
      expectation.fulfill()
    }
    await waitForExpectations(timeout: 5)
  }
}
