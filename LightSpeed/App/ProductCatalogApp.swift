import SwiftUI

@main
struct ProductCatalogApp: App {
  init() {
    DI.Container.setup()
  }

  var body: some Scene {
    WindowGroup {
      ProductCatalogCoordinator().view(for: .productList)
    }
  }
}
