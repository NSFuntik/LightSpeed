//
//  ProductsResponse.swift
//  LightSpeed
//
//  Created by Dmitry Mikhailov on 25.10.2024.
//

import UIKit
import os.log
import Foundation
import CoreImage.CIFilterBuiltins

// MARK: - DTO

/// Universal protocol combining common conformances
protocol DTO: Codable, Hashable, Sendable {
  func validate() throws
}

private let logger = Logger(subsystem: "com.LightSpeed.ProductsCatalog", category: "Product Page DTO")

// MARK: - ProductPage

/// Root response structure
struct ProductPage: DTO {
  let skip: Int
  let limit: Int
  let total: Int
  let products: [Product]

  func validate() throws {
    if skip < 0 || limit < 0 {
      throw ModelParserError.invalidFormat("Invalid pagination parameters")
    }
  }
}

// MARK: - Product

struct Product: DTO {
  init(
    id: Int, title: String = .init(repeating: "*", count: 13), sku: String = .init(),
    description: String = .init(), price: Double = .init(), discountPercentage: Double = .init(),
    rating: Double = .init(), stock: Int = .init(), brand: String = .init(),
    category: String = .init(), minimumOrderQuantity: Int = .init(), reviews: [Review] = .init(),
    images: [String] = .init(), thumbnail: String? = nil, tags: [String] = .init(),
    weight: Int? = nil, shippingInformation: String? = nil, availabilityStatus: String? = nil,
    warrantyInformation: String? = nil, returnPolicy: String? = nil,
    dimensions: Dimensions? = nil, meta: Meta? = nil) {
    self.id = id
    self.title = title
    self.sku = sku
    self.description = description
    self.price = price
    self.discountPercentage = discountPercentage
    self.rating = rating
    self.stock = stock
    self.brand = brand
    self.category = category
    self.minimumOrderQuantity = minimumOrderQuantity
    self.reviews = reviews
    self.images = images
    self.thumbnail = thumbnail
    self.tags = tags
    self.weight = weight
    self.shippingInformation = shippingInformation
    self.availabilityStatus = availabilityStatus
    self.warrantyInformation = warrantyInformation
    self.returnPolicy = returnPolicy
    self.dimensions = dimensions
    self.meta = meta
  }

  // Required fields
  let id: Int
  let title: String
  let sku: String

  // Fields with default vlues
  let description: String
  let price: Double
  let discountPercentage: Double
  let rating: Double
  let stock: Int
  let brand: String
  let category: String
  let minimumOrderQuantity: Int
  let reviews: [Review]
  let images: [String]

  // Optional fields
  let thumbnail: String?
  let tags: [String]
  let weight: Int?
  let shippingInformation: String?
  let availabilityStatus: String?
  let warrantyInformation: String?
  let returnPolicy: String?
  let dimensions: Dimensions?
  let meta: Meta?

  enum CodingKeys: String, CodingKey {
    case id, title, sku
    case weight, shippingInformation, availabilityStatus,
         description, price, discountPercentage,
         rating, stock, brand, category
    case thumbnail, images, tags, warrantyInformation,
         returnPolicy, minimumOrderQuantity,
         dimensions, reviews, meta
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    // Required fields
    do {
      id = try container.decode(Int.self, forKey: .id)
      title = try container.decode(String.self, forKey: .title)
      sku = try container.decode(String.self, forKey: .sku)
    } catch {
      logger.error("Failed to decode required field: \(error.localizedDescription)")
      throw error
    }

    description = (try? container.decodeIfPresent(String.self, forKey: .description)) ?? ""
    price = (try? container.decodeIfPresent(Double.self, forKey: .price)) ?? 0.0
    discountPercentage = (try? container.decodeIfPresent(Double.self, forKey: .discountPercentage)) ?? 0.0
    rating = (try? container.decodeIfPresent(Double.self, forKey: .rating)) ?? 0.0
    stock = (try? container.decodeIfPresent(Int.self, forKey: .stock)) ?? 0
    brand = (try? container.decodeIfPresent(String.self, forKey: .brand)) ?? ""
    category = (try? container.decodeIfPresent(String.self, forKey: .category)) ?? ""
    minimumOrderQuantity = (try? container.decodeIfPresent(Int.self, forKey: .minimumOrderQuantity)) ?? 1
    thumbnail = try? container.decodeIfPresent(String.self, forKey: .thumbnail)
    images = (try? container.decodeIfPresent([String].self, forKey: .images)) ?? []
    tags = (try? container.decodeIfPresent([String].self, forKey: .tags)) ?? []
    weight = try? container.decodeIfPresent(Int.self, forKey: .weight)
    shippingInformation = try? container.decodeIfPresent(String.self, forKey: .shippingInformation)
    availabilityStatus = try? container.decodeIfPresent(String.self, forKey: .availabilityStatus)
    warrantyInformation = try? container.decodeIfPresent(String.self, forKey: .warrantyInformation)
    returnPolicy = try? container.decodeIfPresent(String.self, forKey: .returnPolicy)
    dimensions = try? container.decodeIfPresent(Dimensions.self, forKey: .dimensions)
    reviews = (try? container.decodeIfPresent([Review].self, forKey: .reviews)) ?? []
    meta = try? container.decodeIfPresent(Meta.self, forKey: .meta)
  }

  var formattedPrice: String {
    String(format: "%.2f", price)
  }

  var discountedPrice: Double {
    let discount = price * (discountPercentage / 100.0)
    return max(0, price - discount)
  }

  var formattedWeight: String? {
    guard let weight = weight else { return nil }
    let weightMeasurement = Measurement(value: Double(weight), unit: UnitMass.grams)
    return weightMeasurement.formatted(.measurement(width: .wide, usage: .general))
  }

  func validate() throws {
    if title.isEmpty {
      throw ModelParserError.missingRequiredField("title")
    }
    if sku.isEmpty {
      throw ModelParserError.missingRequiredField("sku")
    }
  }
}

// MARK: - Dimensions

/// Product dimensions
struct Dimensions: DTO, CustomStringConvertible {
  let width: Double?
  let depth: Double?
  let height: Double?

  init(width: Double? = nil,
       depth: Double? = nil,
       height: Double? = nil) {
    self.width = width
    self.depth = depth
    self.height = height
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    do {
      width = try container.decodeIfPresent(Double.self, forKey: .width)
      depth = try container.decodeIfPresent(Double.self, forKey: .depth)
      height = try container.decodeIfPresent(Double.self, forKey: .height)
    } catch {
      logger.error("Failed to decode dimensions: \(error.localizedDescription)")
      throw error
    }
  }

  func validate() throws {
    guard let width = width, let depth = depth, let height = height else { return }
    if width <= 0 || depth <= 0 || height <= 0 {
      throw ModelParserError.invalidFormat("Dimensions must be positive")
    }
  }

  var description: String {
    guard let width = width, let depth = depth, let height = height else { return "" }
    return String(format: "%.2f x %.2f x %.2f cm", width, depth, height)
  }
}

// MARK: - Review

/// Product review
struct Review: DTO {
  let date: Date
  let reviewerName: String
  let reviewerEmail: String?
  let comment: String
  let rating: Int

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    do {
      date = try container.decode(Date.self, forKey: .date)
      reviewerName = try container.decode(String.self, forKey: .reviewerName)
      comment = try container.decode(String.self, forKey: .comment)
      rating = try container.decode(IntegerLiteralType.self, forKey: .rating)
      reviewerEmail = try container.decodeIfPresent(String.self, forKey: .reviewerEmail)
    } catch {
      logger.error("Failed to decode review: \(error.localizedDescription)")
      throw error
    }
  }

  init(date: Date = .now, name: String, comment: String, rating: Int, reviewerEmail: String? = nil) {
    self.date = date
    self.reviewerName = name
    self.comment = comment
    self.rating = rating
    self.reviewerEmail = reviewerEmail
  }

  func validate() throws {
    if reviewerName.isEmpty {
      throw ModelParserError.missingRequiredField("reviewer name")
    }
    if rating < 1 || rating > 5 {
      throw ModelParserError.invalidFormat("Rating must be between 1 and 5")
    }
  }
}

// MARK: - Meta

/// Product metadata
struct Meta: DTO {
  let barcode: String?
  let qrCode: String?
  let createdAt: Date
  let updatedAt: Date

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    do {
      createdAt = try container.decode(Date.self, forKey: .createdAt)
      updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? createdAt
      barcode = try container.decodeIfPresent(String.self, forKey: .barcode)
      qrCode = try container.decodeIfPresent(String.self, forKey: .qrCode)
    } catch {
      logger.error("Failed to decode meta: \(error.localizedDescription)")
      throw error
    }
  }

  init(createdAt: Date,
       updatedAt: Date? = nil,
       barcode: String? = nil,
       qrCode: String? = nil) {
    self.createdAt = createdAt
    self.updatedAt = updatedAt ?? createdAt
    self.barcode = barcode
    self.qrCode = qrCode
  }

  /// Only validate date formats if they exist
  func validate() throws {
    guard let qrCode = barcodeImage() else { throw ModelParserError.invalidFormat("Invalid QR Code") }
  }

  func barcodeImage() -> UIImage? {
    let context = CIContext()
    let filter = CIFilter.code128BarcodeGenerator()

    func generateBarcode(from string: String) -> UIImage? {
      let data = Data(string.utf8)
      filter.message = data

      if let outputImage = filter.outputImage,
         let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
        return UIImage(cgImage: cgImage)
      }

      return nil
    }

    return generateBarcode(from: barcode ?? "")
  }
}
