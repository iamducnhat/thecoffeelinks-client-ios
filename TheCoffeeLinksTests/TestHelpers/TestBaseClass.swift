//
//  TestBaseClass.swift
//  TheCoffeeLinksTests
//
//  Base class for all tests with common setup and utilities
//

import XCTest
import Combine
@testable import TheCoffeeLinks

class TestBaseClass: XCTestCase {
    
    // MARK: - Properties
    
    var cancellables: Set<AnyCancellable>!
    var mockNetworkService: MockNetworkService!
    var mockKeychainManager: MockKeychainManager!
    var mockUserDefaults: MockUserDefaults!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
        mockNetworkService = MockNetworkService()
        mockKeychainManager = MockKeychainManager()
        mockUserDefaults = MockUserDefaults()
        
        // Reset UserDefaults for each test
        resetUserDefaults()
    }
    
    override func tearDown() {
        super.tearDown()
        cancellables = nil
        mockNetworkService = nil
        mockKeychainManager = nil
        mockUserDefaults = nil
        
        // Clean up UserDefaults
        resetUserDefaults()
    }
    
    // MARK: - Utilities
    
    func resetUserDefaults() {
        let keys = [
            "auth_session",
            "isOnboardingCompleted",
            "isInitialSetupCompleted",
            "isPhoneVerified_cached"
        ]
        
        for key in keys {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
    
    func waitForPublisher<T: Publisher>(
        _ publisher: T,
        timeout: TimeInterval = 1.0,
        file: StaticString = #file,
        line: UInt = #line
    ) throws -> T.Output {
        var result: Result<T.Output, Error>?
        let expectation = self.expectation(description: "Publisher expectation")
        
        publisher
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        result = .failure(error)
                    }
                    expectation.fulfill()
                },
                receiveValue: { value in
                    result = .success(value)
                }
            )
            .store(in: &cancellables)
        
        waitForExpectations(timeout: timeout)
        
        let unwrappedResult = try XCTUnwrap(
            result,
            "Publisher did not emit any value",
            file: file,
            line: line
        )
        
        return try unwrappedResult.get()
    }
    
    func expectAsync<T>(
        _ expression: @escaping () async throws -> T,
        timeout: TimeInterval = 2.0,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    let result = try await expression()
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func assertMainThread(file: StaticString = #file, line: UInt = #line) {
        XCTAssertTrue(
            Thread.isMainThread,
            "Expected to be on main thread",
            file: file,
            line: line
        )
    }
    
    // MARK: - Mock Setup Helpers
    
    func setupMockAuthSuccess() {
        let user = TestDataFactory.createUser()
        mockNetworkService.setMockResponse(for: "/api/auth/login", response: TestDataFactory.createAPIResponse(data: user))
    }
    
    func setupMockAuthFailure() {
        mockNetworkService.shouldFail = true
        mockNetworkService.failureError = NetworkError.unauthorized
    }
    
    func setupMockProductsSuccess() {
        let products = TestDataFactory.createProducts()
        mockNetworkService.setMockResponse(for: "/api/products", response: TestDataFactory.createAPIResponse(data: products))
    }
    
    func setupMockProductsFailure() {
        mockNetworkService.shouldFail = true
        mockNetworkService.failureError = NetworkError.networkFailure(URLError(.notConnectedToInternet))
    }
}

// MARK: - Performance Testing

extension TestBaseClass {
    
    func measureAsync<T>(
        _ block: @escaping () async throws -> T,
        iterations: Int = 5,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        measure {
            let expectation = XCTestExpectation(description: "Async operation")
            
            Task {
                do {
                    _ = try await block()
                    expectation.fulfill()
                } catch {
                    XCTFail("Async operation failed: \(error)", file: file, line: line)
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
}

// MARK: - Assertion Helpers

extension XCTestCase {
    
    func XCTAssertThrowsErrorAsync<T>(
        _ expression: @autoclosure () async throws -> T,
        _ errorHandler: (Error) -> Void = { _ in },
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        do {
            _ = try await expression()
            XCTFail("Expected error to be thrown", file: file, line: line)
        } catch {
            errorHandler(error)
        }
    }
    
    func XCTAssertNoThrowAsync<T>(
        _ expression: @autoclosure () async throws -> T,
        file: StaticString = #file,
        line: UInt = #line
    ) async -> T? {
        do {
            return try await expression()
        } catch {
            XCTFail("Unexpected error thrown: \(error)", file: file, line: line)
            return nil
        }
    }
    
    func XCTAssertEventuallyTrue(
        _ condition: @autoclosure @escaping () -> Bool,
        timeout: TimeInterval = 1.0,
        message: String = "",
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(block: { _, _ in condition() }),
            object: nil
        )
        
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        
        if result != .completed {
            XCTFail("Condition was not met within timeout: \(message)", file: file, line: line)
        }
    }
}