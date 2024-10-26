//
//  ImageService.swift
//  LightSpeed
//
//  Created by Dmitry Mikhailov on 25.10.2024.
//

import UIKit
import Foundation

// MARK: - Services

/// Image Loading Service
actor ImageService: ImageServiceProtocol {
  /// Caching
  private var cache: [String: UIImage] = [:]

  func loadImage(from urlString: String, targetSize: CGSize) async throws -> UIImage {
    if let cachedImage = cache[urlString] {
      return cachedImage
    }

    guard let url = URL(string: urlString) else {
      throw NetworkError.invalidURL
    }

    let (data, _) = try await URLSession.shared.data(from: url)
    guard let originalImage = UIImage(data: data) else {
      throw NetworkError.invalidResponse
    }

    let resizedImage = await resizeImage(originalImage, to: targetSize)
    cache[urlString] = resizedImage

    return resizedImage
  }

  private func resizeImage(
    _ image: UIImage,
    to targetSize: CGSize) async -> UIImage {
    return await withCheckedContinuation { continuation in
      DispatchQueue.global(qos: .userInitiated).async {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resizedImage = renderer.image { _ in
          image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        continuation.resume(returning: resizedImage)
      }
    }
  }

  init() {}
}
