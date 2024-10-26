//
//  NetworkServiceProtocol.swift
//  LightSpeed
//
//  Created by Dmitry Mikhailov on 25.10.2024.
//
import UIKit
import Foundation

// MARK: - NetworkServiceProtocol

/// Network  service
protocol NetworkServiceProtocol {
  var tasks: [URL: Task<Data, Error>] { get set }
  func fetch(_ endpoint: APIEndpoint) async throws -> Data
}

// MARK: - ImageServiceProtocol

/// Protocol defining image loading and caching operations
protocol ImageServiceProtocol {
  func loadImage(from urlString: String, targetSize: CGSize) async throws -> UIImage
}
