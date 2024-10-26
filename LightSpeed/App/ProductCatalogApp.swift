import SwiftUI

@main
struct ProductCatalogApp: App {
  init() {
    DI.Container.setup()
  }

  var body: some Scene {
    WindowGroup {
      AppCoordinator().view(for: .productList)
    }
  }
}
