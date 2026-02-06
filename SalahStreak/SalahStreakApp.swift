//
//  SalahStreakApp.swift
//  SalahStreak
//
//  Created by Danial Zahid on 2026-02-05.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct SalahStreakApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            PrayerEntry.self,
            DailyLog.self,
            UserStats.self,
            UserSettings.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: - RootView (onboarding gate)

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allStats: [UserStats]

    private var hasCompletedOnboarding: Bool {
        allStats.first?.hasCompletedOnboarding ?? false
    }

    var body: some View {
        if hasCompletedOnboarding {
            MainTabView()
        } else {
            OnboardingContainerView()
        }
    }
}

// MARK: - MainTabView

struct MainTabView: View {
    @State private var coordinator = MainTabCoordinator()

    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            Tab("Today", systemImage: "sun.max", value: 0) {
                NavigationStack(path: $coordinator.dashboardPath) {
                    DashboardView()
                }
            }
            Tab("Badges", systemImage: "star", value: 1) {
                NavigationStack(path: $coordinator.badgesPath) {
                    BadgesView()
                }
            }
            Tab("Stats", systemImage: "chart.bar", value: 2) {
                NavigationStack(path: $coordinator.statsPath) {
                    StatsView()
                }
            }
            Tab("Settings", systemImage: "gearshape", value: 3) {
                NavigationStack(path: $coordinator.settingsPath) {
                    SettingsView()
                }
            }
        }
        .tabViewStyle(.automatic)
        .environment(coordinator)
    }
}

// MARK: - AppDelegate (notification handling)

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        (DependencyContainer.shared.notificationService as? NotificationService)?.registerCategories()
        return true
    }

    // MARK: - Foreground notifications

    func userNotificationCenter(_ center: UNUserNotificationCenter, willShow notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }

    // MARK: - Action handling

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo  = response.notification.request.content.userInfo
        let prayerRaw = userInfo["prayer"] as? String

        switch response.actionIdentifier {
        case "MARK_DONE":
            if let raw = prayerRaw, let prayer = PrayerType(rawValue: raw) {
                markPrayerDoneFromNotification(prayer)
            }
        case "SNOOZE":
            if let raw = prayerRaw, let prayer = PrayerType(rawValue: raw) {
                snoozePrayer(prayer, minutes: 20)
            }
        default:
            break
        }
        completionHandler()
    }

    // MARK: - Helpers

    private func markPrayerDoneFromNotification(_ prayer: PrayerType) {
        // Performed on background — SwiftData context must be created on main
        DispatchQueue.main.async {
            guard let container = try? ModelContainer(for: PrayerEntry.self, DailyLog.self, UserStats.self, UserSettings.self) else { return }
            let context = ModelContext(container)
            let today   = Calendar.current.startOfDay(for: Date())

            let logDesc = FetchDescriptor<DailyLog>(predicate: #Predicate { $0.date == today })
            guard let log = try? context.fetch(logDesc).first,
                  let entry = log.safeEntries.first(where: { $0.prayer == prayer && $0.status == .pending }) else { return }

            entry.status     = .done
            entry.performedAt = Date()
            entry.source     = .notification

            let statsDesc = FetchDescriptor<UserStats>()
            if let stats = try? context.fetch(statsDesc).first {
                stats.totalPrayers += 1
            }

            DependencyContainer.shared.notificationService.cancelNotifications(for: prayer, on: today)
            try? context.save()
        }
    }

    private func snoozePrayer(_ prayer: PrayerType, minutes: Int) {
        let fireAt = Date().addingTimeInterval(Double(minutes * 60))
        let content = UNMutableNotificationContent()
        content.title = "SalahStreak"
        content.body  = "Reminder: \(prayer.displayName) prayer is waiting."
        content.sound = .default
        content.categoryIdentifier = "PRAYER_REMINDER"
        content.userInfo = ["prayer": prayer.rawValue]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: fireAt.timeIntervalSinceNow, repeats: false)
        let request = UNNotificationRequest(identifier: "\(prayer.rawValue)_snooze", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
