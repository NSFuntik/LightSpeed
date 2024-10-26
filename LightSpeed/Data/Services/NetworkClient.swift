//
//  NetworkService.swift
//  LightSpeed
//
//  Created by Dmitry Mikhailov on 25.10.2024.
//

import os.log
import Foundation

private let logger = Logger(subsystem: "com.LightSpeed.ProductsCatalog", category: "NetworkClient")

// MARK: - NetworkClient

/// Network client implementing NetworkServiceProtocol
actor NetworkClient: @preconcurrency NetworkServiceProtocol {
  var tasks: [URL: Task<Data, Error>] = [:]

  func fetch(
    _ endpoint: APIEndpoint
  ) async throws(NetworkError) -> Data {
    logger.debug("Fetching \(endpoint.url?.absoluteString ?? "nil")")
    guard let url = endpoint.url else {
      throw NetworkError.invalidURL
    }

    if tasks[url] != nil, let value = try? await tasks[url]!.value {
      logger.debug("Task was in progress")
      return value
    }

    tasks[url]?.cancel()

    let task = Task<Data, Error> {
      let (data, response) = try await URLSession.shared.data(from: url)

      guard let httpResponse = response as? HTTPURLResponse else {
        throw NetworkError.invalidResponse
      }

      guard (200 ... 299).contains(httpResponse.statusCode) else {
        logger.error("Server error occured: \(httpResponse.statusCode)")
        throw NetworkError.serverError(httpResponse.statusCode)
      }

      return data
    }

    tasks[url] = task

    do {
      let result = try await task.value
      tasks[url] = nil
      return result
    } catch {
      tasks[url] = nil
      throw NetworkError.unknown(error)
    }
  }
}
