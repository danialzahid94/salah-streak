import Foundation
import SwiftUI

@Observable
final class MainTabCoordinator {
    var selectedTab: Int = 0

    var dashboardPath  = NavigationPath()
    var badgesPath     = NavigationPath()
    var statsPath      = NavigationPath()
    var settingsPath   = NavigationPath()

    var presentedSheet: Route?

    var currentPath: Binding<NavigationPath> {
        switch selectedTab {
        case 0: return Binding { self.dashboardPath }  set: { self.dashboardPath  = $0 }
        case 1: return Binding { self.badgesPath }     set: { self.badgesPath     = $0 }
        case 2: return Binding { self.statsPath }      set: { self.statsPath      = $0 }
        default: return Binding { self.settingsPath }  set: { self.settingsPath   = $0 }
        }
    }

    func navigate(to route: Route) {
        currentPath.wrappedValue.append(route)
    }

    func presentSheet(_ route: Route) {
        presentedSheet = route
    }

    func popToRoot() {
        currentPath.wrappedValue = NavigationPath()
    }
}
