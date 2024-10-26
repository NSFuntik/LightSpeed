//
//  ProductDetails.swift
//  LightSpeed
//
//  Created by Dmitry Mikhailov on 25.10.2024.
//

import SwiftUI

// MARK: - ProductView

struct ProductDetails: View {
  init(_ product: Product) {
    self.product = product
  }

  let product: Product
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  @Environment(\.colorScheme) private var colorScheme
  private var themeColors: ThemeConfiguration.Colors {
    colorScheme == .dark ? ThemeConfiguration.dark : ThemeConfiguration.light
  }

  var body: some View {
    List {
      productImage

      // Main Details
      VStack(alignment: .leading) {
        (Text(product.brand) + Text(Image(systemName: "chevron.right")))
          .imageScale(.small).font(.subheadline)

        Text(product.title)
          .font(.title)
          .fontWeight(.bold)

        Text(" **\(product.rating, specifier: "%.1f")** ★ ")
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .fontWeight(.semibold)
          .background(.yellow, in: .capsule)

        HStack {
          Text("$\(product.discountedPrice, specifier: "%.2f")")
            .font(.title).fontWeight(.bold)
            .foregroundStyle(.green.gradient)
            .safeAreaInset(edge: .trailing, alignment: .firstTextBaseline, spacing: 6, content: {
              if product.discountPercentage > 0 {
                (Text(" / ") + Text("$\(product.formattedPrice)").strikethrough(true, color: .secondary))
                  .font(.caption)
                  .foregroundColor(.secondary)
              }
            })
          Spacer()

          Text(product.availabilityStatus ?? "Out of Stock")
            .font(.subheadline)
            .foregroundColor(product.stock > 0 ? .green : .red)
            .foregroundStyle(.secondary)
        }
      }

      // Description
      Section("Description") {
        Text(product.description)
          .font(.body).multilineTextAlignment(.leading)

        Group {
          LazyVGrid(
            columns: .init(
              repeating: .init(.flexible()),
              count: product.tags.endIndex),
            alignment: .center, spacing: 0) {
              ForEach(product.tags, id: \.self) { tag in
                Text(tag)
                  .font(.subheadline)
                  .foregroundStyle(.primary)
                  .padding(.vertical, 4).padding(.horizontal, 8)
                  .background(themeColors.accent.opacity(0.1).gradient, in: .capsule)
                  .overlay(.secondary, in: .capsule.stroke())
              }
            }
        }
      }

      Section("Details") {
        detailRow(label: "Weight", value: \.formattedWeight)
        detailRow(label: "Dimensions", value: \.dimensions?.description)
        detailRow(label: "Shipping", value: \.shippingInformation)
        detailRow(label: "Warranty", value: \.warrantyInformation)
        detailRow(label: "Minimum Order Quantity", value: \.minimumOrderQuantity)
        detailRow(label: "SKU", value: \.sku)
      }

      // Reviews Section
      Section("Customer Reviews") {
        ForEach(product.reviews, id: \.reviewerEmail) { review in
          VStack(alignment: .leading, spacing: 4) {
            HStack {
              Text(review.reviewerName)
                .font(.subheadline.weight(.semibold))

              Spacer()
              Text(" \(review.rating) ★ ")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .background(.yellow.secondary, in: .capsule.inset(by: -2))
            }
            Text(review.comment)
              .font(.body)
          }
          .padding(.vertical, 4)
        }
      }

      // QR Code
      if let meta = product.meta {
        HStack(alignment: .center, spacing: 12) {
          Spacer()
          if let qrCode = meta.qrCode,
             let qrCodeUrl = URL(string: qrCode) {
            VStack(alignment: .center) {
              Text("QR Code")
                .font(.headline)
              ResizedAsyncImage(qrCodeUrl)
                .aspectRatio(1, contentMode: .fit)
            }
            .frame(height: 100)
            .cornerRadius(10)
          }
          Divider()
          if let barcodeImage = meta.barcodeImage() {
            VStack(alignment: .center) {
              Text("Barcode")
                .font(.headline)
              Image(uiImage: barcodeImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
            }
            .frame(height: 100)
            .cornerRadius(10)
          }
          Spacer()
        }
      }
    }
    .listStyle(.insetGrouped)
    .navigationTitle("Product \(product.id)")
  }

  private var productImage: some View {
    ResizedAsyncImage(product.thumbnail)
      .clipped()
      .scaledToFit()
      .frame(width: UIScreen.main.bounds.width - 64, height: 200)
  }

  @ViewBuilder
  func detailRow(label: String, value: PartialKeyPath<Product>) -> some View {
    if let value = product[keyPath: value] as? String, !value.isEmpty {
      HStack(alignment: .center, spacing: 8) {
        Text(label)
          .font(.subheadline)
          .fontWeight(.medium)
          .frame(width: dynamicTypeSize.isAccessibilitySize ? 110 : 90, alignment: .leading)
          .foregroundStyle(.secondary).fixedSize(horizontal: true, vertical: true)
        Text("\(value)")
          .frame(maxWidth: .infinity, alignment: .leading)
          .foregroundStyle(.primary)
          .font(.body)
        Spacer()
      }
      .padding(.vertical, 4)
    }
  }
}

#Preview {
  NavigationView {
    ProductDetails(
      Product(
        id: 1,
        title: "Essence Mascara Lash Princess",
        sku: "RCH45Q1A",
        description: "The Essence Mascara Lash Princess is a popular mascara known for its volumizing and lengthening effects.",
        price: 9.99,
        discountPercentage: 50,
        rating: 4.94,
        stock: 5,
        brand: "Essence",
        minimumOrderQuantity: 24,
        reviews: [
          Review(date: .now, name: "John Doe", comment: "Very unhappy with my purchase!", rating: 2, reviewerEmail: "john.doe@x.dummyjson.com"),
          Review(name: "Nolan Gonzalez", comment: "Not as described!", rating: 2, reviewerEmail: "nolan.gonzalez@x.dummyjson.com"),
          Review(name: "Scarlett Wright", comment: "Very satisfied!", rating: 5, reviewerEmail: "scarlett.wright@x.dummyjson.com"),
        ],
        thumbnail: "https://cdn.dummyjson.com/products/images/beauty/Essence%20Mascara%20Lash%20Princess/thumbnail.png",
        tags: ["Lash", "Mascara", "Princess"],
        weight: 2,
        shippingInformation: "Ships in 1 month",
        availabilityStatus: "Low Stock",
        warrantyInformation: "1 month warranty",
        dimensions: Dimensions(width: 23.17, depth: 28.01, height: 14.43),
        meta: Meta(createdAt: .now, barcode: "9164035109868", qrCode: #"https://assets.dummyjson.com/public/qr-code.png"#))
    )
  }
}
