//
//  ModelParser.swift
//  LightSpeed
//
//  Created by Dmitry Mikhailov on 25.10.2024.
//
import os.log
import Foundation

private let logger = Logger(subsystem: "com.LightSpeed.ProductsCatalog", category: "ModelParser")

// MARK: - ModelParser

/// Generic parser for any `DTO` type
class ModelParser<T: DTO> {
  /// Parse JSON data into a `DTO` type
  /// - Parameter jsonData: The JSON data to parse
  /// - Returns: Parsed model of type T
  /// - Throws: ProductParserError
  static func parse(jsonData: Data) throws(ModelParserError) -> T {
    do {
      let decoder = JSONDecoder()
      decoder.keyDecodingStrategy = .useDefaultKeys
      decoder.dateDecodingStrategy = .iso8601

      let model = try decoder.decode(T.self, from: jsonData)
      try model.validate()

      return model
    } catch let error as DecodingError {
      switch error {
      case let .keyNotFound(key, _):
        logger.error("Missing required field: \(key.stringValue)")
        throw .missingRequiredField(key.stringValue)
      case let .typeMismatch(_, context):
        logger.error("Type mismatch: \(context.debugDescription)")
        throw .decodingError("Type mismatch: \(context.debugDescription)")
      case let .valueNotFound(_, context):
        logger.error("Value not found: \(context.debugDescription)")
        throw .decodingError("Value not found: \(context.debugDescription)")
      case let .dataCorrupted(context):
        logger.error("Data corrupted: \(context.debugDescription)")
        throw .decodingError("Data corrupted: \(context.debugDescription)")
      @unknown default:
        logger.error("Unknown decoding error")
        throw .decodingError("Unknown decoding error")
      }
    } catch let error as ModelParserError {
      logger.error("Product parser error: \(error.localizedDescription)")
      throw error
    } catch {
      logger.error("Unexpected error: \(error.localizedDescription)")
      throw ModelParserError.invalidJSON(error.localizedDescription)
    }
  }

  /// Parse JSON string into a `DTO` type
  /// - Parameter jsonString: The JSON string to parse
  /// - Returns: Parsed model of type T
  /// - Throws: ProductParserError
  static func parse(jsonString: String) throws(ModelParserError) -> T {
    guard let data = jsonString.data(using: .utf8) else {
      logger.error("Failed to convert string to data")
      throw .invalidData
    }
    return try parse(jsonData: data)
  }

  /// Safe parsing method that returns nil instead of throwing
  /// - Parameter jsonData: The JSON data to parse
  /// - Returns: Optional model of type T
  static func safeParse(jsonData: Data) -> T? {
    do {
      return try parse(jsonData: jsonData)
    } catch {
      logger.error("Safe parse failed: \(error.localizedDescription)")
      return nil
    }
  }
}

/// Type alias for ProductParser for backward compatibility
typealias ProductParser = ModelParser<ProductPage>

// MARK: - ModelParserError

/// Custom errors for better error handling
enum ModelParserError: Error {
  case invalidData
  case invalidJSON(String)
  case decodingError(String)
  case invalidFormat(String)
  case missingRequiredField(String)

  var localizedDescription: String {
    switch self {
    case .invalidData:
      return "The provided data is invalid"
    case let .invalidJSON(details):
      return "Invalid JSON format: \(details)"
    case let .decodingError(details):
      return "Failed to decode JSON: \(details)"
    case let .invalidFormat(details):
      return "Invalid data format: \(details)"
    case let .missingRequiredField(field):
      return "Missing required field: \(field)"
    }
  }
}
