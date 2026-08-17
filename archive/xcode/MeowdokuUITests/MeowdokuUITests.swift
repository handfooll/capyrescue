//
//  MeowdokuUITests.swift
//  MeowdokuUITests
//
//  Created by the god unkn0wn on 2026/8/17.
//

import XCTest

final class MeowdokuUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    /// The accessibility snapshot XCUITest reads can lag a moment behind a
    /// completed gesture (worse for a lone tap, which also has to wait out
    /// SwiftUI's double-tap disambiguation window) - poll instead of
    /// asserting immediately after any tap.
    @MainActor
    private func waitForLabel(_ label: String, on element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "label == %@", label)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }

    @MainActor
    func testSingleTapTogglesAMark() throws {
        let app = XCUIApplication()
        app.launch()

        let cell = app.descendants(matching: .any)["cell-0-0"]
        XCTAssertTrue(cell.waitForExistence(timeout: 5))
        XCTAssertEqual(cell.label, "empty")

        cell.tap()
        XCTAssertTrue(waitForLabel("marked", on: cell))

        cell.tap()
        XCTAssertTrue(waitForLabel("empty", on: cell))
    }

    @MainActor
    func testDoubleTapTogglesACat() throws {
        let app = XCUIApplication()
        app.launch()

        let cell = app.descendants(matching: .any)["cell-0-0"]
        XCTAssertTrue(cell.waitForExistence(timeout: 5))

        cell.doubleTap()
        XCTAssertTrue(waitForLabel("cat", on: cell))

        cell.doubleTap()
        XCTAssertTrue(waitForLabel("empty", on: cell))
    }

    @MainActor
    func testNewPuzzleReplacesTheBoard() throws {
        let app = XCUIApplication()
        app.launch()

        let cell = app.descendants(matching: .any)["cell-0-0"]
        XCTAssertTrue(cell.waitForExistence(timeout: 5))
        cell.doubleTap()
        XCTAssertTrue(waitForLabel("cat", on: cell))

        app.buttons["New Puzzle"].tap()
        XCTAssertTrue(waitForLabel("empty", on: cell))
    }

    @MainActor
    func testHintPlacesACat() throws {
        let app = XCUIApplication()
        app.launch()

        let firstCell = app.descendants(matching: .any)["cell-0-0"]
        XCTAssertTrue(firstCell.waitForExistence(timeout: 5))

        // The real puzzle is randomly generated each launch, so we can't predict
        // which cell the hint lands on - only that exactly one cat appears.
        let catCells = app.descendants(matching: .any).matching(NSPredicate(format: "label == 'cat'"))
        XCTAssertEqual(catCells.count, 0)

        app.buttons["Hint"].tap()

        let predicate = NSPredicate(format: "count == 1")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: catCells)
        XCTAssertEqual(XCTWaiter().wait(for: [expectation], timeout: 5), .completed)
    }

    @MainActor
    func testBoardSizePickerResizesTheGrid() throws {
        let app = XCUIApplication()
        app.launch()

        // Default is 6x6: row/col 5 exists, row/col 6 doesn't.
        XCTAssertTrue(app.descendants(matching: .any)["cell-5-5"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.descendants(matching: .any)["cell-6-6"].exists)

        app.buttons["4×4"].tap()

        let cell33 = app.descendants(matching: .any)["cell-3-3"]
        XCTAssertTrue(cell33.waitForExistence(timeout: 5))
        XCTAssertFalse(app.descendants(matching: .any)["cell-4-4"].exists)
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
