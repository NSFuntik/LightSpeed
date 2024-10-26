//
//  Shimmer.swift
//  LightSpeed
//
//  Created by Dmitry Mikhailov on 25.10.2024.
//

import SwiftUI

// MARK: - Shimmer

/// A view modifier that applies an animated "shimmer" to any view, typically to show that an operation is in progress.
public struct Shimmer: ViewModifier {
  @State private var isInitialState = true
  var isActive: Bool
  @ViewBuilder
  public func body(content: Content) -> some View {
    if isActive {
      content
        .mask(
          LinearGradient(
            colors: [.black.opacity(0.4), .black, .black.opacity(0.4)],
            startPoint: isInitialState ? .init(x: -0.3, y: -0.3) : .init(x: 1, y: 1),
            endPoint: isInitialState ? .init(x: 0, y: 0) : .init(x: 1.3, y: 1.3))
        )

        .animation(
          .linear(duration: 1.33).delay(0.33)
            .repeatForever(autoreverses: true),
          value: isInitialState)
        .onAppear {
          isInitialState = false
        }
    } else { content }
  }
}

public extension View {
  /// Applies the `Shimmer` view modifier to the current view.
  func shimmering(active: Bool = true) -> some View {
    modifier(Shimmer(isActive: active))
  }
}
