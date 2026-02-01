//
//  MapTrackingViewModel.swift
//  thecoffeelinks-client-ios
//
//  Live delivery tracking with MapKit
//

import Foundation
import CoreLocation
import Combine

@MainActor
final class MapTrackingViewModel: ObservableObject {
    @Published var tracking: DeliveryTracking?
    @Published var driverLocation: CLLocationCoordinate2D?
    @Published var deliveryAddress: CLLocationCoordinate2D?
    @Published var storeLocation: CLLocationCoordinate2D?
    @Published var routeCoordinates: [CLLocationCoordinate2D] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let orderId: String
    private let deliveryRepository: DeliveryRepositoryProtocol
    private let locationService: LocationServiceProtocol
    private var refreshTask: Task<Void, Never>?
    
    init(orderId: String, deliveryRepository: DeliveryRepositoryProtocol, locationService: LocationServiceProtocol) {
        self.orderId = orderId
        self.deliveryRepository = deliveryRepository
        self.locationService = locationService
    }
    
    var driverName: String { tracking?.driverName ?? "Driver" }
    var driverPhone: String? { tracking?.driverPhone }
    var statusText: String { tracking?.status.displayName ?? "Tracking..." }
    var estimatedArrival: String? {
        guard let eta = tracking?.estimatedArrival else { return nil }
        let formatter = DateFormatter(); formatter.timeStyle = .short
        return formatter.string(from: eta)
    }
    var isDelivered: Bool { tracking?.status == .delivered }
    
    func startTracking() async {
        isLoading = true
        await loadTracking()
        startAutoRefresh()
        isLoading = false
    }
    
    func stopTracking() { 
        refreshTask?.cancel()
        refreshTask = nil 
    }
    
    private func loadTracking() async {
        do {
            tracking = try await deliveryRepository.getDeliveryTracking(orderId: orderId)
            if let location = tracking?.currentLocation {
                driverLocation = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            }
            updateRoute()
        } catch { self.error = error }
    }
    
    private func startAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            let refreshInterval: UInt64 = 10_000_000_000 // 10 seconds in nanoseconds
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: refreshInterval)
                guard let self = self, !Task.isCancelled else { break }
                await self.loadTracking()
            }
        }
    }
    
    private func updateRoute() {
        guard let driver = driverLocation, let destination = deliveryAddress else { routeCoordinates = []; return }
        routeCoordinates = [driver, destination]
    }
    
    func callDriver() {
        guard let phone = driverPhone, let url = URL(string: "tel://\(phone)") else { return }
        // UIApplication.shared.open(url)
    }
    
    func messageDriver() {
        guard let phone = driverPhone, let url = URL(string: "sms:\(phone)") else { return }
        // UIApplication.shared.open(url)
    }
}
