# SalahStreak – Detailed Project Plan (iOS & watchOS)

**Project:** SalahStreak  
**Platforms:** iOS 18+, watchOS 11+  
**Tech Stack:** Swift 6, SwiftUI, SwiftData, Adhan, UserNotifications  
**Architecture:** MVVM \+ Coordinator  
**Persistence:** SwiftData (CloudKit enabled, local-first MVP)  
**Status:** Ready for Execution

---

## 0\. Guiding Principles (Non-Negotiables)

- **Offline-first:** No backend, no APIs in MVP  
- **Privacy-first:** All logic and data remain on-device  
- **Action-oriented:** Notifications are tasks, not FYIs  
- **Frictionless:** Marking prayer should take ≤1 tap  
- **Future-proof:** Schema must support Qada, travel, analytics  
- **Apple-native:** Behave like a system app, not a web wrapper

---

## 1\. High-Level Architecture

### Core Domains

- **Time & Prayer Engine** → Adhan-based calculation  
- **Persistence Layer** → SwiftData models  
- **Notification Engine** → Smart cascade scheduling  
- **Streak & Gamification Engine**  
- **UI Layer** → Dashboard, badges, charts  
- **Extensions** → Widgets & Watch app

### Data Ownership

- `PrayerEntry` \= single source of historical truth  
- `DailyLog` \= aggregation, streak, UI grouping  
- `UserStats` \= derived & cached stats

---

## 2\. Data Model Design (FOUNDATIONAL)

### 2.1 Enums (Lock These First)

enum PrayerType { fajr, dhuhr, asr, maghrib, isha }

enum PrayerStatus { pending, done, missed, qada }

enum EntrySource { app, notification, widget, watch }

### **2.2 SwiftData Models**

#### **DailyLog**

* `date: Date` (start-of-day, unique)  
* `entries: [PrayerEntry]` (relationship)  
* `isPerfect: Bool` (derived or cached)  
* `streakProtected: Bool` (freeze used)  
* `createdAt: Date`

**Responsibilities**

* Determine daily completion (5/5)  
* Trigger streak increment or freeze consumption  
* Power “Today” UI grouping

---

#### **PrayerEntry**

* `id: UUID`  
* `prayer: PrayerType`  
* `scheduledDate: Date`  
* `windowStart: Date`  
* `windowEnd: Date`  
* `performedAt: Date?`  
* `status: PrayerStatus`  
* `source: EntrySource`  
* `latitude: Double?` (future)  
* `longitude: Double?` (future)

**Responsibilities**

* Notification lifecycle  
* Widget / Watch updates  
* Analytics & dashboards  
* Qada support (v2)

---

#### **UserStats**

* `currentStreak: Int`  
* `bestStreak: Int`  
* `freezesAvailable: Int`  
* `totalPrayers: Int`  
* `badgesUnlocked: Set<BadgeID>`

---

## **3\. Milestone Breakdown**

---

## **Milestone 1: Project Setup & Skeleton (Week 1\)**

### **Goals**

* App compiles  
* Data layer finalized  
* Navigation structure ready

### **Tasks**

* Create Xcode project (iOS \+ watchOS targets)  
* Enable:  
  * Swift 6 strict concurrency  
  * SwiftData \+ CloudKit container  
* Define all enums  
* Implement SwiftData models  
* Set up Coordinator pattern  
* Build empty shell views:  
  * Dashboard  
  * Badges  
  * Stats  
  * Settings  
* Add dependency: Adhan

**Exit Criteria**

* App launches  
* Models persist & query correctly  
* Navigation works

---

## **Milestone 2: Prayer Time Engine (Week 1–2)**

### **Goals**

* Correct daily prayer windows  
* Location & calculation ready

### **Tasks**

* Integrate Adhan:  
  * Calculation method  
  * Madhab selection  
* Location strategy:  
  * MVP: Auto-GPS OR manual city  
* Build `PrayerScheduleService`  
  * Generates today’s prayer times  
  * Computes windowStart / windowEnd  
* Create or fetch `DailyLog` on app launch  
* Auto-create 5 `PrayerEntry` objects per day

**Edge Cases**

* Day rollover at midnight  
* Timezone changes  
* DST changes

**Exit Criteria**

* Today’s prayers render with correct times  
* Windows update correctly day-to-day

---

## **Milestone 3: Smart Notification Engine (Week 2\)**

### **Goals**

* Core differentiator working perfectly

### **Tasks**

* Implement Notification categories:  
  * `Mark Done`  
  * `Snooze 20m`  
* Implement Smart Cascade Algorithm:  
  * Adhan  
  * 25%  
  * 50%  
  * 85% / 30-min rule  
* Tag notifications by:  
  * prayer  
  * date  
* Handle actions:  
  * Mark Done → update PrayerEntry \+ cancel pending  
  * Snooze → schedule one-off reminder  
* Re-schedule notifications daily at Fajr or midnight

**Critical Rules**

* No duplicate notifications  
* No notifications after prayer marked done  
* No notifications past window end

**Exit Criteria**

* Notifications behave reliably across all prayers  
* Actions correctly mutate DB

---

## **Milestone 4: Dashboard & Core UI (Week 2–3)**

### **Goals**

* Daily interaction loop complete

### **Tasks**

* Build “Today” dashboard:  
  * 5 prayer cards  
* Card states:  
  * `.future`  
  * `.active`  
  * `.warning`  
  * `.done`  
  * `.missed`  
* Tap to mark done  
* Visual feedback:  
  * Pulse for active  
  * Green for done  
  * Red for missed  
* Bottom sheet:  
  * Today’s completion summary

**Exit Criteria**

* User can complete full day without friction  
* Visual state matches data truth

---

## **Milestone 5: Streak Engine & Freezes (Week 3\)**

### **Goals**

* Habit-forming mechanics locked in

### **Tasks**

* Implement Streak Engine:  
  * Increment only on perfect day  
  * Detect missed day  
* Freeze logic:  
  * \+1 freeze every 7 perfect days  
  * Auto-consume on missed day  
* Update UserStats accordingly  
* Build streak flame UI  
* Persist best streak

**Exit Criteria**

* Streak behaves predictably  
* Freeze logic is automatic & invisible

---

## **Milestone 6: Gamification Layer (Week 3–4)**

### **Goals**

* Motivation & reward systems live

### **Tasks**

* Implement Simulated Ummah stats:  
  * Trigger-based injection  
  * Toast / modal presentation  
* Badge Engine:  
  * Define badge conditions  
  * Unlock detection  
* Badge UI:  
  * Grid layout  
  * Locked vs unlocked visuals  
* Total prayers counter

**Exit Criteria**

* User feels rewarded after actions  
* Badges unlock correctly

---

## **Milestone 7: Charts & Analytics (Week 4\)**

### **Goals**

* Visual feedback loop

### **Tasks**

* Weekly activity chart (Swift Charts)  
* Queries:  
  * Prayers per day  
  * Missed vs done  
* Prep structure for future dashboards

**Exit Criteria**

* Charts render fast and correctly

---

## **Milestone 8: Widgets (Week 5\)**

### **Goals**

* Zero-friction completion

### **Tasks**

* Home Screen widget:  
  * Current prayer  
  * Ends at time  
  * Interactive “Mark Done”  
* Lock Screen widgets:  
  * Inline text  
  * Circular progress  
* Timeline refresh logic  
* Battery-safe updates (no timers)

**Exit Criteria**

* Marking from widget updates DB instantly  
* Widget always reflects correct prayer

---

## **Milestone 9: Apple Watch App (Week 5\)**

### **Goals**

* Ultra-fast utility

### **Tasks**

* Watch app target  
* Sync logic (shared container / CloudKit)  
* Main screen:  
  * Current prayer  
  * Giant “Mark Done” button  
* Complication:  
  * Prayer name \+ time left

**Exit Criteria**

* Watch works without opening iPhone app

---

## **Milestone 10: Onboarding, Polish & Review Prep (Week 5–6)**

### **Goals**

* Ship-ready MVP

### **Tasks**

* 3-step onboarding:  
  * Location  
  * Madhab  
  * Goal  
* Haptics & sounds  
* Error handling  
* Accessibility pass  
* App Store compliance review:  
  * Notification wording  
  * Religious sensitivity  
* Test edge cases:  
  * Travel  
  * Missed days  
  * Timezone changes

**Exit Criteria**

* App feels premium  
* No blocking App Store risks

---

## **4\. Post-MVP Hooks (Not Built, But Supported)**

* Qada calculator  
* Cloud sync toggle  
* Social features (opt-in)  
* Advanced analytics  
* Multiple madhabs per prayer

---

## **5\. Definition of “MVP Done”**

* User completes prayers via notifications, widget, or watch  
* Streaks & freezes work correctly  
* Badges unlock  
* App runs offline for weeks without breaking  
* No schema migration needed for v2

---

**Status:** 🚀 Ready to build

