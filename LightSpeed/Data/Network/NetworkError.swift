//
//  NetworkError.swift
//  LightSpeed
//
//  Created by Dmitry Mikhailov on 25.10.2024.
//

import Foundation

/// ## Error Handling
///
/// - **Network Errors**: Handled in `ProductListViewModel` by catching exceptions during the fetch operation and updating the `errorMessage` property.
/// - **Image Loading Errors**: In `ResizedAsyncImage`, errors during image loading are caught, and a placeholder is displayed.
/// - **Coordinator Alerts**: Using the provided Coordinator implementation, alerts can be presented via the coordinator if needed.
///
enum NetworkError: LocalizedError, Error, Identifiable {
  var id: Int {
    return switch self {
    case .invalidURL: 0
    case .invalidResponse: 1
    case .serverError: 2
    case .decodingError: 3
    case .unknown: 4
    }
  }

  case invalidURL
  case invalidResponse
  case decodingError(DecodingError)
  case serverError(_ statusCode: Int)
  case unknown(Error)

  var errorDescription: String {
    switch self {
    case .invalidURL:
      return "Invalid URL"
    case .invalidResponse:
      return "Invalid server response"
    case let .decodingError(error):
      return "Error processing data \(error.failureReason ?? error.localizedDescription)"
    case let .serverError(statusCode):
      return "Server error: \(statusCode)"
    case let .unknown(error):
      return "Unknown error occurred: \n \(error.localizedDescription)"
    }
  }
}
