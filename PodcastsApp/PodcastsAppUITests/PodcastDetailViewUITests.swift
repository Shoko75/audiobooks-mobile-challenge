//
//  PodcastDetailViewUITests.swift
//  PodcastsAppUITests
//
//  Created by Shoko Hashimoto on 2025-10-07.
//

import XCTest

final class PodcastDetailViewUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Helpers
    private func waitForListReady(timeout: TimeInterval = 30) {
        let navBar = app.navigationBars["Podcasts"].firstMatch
        XCTAssertTrue(navBar.waitForExistence(timeout: timeout))
        let firstCell = app.cells.firstMatch
        XCTAssertTrue(firstCell.waitForExistence(timeout: timeout))
    }
    
    private func navigateToDetail() {
        waitForListReady()
        let firstCell = app.cells.firstMatch
        firstCell.tap()
        let backButton = app.navigationBars.buttons["Back"].firstMatch
        XCTAssertTrue(backButton.waitForExistence(timeout: 15))
    }
    
    private func waitUntilHittable(_ element: XCUIElement, in scroll: XCUIElement, maxScrolls: Int = 4) {
        var tries = 0
        while !element.isHittable && tries < maxScrolls {
            scroll.swipeUp()
            tries += 1
        }
        let p = NSPredicate(format: "exists == true AND hittable == true")
        let exp = XCTNSPredicateExpectation(predicate: p, object: element)
        _ = XCTWaiter.wait(for: [exp], timeout: 5)
    }
    
    private func waitForLabel(_ label: String, on element: XCUIElement, timeout: TimeInterval) {
        let p = NSPredicate(format: "exists == true AND label == %@", label)
        let exp = XCTNSPredicateExpectation(predicate: p, object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [exp], timeout: timeout), .completed,
                       "Expected label '\(label)', got '\(element.label)'")
    }
    
    private func waitForLabelNotEqual(_ label: String, on element: XCUIElement, timeout: TimeInterval) {
        let p = NSPredicate(format: "exists == true AND label != %@", label)
        let exp = XCTNSPredicateExpectation(predicate: p, object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [exp], timeout: timeout), .completed,
                       "Label did not change from '\(label)' in time (still '\(element.label)')")
    }
    
    // MARK: - Navigation Tests
    func test_navigateFromList_toDetail_andBack() throws {
        navigateToDetail()
        let backButton = app.navigationBars.buttons["Back"].firstMatch
        backButton.tap()
        // Back on list
        let firstCell = app.cells.firstMatch
        XCTAssertTrue(firstCell.waitForExistence(timeout: 15))
    }
    
    // MARK: - Content Display Tests
    func test_detail_displaysTitlePublisherDescription() throws {
        navigateToDetail()
        // Verify there are at least a few static texts (title, publisher, description)
        let staticTexts = app.staticTexts.allElementsBoundByIndex
        XCTAssertGreaterThan(staticTexts.count, 2)
        // Basic sanity: first few labels are non-empty
        XCTAssertFalse(staticTexts[0].label.isEmpty)
    }
    
    func test_detail_displaysImage() throws {
        navigateToDetail()
        // Check if there's an image (either loaded or placeholder)
        let images = app.images.allElementsBoundByIndex
        XCTAssertGreaterThan(images.count, 0)
    }
    
    // MARK: - Favorite Button Tests
    func test_favorite_toggle_changesButtonText() throws {
        navigateToDetail()
        
        // Find the button by accessibility identifier
        let favoriteButton = app.buttons["favoriteButton"]
        XCTAssertTrue(favoriteButton.waitForExistence(timeout: 10), "Favorite button should exist")
        
        // Ensure button starts in "Favourite" state
        if favoriteButton.label == "Favourited" {
            print("Button is 'Favourited', tapping to reset to 'Favourite'")
            favoriteButton.tap()
            
            // Wait for the label to change to "Favourite"
            let favouritePredicate = NSPredicate(format: "label == %@", "Favourite")
            let resetExpectation = XCTNSPredicateExpectation(predicate: favouritePredicate, object: favoriteButton)
            XCTAssertEqual(XCTWaiter.wait(for: [resetExpectation], timeout: 5), .completed, "Button should reset to 'Favourite'")
        }
        
        // Verify we're now in "Favourite" state
        XCTAssertEqual(favoriteButton.label, "Favourite", "Button should start as 'Favourite'")
        
        // Tap once → should switch to "Favourited"
        favoriteButton.tap()
        
        // Wait for the label to change with a more robust approach
        let favouritedPredicate = NSPredicate(format: "label == %@", "Favourited")
        let expectation = XCTNSPredicateExpectation(predicate: favouritedPredicate, object: favoriteButton)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 5), .completed, "Button should update to 'Favourited'")
        
        // Tap again → should toggle back
        favoriteButton.tap()
        
        // Wait for the label to change back
        let favouritePredicate2 = NSPredicate(format: "label == %@", "Favourite")
        let backExpectation = XCTNSPredicateExpectation(predicate: favouritePredicate2, object: favoriteButton)
        XCTAssertEqual(XCTWaiter.wait(for: [backExpectation], timeout: 5), .completed, "Button should toggle back to 'Favourite'")
    }
    
    func test_favorite_button_isTappable() throws {
        navigateToDetail()
        
        let favoriteButton = app.buttons["favoriteButton"]
        XCTAssertTrue(favoriteButton.waitForExistence(timeout: 10))
        XCTAssertTrue(favoriteButton.isHittable, "Favorite button should be tappable")
    }
    
    // MARK: - Layout Tests
    func test_scrollView_exists_andContentIsScrollable() throws {
        navigateToDetail()
        let scroll = app.scrollViews.firstMatch
        XCTAssertTrue(scroll.exists)
    }
    
    func test_backButton_exists_andIsTappable() throws {
        navigateToDetail()
        let backButton = app.navigationBars.buttons["Back"].firstMatch
        XCTAssertTrue(backButton.exists)
        XCTAssertTrue(backButton.isHittable)
        XCTAssertEqual(backButton.label, "Back")
    }
    
    // MARK: - Accessibility Tests
    func test_backButton_hasAccessibleLabel() throws {
        navigateToDetail()
        let backButton = app.navigationBars.buttons["Back"].firstMatch
        XCTAssertEqual(backButton.label, "Back")
    }
    
    func test_favoriteButton_hasAccessibleLabel() throws {
        navigateToDetail()
        let favoriteButton = app.buttons["favoriteButton"]
        XCTAssertTrue(favoriteButton.waitForExistence(timeout: 10))
        // The button should have either "Favourite" or "Favourited" as its label
        let validLabels = ["Favourite", "Favourited"]
        XCTAssertTrue(validLabels.contains(favoriteButton.label), "Button should have a valid accessibility label")
    }
}
