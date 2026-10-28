import XCTest
@testable import TypebackCore

@MainActor
final class PreferencesStoreTests: XCTestCase {
    private var defaultsSuiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaultsSuiteName = "TypebackTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: defaultsSuiteName)
        defaults.removePersistentDomain(forName: defaultsSuiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: defaultsSuiteName)
        defaults = nil
        defaultsSuiteName = nil
        super.tearDown()
    }

    func testDefaultPreferencesUseEnabledTenSecondsABCAndLaunchAtLoginDisabled() {
        let store = PreferencesStore(defaults: defaults)

        XCTAssertTrue(store.enabled)
        XCTAssertEqual(store.idleSeconds, 10)
        XCTAssertEqual(store.targetInputSourceID, "com.apple.keylayout.ABC")
        XCTAssertFalse(store.launchAtLogin)
    }

    func testIdleSecondsAreClampedToSupportedRange() {
        let store = PreferencesStore(defaults: defaults)

        store.setIdleSeconds(-10)
        XCTAssertEqual(store.idleSeconds, 1)

        store.setIdleSeconds(0)
        XCTAssertEqual(store.idleSeconds, 1)

        store.setIdleSeconds(7200)
        XCTAssertEqual(store.idleSeconds, 3600)
    }

    func testPreferencesPersistAcrossStoreInstances() {
        let firstStore = PreferencesStore(defaults: defaults)

        firstStore.setEnabled(false)
        firstStore.setIdleSeconds(30)
        firstStore.setTargetInputSourceID("com.example.input")
        firstStore.setLaunchAtLogin(true)

        let secondStore = PreferencesStore(defaults: defaults)

        XCTAssertFalse(secondStore.enabled)
        XCTAssertEqual(secondStore.idleSeconds, 30)
        XCTAssertEqual(secondStore.targetInputSourceID, "com.example.input")
        XCTAssertTrue(secondStore.launchAtLogin)
    }

}
