//
//  ThemeConfiguration.swift
//  LightSpeed
//
//  Created by Dmitry Mikhailov on 25.10.2024.
//

import SwiftUI

// MARK: - ThemeConfiguration

/// Theme configuration with light/dark mode adaptation
enum ThemeConfiguration {
  struct Colors {
    let background: Color
    let foreground: Color
    let accent: Color
    let error: Color
  }

  static let light = Colors(
    background: Color(.systemBackground),
    foreground: Color(.label),
    accent: Color.accentColor,
    error: Color.red)

  static let dark = Colors(
    background: Color(.systemBackground),
    foreground: Color(.label),
    accent: Color.accentColor.opacity(0.8),
    error: Color.red.opacity(0.8))
}
