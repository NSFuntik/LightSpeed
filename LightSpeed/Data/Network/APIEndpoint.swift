//
//  APIEndpoint.swift
//  LightSpeed
//
//  Created by Dmitry Mikhailov on 25.10.2024.
//

import Foundation

enum APIEndpoint {
  case products(limit: Int = 20, skip: Int)

  var url: URL? {
    switch self {
    case let .products(limit, skip):
      var components = URLComponents()
      components.scheme = "https"
      components.host = "dummyjson.com"
      components.path = "/products"
      components.queryItems = [
        URLQueryItem(name: "skip", value: String(skip)),
        URLQueryItem(name: "limit", value: String(limit)),
      ]
      return components.url
    }
  }
}
