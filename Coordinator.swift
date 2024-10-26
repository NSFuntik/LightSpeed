//
//  Coordinator.swift
//

import SwiftUI
import Combine
import Foundation

// MARK: - Navigation

/// Example of implementation:
///
///     final class SomeCoordinator: NavigationModalCoordinator {
///
///       enum Screen: ScreenProtocol {
///          case screen1
///          case screen2
///          case screen3
///       }
///
///       func destination(for screen: Screen) -> some View {
///          switch screen {
///              case .screen1: Screen1View()
///              case .screen2: Screen2View()
///              case .screen3: Screen3View()
///          }
///       }
///
///       enum ModalFlow: ModalProtocol {
///          case modalScreen1
///          case modalFlow(ChildCoordinator = .init())
///       }
///
///       func destination(for flow: ModalFlow) -> some View {
///          switch flow {
///             case .modalScreen1: Modal1View()
///             case .modalFlow(let coordinator): coordinator.view(for: .rootScreen)
///          }
///       }
///     }
///
/// SomeCoordinator contains a navigation controller that can push one of the 3 views defined by ``Screen`` enum.
/// Also it can present a modal view and a modal navigation flow with child navigation specified by `ChildCoordinator`
///
/// Show view in SwiftUI hierarchy, with screen1 as root view:
///
///     coordinator.view(for: .screen1)
///
/// Push view in navigation stack:
///
///     coordinator.present(.screen1)
///
/// Present modal view:
///
///     coordinator.present(.modalFlow())
///
public final class Navigation<C: Coordinator>: ObservableObject {
  private(set) weak var object: C?
  private var observer: AnyCancellable?

  public init(_ object: C) {
    self.object = object

    observer = object.objectWillChange.sink { [weak self] _ in
      self?.objectWillChange.send()
    }
  }

  public func callAsFunction() -> C { object! }
}

public protocol Coordinator: ObservableObject, Hashable {}

private var coordinatorStateKey = 0
private var coordinatorWeakReferenceKey = 0

public extension Coordinator {
  /// Coordinator state, encapsulates current navigation path and presented modal flow and reference to parent coordinator
  var state: NavigationState {
    if let state = objc_getAssociatedObject(self, &coordinatorStateKey) as? NavigationState {
      return state
    } else {
      let state = NavigationState()
      objc_setAssociatedObject(self, &coordinatorStateKey, state, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      return state
    }
  }

  var weakReference: Navigation<Self> {
    if let reference = objc_getAssociatedObject(self, &coordinatorWeakReferenceKey) as? Navigation<Self> {
      return reference
    } else {
      let reference = Navigation(self)
      objc_setAssociatedObject(self, &coordinatorWeakReferenceKey, reference, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      return reference
    }
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(ObjectIdentifier(self))
  }

  static func == (lhs: Self, rhs: Self) -> Bool { lhs.hashValue == rhs.hashValue }

  /// Dismiss current modal navigation
  func dismiss() {
    state.presentedBy?.dismissPresented()
  }

  /// Dismiss modal navigation presented over current navigation
  func dismissPresented() {
    state.modalPresented = nil
  }

  /// Move to previous screen of the current navigation
  func pop() {
    state.path.removeLast()
  }

  /// Move to the first screen of the current navigation
  func popToRoot() {
    state.path.removeAll()
  }
}

extension Coordinator {
  func present(_ presentation: ModalPresentation, resolve: PresentationResolve = .overAll) {
    if let presentedCoordinator = state.modalPresented?.coordinator {
      switch resolve {
      case .replaceCurrent:
        dismissPresented()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
          self?.present(presentation, resolve: resolve)
        }
      case .overAll:
        presentedCoordinator.present(presentation, resolve: resolve)
      }
    } else {
      presentation.coordinator.state.presentedBy = self
      state.modalPresented = presentation
    }
  }
}

public extension Coordinator {
  static var defaultAlertTitle: String { Bundle.main.infoDictionary!["CFBundleDisplayName"] as? String ?? Bundle.main.infoDictionary!["CFBundleName"] as? String ?? "" }

  func alert<A: View, M: View>(_ title: String = Self.defaultAlertTitle,
                               @ViewBuilder _ message: @escaping () -> M,
                               @ViewBuilder actions: @escaping () -> A) {
    state.alerts.append(.init(title: title, actions: actions, message: message))
  }

  func alert<M: View>(_ title: String = Self.defaultAlertTitle,
                      @ViewBuilder _ message: @escaping () -> M) {
    state.alerts.append(.init(title: title, actions: { Button("OK") {} }, message: message))
  }

  func alert(_ title: String = Self.defaultAlertTitle, message: String) {
    state.alerts.append(.init(title: title, actions: { Button("OK") {} }, message: { Text(message) }))
  }

  func alert<A: View>(_ title: String = Self.defaultAlertTitle,
                      message: String,
                      @ViewBuilder actions: @escaping () -> A) {
    state.alerts.append(.init(title: title, actions: actions, message: { Text(message) }))
  }
}

public typealias NavigationModalCoordinator = ModalCoordinator & NavigationCoordinator

public extension CoordinateSpace {
  /// Coordinated space related to navigation view
  static let navController = "CoordinatorSpaceNavigationController"

  /// Coordinated space related to modal presentation view
  static let modal = "CoordinatorSpaceModal"
}

// MARK: - CustomCoordinator

public protocol CustomCoordinator: Coordinator {
  associatedtype DestinationView: View

  func destination() -> DestinationView
}

public extension CustomCoordinator {
  var rootView: some View {
    destination().withModal(self)
  }
}

//

// MARK: -  ModalCoordinator.swift

import SwiftUI
import Foundation

// MARK: - ModalStyle

/// Modal presentation stype of the Modal flow
public enum ModalStyle {
  /// Present as sheet, takes part of the screen and dimms screen below
  case sheet

  /// Presents as full screen cover
  case cover

  /// Presents screen over current navigation. This option is for customizing, it doesn't interfear with native navigation controller or modal presentation flow.
  case overlay
}

// MARK: - ModalProtocol

/// Protocol for conforming by a modal navigation flow
public protocol ModalProtocol: Hashable, Identifiable {
  /// Modal flow presentation style
  var style: ModalStyle { get }
}

public extension ModalProtocol {
  var style: ModalStyle { .sheet }

  var id: Int { hashValue }
}

extension ModalProtocol {
  var coordinator: (any Coordinator)? {
    for child in Mirror(reflecting: self).children {
      if let value = child.value as? (any Coordinator) {
        return value
      }
    }
    return nil
  }
}

// MARK: - ModalCoordinator

public protocol ModalCoordinator: Coordinator {
  associatedtype Modal: ModalProtocol
  associatedtype ModalView: View

  @ViewBuilder func destination(for modal: Modal) -> ModalView
}

// MARK: - PresentationResolve

/// Resolution for the case when we're trying to present a modal flow over screen which already presents another screen
public enum PresentationResolve {
  /// Search for currently presented top screen and present our screen over it
  case overAll

  /// Dismiss currently presented screen and present our screen in replace
  case replaceCurrent
}

public extension ModalCoordinator {
  /// Present a flow modally over current navigation
  func present(_ modalFlow: Modal, resolve: PresentationResolve = .overAll) {
    present(.init(modalFlow: modalFlow,
                  destination: { [unowned self] in AnyView(self.destination(for: modalFlow)) }),
            resolve: resolve)
  }
}

// MARK: - ModalModifer

private struct ModalModifer: ViewModifier {
  @ObservedObject var state: NavigationState

  func isPresentedBinding(_ style: ModalStyle) -> Binding<Bool> {
    .init { [weak state] in
      state?.modalPresented?.modalFlow.style == style
    } set: { [weak state] _ in
      if let presented = state?.modalPresented,
         let overlayPresented = presented.coordinator.state.modalPresented,
         overlayPresented.modalFlow.style == .overlay {
        presented.coordinator.state.modalPresented = nil
      } else {
        state?.modalPresented = nil
      }
    }
  }

  func body(content: Content) -> some View {
    content.overlay {
      if let presented = state.modalPresented, presented.modalFlow.style == .overlay {
        presented.destination()
          .coordinateSpace(name: CoordinateSpace.modal)
      }
    }.sheet(isPresented: isPresentedBinding(.sheet)) { [weak state] in
      state?.modalPresented!.destination()
        .coordinateSpace(name: CoordinateSpace.modal)
    }.fullScreenCover(isPresented: isPresentedBinding(.cover)) { [weak state] in
      state?.modalPresented!.destination()
        .coordinateSpace(name: CoordinateSpace.modal)
    }.alert(state.alerts.last?.title ?? "",
            isPresented: Binding(get: { state.alerts.last != nil }, set: { _ in
              if state.alerts.count > 0 {
                state.alerts.removeLast()
              }
            }),
            actions: state.alerts.last?.actions ?? { AnyView(EmptyView()) },
            message: state.alerts.last?.message ?? { AnyView(EmptyView()) })
  }
}

public extension View {
  /// Supply view with ability to present screens using specified coordinator
  func withModal<C: Coordinator>(_ coordinator: C) -> some View {
    modifier(ModalModifer(state: coordinator.state)).environmentObject(coordinator.weakReference)
  }
}

/// Protocol for conforming by a screen in horizontal navigation flow
public protocol ScreenProtocol: Hashable {}

// MARK: - NavigationCoordinator

public protocol NavigationCoordinator: Coordinator {
  associatedtype Screen: ScreenProtocol
  associatedtype ScreenView: View

  @ViewBuilder func destination(for screen: Screen) -> ScreenView
}

public extension NavigationCoordinator {
  /// Navigate to a new screen in current navigation stack
  func present(_ screen: Screen) {
    state.path.append(screen)
  }

  /// Move back to a specified screen in current navigation
  @discardableResult
  func popTo(where condition: (Screen) -> Bool) -> Bool {
    if let index = state.path.firstIndex(where: {
      if let screen = $0 as? Screen {
        return condition(screen)
      }
      return false
    }) {
      state.path.removeLast(state.path.count - index - 1)
      return true
    }
    return false
  }

  /// Move back to a specified screen in current navigation
  @discardableResult
  func popTo(_ element: Screen) -> Bool {
    popTo(where: { $0 == element })
  }
}

@available(iOS 16.0, *)
public extension View {
  func withNavigation<C: NavigationCoordinator>(_ coordinator: C) -> some View {
    modifier(NavigationModifer(coordinator: coordinator))
  }
}

@available(iOS 16.0, *)
public extension NavigationCoordinator {
  func view(for screen: Screen) -> some View {
    destination(for: screen).withNavigation(self).withModal(self)
  }
}

// MARK: - NavigationModifer

@available(iOS 16.0, *)
private struct NavigationModifer<Coordinator: NavigationCoordinator>: ViewModifier {
  let coordinator: Coordinator
  @ObservedObject var state: NavigationState

  init(coordinator: Coordinator) {
    self.coordinator = coordinator
    self.state = coordinator.state
  }

  public func body(content: Content) -> some View {
    NavigationStack(path: $state.path) { [weak coordinator] in
      content.navigationDestination(for: AnyHashable.self) {
        if let screen = $0 as? Coordinator.Screen {
          coordinator?.destination(for: screen)
        }
      }
    }.coordinateSpace(name: CoordinateSpace.navController)
  }
}

///Current modal presentation that stores parent coordinator
public struct ModalPresentation {
  
  private final class PlaceholderCoordinator: Coordinator { }
  
  public let modalFlow: any ModalProtocol
  
  let coordinator: any Coordinator
  let destination: ()->AnyView
  
  init(modalFlow: any ModalProtocol, destination: @escaping () -> AnyView) {
    self.modalFlow = modalFlow
    
    if let coordinator = modalFlow.coordinator {
      self.destination = destination
      self.coordinator = coordinator
    } else {
      let coordinator = PlaceholderCoordinator()
      self.destination = { [unowned coordinator] in AnyView(destination().withModal(coordinator)) }
      self.coordinator = coordinator
    }
  }
}

///Coordinator navigation state. Stores current navigation path and a reference to presented child navigation with reference to parent coordinator
public final class NavigationState: ObservableObject {
  
  /// Current navigation path
  @Published public var path: [AnyHashable] = []
  
  /// Modal flow presented over current navigation
  @Published public internal(set) var modalPresented: ModalPresentation?
  
  struct Alert {
    let title: String
    let actions: ()->AnyView
    let message: ()->AnyView
    
    init<A: View, M: View>(title: String, actions: @escaping ()->A, message: @escaping ()->M) {
      self.title = title
      self.actions = { AnyView(actions()) }
      self.message = { AnyView(message()) }
    }
  }
  
  /// Currently presented alerts
  @Published var alerts: [Alert] = []
  
  /// Parent coordinator presented current navigation modally
  public internal(set) weak var presentedBy: (any Coordinator)?
  private var observers: [AnyCancellable] = []
  
  public init() {
    $path.sink { [weak self] _ in
      self?.closeKeyboard()
    }.store(in: &observers)
    
    $modalPresented.sink { [weak self] _ in
      self?.closeKeyboard()
    }.store(in: &observers)
  }
  
  private func closeKeyboard() {
    UIApplication.shared.resignFirstResponder()
  }
}

