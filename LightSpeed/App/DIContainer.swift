//
//  DIContainer.swift
//  LightSpeed
//
//  Created by Dmitry Mikhailov on 25.10.2024.
//

import Foundation

// MARK: - DI Keys

extension DI {
  static let networkService = Key<any NetworkServiceProtocol>()
  static let imageService = Key<any ImageServiceProtocol>()
}

// MARK: - DI Container Setup

extension DI.Container {
  static func setup() {
    register(DI.networkService, NetworkClient())
    register(DI.imageService, ImageService())
  }
}
