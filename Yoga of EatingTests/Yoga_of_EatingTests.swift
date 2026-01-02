#if canImport(XCTest)
//
    //  Yoga_of_EatingTests.swift
    //  Yoga of EatingTests
//
    //  Created by Sunil Pawar on 25/12/25.
//
    //  NOTE: This is the main test file. All other test files in the "Yoga of EatingTests" target
    //  are automatically discovered by XCTest. Test files include:
    //  - MainViewModelTests.swift
    //  - MainViewModelAIAnalysisTests.swift
    //  - AILogicServiceTests.swift
    //  - AuthServiceTests.swift
    //  - SensoryServiceTests.swift
    //  - MealTests.swift
    //  - PersistenceServiceTests.swift
    //  - SmileyViewTests.swift
    //  - MealLogicTests.swift
    //  - NotificationManagerTests.swift

    import XCTest
    @testable import Yoga_of_Eating

    final class Yoga_of_EatingTests: XCTestCase {
        override func setUpWithError() throws {
            // Put setup code here. This method is called before the invocation of each test method in the class.
        }

        override func tearDownWithError() throws {
            // Put teardown code here. This method is called after the invocation of each test method in the class.
        }

        func testExample() throws {
            // This is an example of a functional test case.
            // Use XCTAssert and related functions to verify your tests produce the correct results.
            // Any test you write for XCTest can be annotated as throws and async.
            // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
            // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with
            // assertions afterwards.
        }

        func testPerformanceExample() throws {
            // This is an example of a performance test case.
            measure {
                // Put the code you want to measure the time of here.
            }
        }
    }

#endif
