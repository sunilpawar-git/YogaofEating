#if canImport(XCTest)
import XCTest
import UserNotifications

final class NotificationManagerTests: XCTestCase {
    var sut: NotificationManager!
    var mockCenter: MockNotificationCenter!
    
    override func setUp() {
        super.setUp()
        mockCenter = MockNotificationCenter()
        sut = NotificationManager(center: mockCenter)
    }
    
    override func tearDown() {
        sut = nil
        mockCenter = nil
        super.tearDown()
    }
    
    func test_scheduleMorningNudge_createsRequest() {
        sut.scheduleMorningNudge()
        
        XCTAssertEqual(mockCenter.requests.count, 1)
        let request = mockCenter.requests.first
        XCTAssertEqual(request?.content.title, "Good Morning!")
        XCTAssertTrue(request?.trigger is UNCalendarNotificationTrigger)
    }
    
    func test_scheduleMealReminder_createsRequest() {
        sut.scheduleMealReminder(for: .lunch, hour: 11, minute: 0)
        
        XCTAssertEqual(mockCenter.requests.count, 1)
        let request = mockCenter.requests.first
        XCTAssertEqual(request?.content.title, "Meal Time")
        XCTAssertTrue(request?.content.body.contains("lunch") ?? false)
    }
}

// Mock for UNUserNotificationCenter
class MockNotificationCenter: NotificationCenterProtocol {
    var requests: [UNNotificationRequest] = []
    
    func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: ((Error?) -> Void)?) {
        requests.append(request)
        completionHandler?(nil)
    }
    
    func requestAuthorization(options: UNAuthorizationOptions, completionHandler: @escaping (Bool, Error?) -> Void) {
        completionHandler(true, nil)
    }
    
    func removeAllPendingNotificationRequests() {
        requests.removeAll()
    }
}

#endif
