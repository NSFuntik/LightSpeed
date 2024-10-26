//
//  ProductCell.swift
//  LightSpeed
//
//  Created by Dmitry Mikhailov on 25.10.2024.
//

import SwiftUI

// MARK: - ProductCell

struct ProductCell: View {
  @DI.Observed(DI.imageService) private var imageService
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  let product: Product
  @State private var image: UIImage?
  @State private var isLoading = false
  @State private var error: Error?

  private var themeColors: ThemeConfiguration.Colors {
    colorScheme == .dark ? ThemeConfiguration.dark : ThemeConfiguration.light
  }

  var body: some View {
    HStack(spacing: dynamicTypeSize.isAccessibilitySize ? 16 : 12) {
      productImage

      VStack(alignment: .leading, spacing: 4) {
        Text(product.title)
          .font(.headline)
          .foregroundStyle(themeColors.foreground)
          .lineLimit(2)

        Text("$\(product.formattedPrice)")
          .foregroundStyle(.secondary)
          .font(.subheadline.weight(.medium))
        HStack {
          Spacer()
          Image(systemName: product.stock > 0 ? "checkmark.circle" : "xmark.circle")
            .foregroundStyle(product.stock > 0 ? .green : .red)
            .symbolRenderingMode(.hierarchical)
          Text("\(product.stock) in stock")
            .font(.caption)
            .foregroundStyle(product.stock > 0 ? .green : .red)
        }
      }
      Spacer()
    }
    
    .accessibilityElement(children: .combine)
    .task(loadImage)
  }

  private var productImage: some View {
    Group {
      if let image = image {
        Image(uiImage: image)
          .resizable()
          .aspectRatio(contentMode: .fill)
      } else if isLoading {
        ProgressView()
      }
    }
    .frame(
      width: dynamicTypeSize.isAccessibilitySize ? 96 : 64,
      height: dynamicTypeSize.isAccessibilitySize ? 64 : 64)
    .clipped()
    .background(themeColors.background.gradient, in: .rect(cornerRadius: 8))
  }

  @Sendable
  private func loadImage() async {
    guard image == nil, !isLoading else { return }

    isLoading = true
    do {
      let size = dynamicTypeSize.isAccessibilitySize ?
        CGSize(width: 96, height: 96) :
        CGSize(width: 64, height: 64)
      guard let thumbnail = product.thumbnail else {
        image = UIImage(resource: .placeholder)
        return
      }
      image = try await imageService.loadImage(
        from: thumbnail,
        targetSize: size)
    } catch {
      self.error = error
    }
    isLoading = false
  }
}

#Preview {
  List {
    ProductCell(product: .placeholder)
  }
}
