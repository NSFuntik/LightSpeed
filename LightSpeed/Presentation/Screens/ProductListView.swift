//
//  ProductListView.swift
//  LightSpeed
//
//  Created by Dmitry Mikhailov on 25.10.2024.
//

import SwiftUI

// MARK: - ProductListView

struct ProductListView: View {
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  @StateObject private var state = State()
  @EnvironmentObject private var navigation: Navigation<AppCoordinator>

  private var themeColors: ThemeConfiguration.Colors {
    colorScheme == .dark ? ThemeConfiguration.dark : ThemeConfiguration.light
  }

  @MainActor private final class State: ProductService {}

  var body: some View {
    List {
      switch state.products.isEmpty {
      case true:
        placeholder.shimmering(active: true)
      case false:
        content
      }
      progress
    }
    .listStyle(.insetGrouped)
    .environment(\.colorScheme, colorScheme)
    .environment(\.dynamicTypeSize, dynamicTypeSize)
    .refreshable(action: state.refresh)
    .navigationTitle("Products")
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        HStack {
          Button {
            navigation().alert("Error Alert") {
              Text("This is an alert")
            } actions: {
              Button("Cancel", role: .cancel) {}
              Button("Refresh", role: .destructive) {
                Task(priority: .userInitiated, operation: state.refresh)
              }
            }

          } label: {
            Image(systemName: "exclamationmark.bubble")
              .symbolRenderingMode(.palette)
          }
          .foregroundStyle(.red, .yellow)
          Menu("Sort", systemImage: "arrow.up.arrow.down.circle") {
            Button("Name", action: { state.sort(by: .name) })
            Button("Rating", action: { state.sort(by: .rating) })
            Button("Price", action: { state.sort(by: .price) })
          }.foregroundStyle(.blue, .tertiary)
        }
      }
    }
    .task(state.loadNextPage)
    .alert(item: $state.error) { error in
      Alert(
        title: Text("Something went wrong"),
        message: Text(error.errorDescription),
        dismissButton: .cancel(
          Text("Refresh"), action: { Task(priority: .userInitiated, operation: state.refresh) }))
    }
    .animation(.spring, value: state.products)
  }

  private var content: some View {
    ForEach(groupedProducts, id: \.key) { category in
      Section(header: Text(category.key ?? " ").font(.headline)) {
        ForEach(category.value, id: \.id) { product in
          Button(action: { navigation().present(.productDetails(product)) }) {
            ProductCell(product: product)
          }
        }
      }
    }
  }

  private var placeholder: some View {
    ForEach(1 ... 10, id: \.self) { _ in
      ProductCell(product: Product.placeholder)
        .redacted(reason: .placeholder)
    }
  }

  @ViewBuilder
  private var progress: some View {
    // Loading indicator at the bottom
    if state.canLoadMore && !state.products.isEmpty {
      HStack {
        Spacer()
        ProgressView()
          .controlSize(.large)
          .progressViewStyle(.circular)
        Spacer()
      }
      .padding(16)
      .onAppear(perform: { Task(priority: .userInitiated, operation: state.loadNextPage) })
    }
  }

  /// handle products grouping
  private var groupedProducts: [(key: String?, value: [Product])] {
    let grouped = Dictionary(grouping: state.products) { product in
      product.category.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    return grouped.sorted { ($0.key) < ($1.key) }
  }

  @ViewBuilder
  private func errorView(_ error: NetworkError) -> some View {
    ContentUnavailableView(label: {
      Image(systemName: "exclamationmark.triangle")
        .font(.largeTitle)
        .foregroundStyle(themeColors.error)

      Text("Something went wrong.")
        .font(.title2.bold())
        .foregroundStyle(themeColors.error)
    }, description: {
      Text(error.errorDescription)
        .multilineTextAlignment(.center)
        .font(.subheadline)
        .foregroundStyle(themeColors.foreground)
    }, actions: {
      Button(action: { Task(operation: state.loadNextPage) }) {
        Label("Retry", systemImage: "arrow.clockwise")
          .padding(.horizontal, 24)
          .padding(.vertical, 12)
      }
      .buttonStyle(.bordered)
      .tint(themeColors.accent)
    })
    .padding()
    .background(.bar, in: .rect(cornerRadius: 10))
    .padding()
    .environment(\.colorScheme, colorScheme)
  }
}

extension Product {
  static let placeholder: Product = .init(id: -1)
}

#Preview {
  AppCoordinator().view(for: .productList)
}
