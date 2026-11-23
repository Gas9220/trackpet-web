import XCTest

/// The website's iPhone screenshots: a throwaway UI test, never committed to Trackpet.
/// `take-screenshots.sh` copies it into TrackpetUITests for one run and takes it out again.
///
/// It opens each screen with the app's sample data and attaches a screenshot of it named as
/// `make-images.sh` expects ("01-pets"), which the script exports. Every element is found by its
/// accessibility identifier, never by its text, so the same test runs in every language: the
/// language and region come from the script, as `TEST_RUNNER_LANGUAGE` and `TEST_RUNNER_REGION`.
/// The appearance is the simulator's, set by the script before each run.
nonisolated final class TrackpetScreenshots: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }
}

@MainActor
extension TrackpetScreenshots {
    func testWebsiteScreenshots() {
        let environment = ProcessInfo.processInfo.environment
        let language = environment["LANGUAGE"] ?? "en"
        let region = environment["REGION"] ?? "en_GB"

        let app = XCUIApplication()
        app.launchArguments = [
            "-ui-testing", "-sample-data",
            "-AppleLanguages", "(\(language))", "-AppleLocale", region,
        ]
        app.launch()

        // 01: the list.
        let paco = app.buttons["pets.row.Paco"]
        XCTAssertTrue(paco.waitForExistence(timeout: 30))
        snap("01-pets")

        // 02: Paco's page, its records.
        paco.tap()
        let weights = app.buttons["petDetail.weights"]
        XCTAssertTrue(weights.waitForExistence(timeout: 10))
        snap("02-pet")

        // 03: his weights over a year.
        weights.tap()
        let period = app.segmentedControls["weights.period"]
        XCTAssertTrue(period.waitForExistence(timeout: 10))
        // 1 Week, 1 Month, 3 Months, 6 Months, 1 Year, All: the year.
        period.buttons.element(boundBy: 4).tap()
        snap("03-weights")
        back(in: app)

        // 04: his vaccinations, the boosters first.
        openRecord("petDetail.vaccinations", in: app)
        XCTAssertTrue(app.buttons.matching(identifier: "vaccinations.row").firstMatch.waitForExistence(timeout: 10))
        snap("04-vaccinations")
        back(in: app)

        // 05: the therapy for his fever, with this morning's dose given.
        openRecord("petDetail.therapies", in: app)
        let therapy = app.buttons["therapies.row"].firstMatch
        XCTAssertTrue(therapy.waitForExistence(timeout: 10))
        therapy.tap()
        let dose = app.buttons.matching(identifier: "therapyDetail.dose").firstMatch
        XCTAssertTrue(dose.waitForExistence(timeout: 10))
        if !dose.isSelected {
            dose.tap()
        }
        XCTAssertTrue(waitUntil { dose.isSelected })
        snap("05-therapy")
        back(in: app)
        back(in: app)

        // 07: his documents, by year.
        openRecord("petDetail.documents", in: app)
        XCTAssertTrue(app.buttons["documents.row"].firstMatch.waitForExistence(timeout: 10))
        snap("07-documents")
        back(in: app)

        back(in: app)

        // 08: Harry's costs, over three years.
        let harry = app.buttons["pets.row.Harry"]
        XCTAssertTrue(harry.waitForExistence(timeout: 10))
        harry.tap()
        openRecord("petDetail.costs", in: app)
        XCTAssertTrue(app.descendants(matching: .any)["costs.total"].waitForExistence(timeout: 10))
        snap("08-costs")
        back(in: app)
        back(in: app)

        // 10: Settings, scrolled to the units and the app icons. 09: Clinica Veterinaria Rossi.
        app.buttons["pets.settings"].tap()
        let clinics = app.buttons["settings.clinics"]
        XCTAssertTrue(clinics.waitForExistence(timeout: 10))
        app.swipeUp(velocity: .slow)
        sleep(1)
        snap("10-settings")
        scroll(to: clinics, in: app)
        clinics.tap()
        let rossi = app.buttons.matching(NSPredicate(format: "identifier == 'clinics.row' AND label CONTAINS 'Rossi'")).firstMatch
        XCTAssertTrue(rossi.waitForExistence(timeout: 10))
        rossi.tap()
        XCTAssertTrue(app.descendants(matching: .any)["clinicDetail.phone"].waitForExistence(timeout: 10))
        snap("09-clinic")
        back(in: app)
        back(in: app)
        app.buttons["settings.close"].tap()

        // 06: the calendar, on today, with Paco's therapy and what else is on.
        let tabs = app.tabBars.buttons
        XCTAssertTrue(tabs.element(boundBy: 1).waitForExistence(timeout: 10))
        tabs.element(boundBy: 1).tap()
        XCTAssertTrue(app.buttons.matching(identifier: "calendar.item").firstMatch.waitForExistence(timeout: 10))
        snap("06-calendar")

        // 11, last, since Quick Look covers the app: Paco's health report, made in a few seconds
        // and opened.
        tabs.element(boundBy: 0).tap()
        XCTAssertTrue(paco.waitForExistence(timeout: 10))
        paco.tap()
        let report = app.buttons["petDetail.healthReport"]
        XCTAssertTrue(report.waitForExistence(timeout: 10))
        report.tap()
        XCTAssertTrue(waitUntil(timeout: 30) { !report.isHittable }, "Quick Look opened")
        sleep(3)  // Its pages drawn.
        snap("11-health-report")
    }

    /// Attaches what's on screen, kept after the test, named as `make-images.sh` expects.
    private func snap(_ name: String) {
        sleep(1)  // Animations settled, the keyboard and any banner gone.
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Opens one of the page's records rows, scrolled to first.
    private func openRecord(_ identifier: String, in app: XCUIApplication) {
        let row = app.buttons[identifier]
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        scroll(to: row, in: app)
        row.tap()
    }

    /// Back to the page before, with the back button on screen, whatever it's called.
    private func back(in app: XCUIApplication) {
        let buttons = app.navigationBars.buttons.matching(identifier: "BackButton")
        XCTAssertTrue(waitUntil(timeout: 10) { buttons.allElementsBoundByIndex.contains(where: \.isHittable) }, "A back button")
        buttons.allElementsBoundByIndex.first(where: \.isHittable)?.tap()
        sleep(1)
    }

    private func waitUntil(timeout: TimeInterval = 5, _ condition: @escaping () -> Bool) -> Bool {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in condition() }, object: nil)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }

    private func scroll(to element: XCUIElement, in app: XCUIApplication) {
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.45))
        for _ in 0..<16 where !(element.exists && element.isHittable) {
            start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.1)
        }
        XCTAssertTrue(element.isHittable, "\(element) is on screen")
    }
}
