//
//  KIMERO_OKUSURI_CALENDARUITestsLaunchTests.swift
//  KIMERO_OKUSURI_CALENDARUITests
//
//  Created by clark on 2025/06/30.
//

import XCTest

final class KIMERO_OKUSURI_CALENDARUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
