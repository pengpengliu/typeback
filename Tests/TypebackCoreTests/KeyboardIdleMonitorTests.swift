import XCTest
@testable import TypebackCore

@MainActor
final class KeyboardIdleMonitorTests: XCTestCase {
    func testStartSchedulesInitialIdleTimer() {
        let scheduler = ManualIdleTimerScheduler()
        let events = ManualKeyboardEventMonitor()
        let monitor = KeyboardIdleMonitor(
            idleSeconds: 10,
            timerScheduler: scheduler,
            eventMonitor: events
        )

        monitor.start(onIdle: {})

        XCTAssertTrue(monitor.isRunning)
        XCTAssertTrue(events.isStarted)
        XCTAssertEqual(scheduler.scheduledIntervals, [10])
    }

    func testKeyboardActivityReschedulesIdleTimer() {
        let scheduler = ManualIdleTimerScheduler()
        let events = ManualKeyboardEventMonitor()
        let monitor = KeyboardIdleMonitor(
            idleSeconds: 10,
            timerScheduler: scheduler,
            eventMonitor: events
        )

        monitor.start(onIdle: {})
        events.sendKeyDown()

        XCTAssertTrue(scheduler.timers[0].isCancelled)
        XCTAssertEqual(scheduler.scheduledIntervals, [10, 10])
    }

    func testIdleTimerFiresCallback() {
        let scheduler = ManualIdleTimerScheduler()
        let events = ManualKeyboardEventMonitor()
        let monitor = KeyboardIdleMonitor(
            idleSeconds: 10,
            timerScheduler: scheduler,
            eventMonitor: events
        )
        var idleFireCount = 0

        monitor.start {
            idleFireCount += 1
        }
        scheduler.timers[0].fire()

        XCTAssertEqual(idleFireCount, 1)
    }

    func testStopCancelsTimerAndEventMonitor() {
        let scheduler = ManualIdleTimerScheduler()
        let events = ManualKeyboardEventMonitor()
        let monitor = KeyboardIdleMonitor(
            idleSeconds: 10,
            timerScheduler: scheduler,
            eventMonitor: events
        )
        var idleFireCount = 0

        monitor.start {
            idleFireCount += 1
        }
        monitor.stop()
        scheduler.timers[0].fire()

        XCTAssertFalse(monitor.isRunning)
        XCTAssertFalse(events.isStarted)
        XCTAssertTrue(scheduler.timers[0].isCancelled)
        XCTAssertEqual(idleFireCount, 0)
    }

    func testUpdatingIdleSecondsWhileRunningReschedulesTimer() {
        let scheduler = ManualIdleTimerScheduler()
        let events = ManualKeyboardEventMonitor()
        let monitor = KeyboardIdleMonitor(
            idleSeconds: 10,
            timerScheduler: scheduler,
            eventMonitor: events
        )

        monitor.start(onIdle: {})
        monitor.updateIdleSeconds(30)

        XCTAssertTrue(scheduler.timers[0].isCancelled)
        XCTAssertEqual(scheduler.scheduledIntervals, [10, 30])
    }
}

@MainActor
private final class ManualKeyboardEventMonitor: KeyboardEventMonitoring {
    private var onKeyDown: (() -> Void)?
    private(set) var isStarted = false

    func start(onKeyDown: @escaping () -> Void) {
        self.onKeyDown = onKeyDown
        isStarted = true
    }

    func stop() {
        onKeyDown = nil
        isStarted = false
    }

    func sendKeyDown() {
        onKeyDown?()
    }
}

@MainActor
private final class ManualIdleTimerScheduler: IdleTimerScheduling {
    private(set) var scheduledIntervals: [TimeInterval] = []
    private(set) var timers: [ManualIdleTimer] = []

    func schedule(after interval: TimeInterval, action: @escaping () -> Void) -> CancellableIdleTimer {
        scheduledIntervals.append(interval)
        let timer = ManualIdleTimer(action: action)
        timers.append(timer)
        return timer
    }
}

@MainActor
private final class ManualIdleTimer: CancellableIdleTimer {
    private let action: () -> Void
    private(set) var isCancelled = false

    init(action: @escaping () -> Void) {
        self.action = action
    }

    func cancel() {
        isCancelled = true
    }

    func fire() {
        guard !isCancelled else { return }
        action()
    }
}
