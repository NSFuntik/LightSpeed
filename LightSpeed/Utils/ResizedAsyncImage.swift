//
//  ResizedAsyncImage.swift
//  LightSpeed
//
//  Created by Dmitry Mikhailov on 26.10.2024.
//
import SwiftUI

// MARK: - ResizedAsyncImage

struct ResizedAsyncImage: View {
  @DI.Observed(DI.imageService) private var imageService
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  init(_ url: URL?) {
    self.url = url
  }

  init(_ url: String?) {
    self.url = url.flatMap { URL(string: $0) }
  }

  let url: URL?
  private var size: CGSize {
    dynamicTypeSize.isAccessibilitySize ? CGSize(width: 96, height: 96) : CGSize(width: 64, height: 64)
  }

  @State private var image: Image?
  @State private var isLoading = false

  var body: some View {
    ZStack {
      if let image = image {
        image
          .resizable().scaledToFit()
          .cornerRadius(8)
      } else if isLoading {
        ProgressView().padding()
      } else {
        Image(.placeholder)
          .resizable().padding()
      }
    }
    .scaledToFill()
    .task(id: url?.absoluteString, priority: .utility, loadImage)
  }

  @Sendable
  private func loadImage() async {
    guard !isLoading else { return }
    guard let url = url else { return }
    isLoading = true

    do {
      let uiimage = try await imageService.loadImage(from: url.absoluteString, targetSize: size)

      self.image = Image(uiImage: uiimage.resizableImage(withCapInsets: .zero, resizingMode: .stretch))

    } catch {
      self.image = Image(.placeholder)
    }
    isLoading = false
  }
}
