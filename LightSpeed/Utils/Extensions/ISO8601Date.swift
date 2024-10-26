//
//  ISO8601Date.swift
//  LightSpeed
//
//  Created by Dmitry Mikhailov on 25.10.2024.
//
import Foundation

// MARK: - ISO8601Date

@propertyWrapper
struct ISO8601Date: Codable, Hashable, Sendable {
  private var date: Date
  private static let formatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
  }()

  var wrappedValue: Date {
    get { date }
    set { date = newValue }
  }

  init(wrappedValue: Date) {
    self.date = wrappedValue
  }

  init(_ wrappedValue: String) {
    self.date = ISO8601Date.formatter.date(from: wrappedValue) ?? .now
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let dateString = try container.decode(String.self)
    self.date = ISO8601Date.formatter.date(from: dateString) ?? .now
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    let dateString = ISO8601Date.formatter.string(from: date)
    try container.encode(dateString)
  }
}

// MARK: ExpressibleByStringLiteral

extension ISO8601Date: ExpressibleByStringLiteral {
  init(stringLiteral value: String) {
    self.init(value)
  }
}

// MARK: ISO8601Date + Now

extension ISO8601Date {
  public static var now: ISO8601Date {
    .init(wrappedValue: .now)
  }
}
