import AppKit
import Foundation

@MainActor
protocol KeyboardEventMonitoring: AnyObject {
    func start(onKeyDown: @escaping () -> Void)
    func stop()
}

@MainActor
protocol IdleTimerScheduling: AnyObject {
    func schedule(after interval: TimeInterval, action: @escaping () -> Void) -> CancellableIdleTimer
}

@MainActor
protocol CancellableIdleTimer: AnyObject {
    func cancel()
}

@MainActor
public final class KeyboardIdleMonitor {
    public private(set) var idleSeconds: Int
    public private(set) var isRunning = false

    private let timerScheduler: IdleTimerScheduling
    private let eventMonitor: KeyboardEventMonitoring
    private var idleTimer: CancellableIdleTimer?
    private var onIdle: (() -> Void)?

    public convenience init(idleSeconds: Int = TypebackPreferences.defaultIdleSeconds) {
        self.init(
            idleSeconds: idleSeconds,
            timerScheduler: TimerIdleScheduler(),
            eventMonitor: SystemKeyboardEventMonitor()
        )
    }

    init(
        idleSeconds: Int,
        timerScheduler: IdleTimerScheduling,
        eventMonitor: KeyboardEventMonitoring
    ) {
        self.idleSeconds = TypebackPreferences.clampedIdleSeconds(idleSeconds)
        self.timerScheduler = timerScheduler
        self.eventMonitor = eventMonitor
    }

    public func start(onIdle: @escaping () -> Void) {
        self.onIdle = onIdle

        if !isRunning {
            isRunning = true
            eventMonitor.start { [weak self] in
                self?.recordKeyboardActivity()
            }
        }

        scheduleIdleTimer()
    }

    public func stop() {
        idleTimer?.cancel()
        idleTimer = nil
        eventMonitor.stop()
        onIdle = nil
        isRunning = false
    }

    public func updateIdleSeconds(_ value: Int) {
        idleSeconds = TypebackPreferences.clampedIdleSeconds(value)

        if isRunning {
            scheduleIdleTimer()
        }
    }

    private func recordKeyboardActivity() {
        guard isRunning else { return }
        scheduleIdleTimer()
    }

    private func scheduleIdleTimer() {
        idleTimer?.cancel()
        idleTimer = timerScheduler.schedule(after: TimeInterval(idleSeconds)) { [weak self] in
            self?.fireIdle()
        }
    }

    private func fireIdle() {
        guard isRunning else { return }
        idleTimer = nil
        onIdle?()
    }
}

@MainActor
private final class SystemKeyboardEventMonitor: KeyboardEventMonitoring {
    private var globalMonitor: Any?
    private var localMonitor: Any?

    func start(onKeyDown: @escaping () -> Void) {
        stop()

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { _ in
            Task { @MainActor in
                onKeyDown()
            }
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            onKeyDown()
            return event
        }
    }

    func stop() {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }

        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
    }
}

@MainActor
private final class TimerIdleScheduler: IdleTimerScheduling {
    func schedule(after interval: TimeInterval, action: @escaping () -> Void) -> CancellableIdleTimer {
        let timer = Timer(timeInterval: interval, repeats: false) { _ in
            Task { @MainActor in
                action()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        return SystemIdleTimer(timer: timer)
    }
}

@MainActor
private final class SystemIdleTimer: CancellableIdleTimer {
    private let timer: Timer

    init(timer: Timer) {
        self.timer = timer
    }

    func cancel() {
        timer.invalidate()
    }
}
