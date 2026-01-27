//
//  DeliveryViewModel.swift
//  thecoffeelinks-client-ios
//
//  Delivery management with zone validation
//

import Foundation
import CoreLocation
import Combine

@MainActor
final class DeliveryViewModel: ObservableObject {
    @Published var savedAddresses: [DeliveryAddress] = []
    @Published var selectedAddress: DeliveryAddress?
    @Published var availability: DeliveryAvailability?
    @Published var zones: [DeliveryZone] = []
    @Published var searchResults: [AddressSearchResult] = []
    @Published var selectedLocation: CLLocationCoordinate2D?
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var isLoading = false
    @Published var isSearching = false
    @Published var error: Error?
    @Published var addressLabel = ""
    @Published var streetAddress = ""
    @Published var buildingInfo = ""
    @Published var city = "Ho Chi Minh City"
    @Published var district = ""
    
    private let deliveryRepository: DeliveryRepositoryProtocol
    private let locationService: LocationServiceProtocol
    private let storage: GenericStorageProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(deliveryRepository: DeliveryRepositoryProtocol, 
         locationService: LocationServiceProtocol,
         storage: GenericStorageProtocol = GenericStorage()) {
        self.deliveryRepository = deliveryRepository
        self.locationService = locationService
        self.storage = storage
        
        loadDraft()
        setupAutoSave()
    }
    
    // ... Computed properties ...
    var defaultAddress: DeliveryAddress? { savedAddresses.first { $0.isDefault } ?? savedAddresses.first }
    var isInDeliveryZone: Bool { availability?.available ?? false }
    var deliveryFee: Double { availability?.fee?.amount ?? 0 }
    var estimatedETA: String? { availability?.eta?.displayRange }
    var canSaveAddress: Bool { !streetAddress.isEmpty && selectedLocation != nil }
    
    // ... Load Addresses ...
    func loadAddresses() async {
        isLoading = true; error = nil
        do {
            savedAddresses = try await deliveryRepository.getAddresses()
            if let defaultAddr = defaultAddress { selectAddress(defaultAddr) }
        } catch { self.error = error }
        isLoading = false
    }
    
    func loadZones(for storeId: String) async {
        do { zones = try await deliveryRepository.getDeliveryZones(storeId: storeId) }
        catch { self.error = error }
    }
    
    func selectAddress(_ address: DeliveryAddress) {
        selectedAddress = address
        if let coords = address.coordinates { selectedLocation = CLLocationCoordinate2D(latitude: coords.latitude, longitude: coords.longitude) }
    }
    
    func validateDeliveryZone(for storeId: String) async {
        guard let address = selectedAddress else { return }
        isLoading = true
        do {
            availability = try await deliveryRepository.checkAvailability(addressId: address.id, latitude: address.coordinates?.latitude, longitude: address.coordinates?.longitude, storeId: storeId)
            if !isInDeliveryZone { error = DeliveryError.notInZone }
        } catch { self.error = error }
        isLoading = false
    }
    
    func isLocationInZone(latitude: Double, longitude: Double) -> Bool {
        for zone in zones where zone.isActive { if zone.contains(latitude: latitude, longitude: longitude) { return true } }
        return false
    }
    
    func searchAddress(_ query: String) async {
        guard !query.isEmpty else { searchResults = []; return }
        isSearching = true
        do {
            let (lat, lon) = try await locationService.geocodeAddress(query)
            searchResults = [AddressSearchResult(id: UUID().uuidString, title: query, subtitle: "", coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon))]
        } catch { searchResults = [] }
        isSearching = false
    }
    
    func selectSearchResult(_ result: AddressSearchResult) {
        streetAddress = result.title
        selectedLocation = result.coordinate
        searchResults = []
    }
    
    func saveAddress() async -> DeliveryAddress? {
        guard canSaveAddress, let location = selectedLocation else { return nil }
        isLoading = true; error = nil
        let address = DeliveryAddress(id: UUID().uuidString, label: addressLabel.isEmpty ? "Home" : addressLabel,
                                      streetAddress: streetAddress, buildingInfo: buildingInfo.isEmpty ? nil : buildingInfo, city: city,
                                      district: district.isEmpty ? nil : district,
                                      coordinates: DeliveryAddress.Coordinates(latitude: location.latitude, longitude: location.longitude),
                                      isDefault: savedAddresses.isEmpty, usageCount: 0, lastUsedAt: nil, createdAt: Date())
        do {
            let saved = try await deliveryRepository.saveAddress(address)
            savedAddresses.insert(saved, at: 0)
            selectAddress(saved)
            clearForm()
            isLoading = false
            return saved
        } catch { self.error = error; isLoading = false; return nil }
    }
    
    func deleteAddress(_ id: String) async {
        do {
            try await deliveryRepository.deleteAddress(id: id)
            savedAddresses.removeAll { $0.id == id }
            if selectedAddress?.id == id { selectedAddress = defaultAddress }
        } catch { self.error = error }
    }
    
    func setAsDefault(_ id: String) async {
        do {
            try await deliveryRepository.setDefaultAddress(id: id)
            for i in savedAddresses.indices { savedAddresses[i].isDefault = savedAddresses[i].id == id }
        } catch { self.error = error }
    }
    
    func requestLocationPermission() async { await locationService.requestAuthorization() }
    
    func getCurrentLocation() async {
        await locationService.startUpdatingLocation()
        if let location = await locationService.currentLocation {
            currentLocation = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            selectedLocation = currentLocation
            do { streetAddress = try await locationService.reverseGeocode(latitude: location.latitude, longitude: location.longitude) } catch {}
        }
        await locationService.stopUpdatingLocation()
    }
    
    func pinDropped(at coordinate: CLLocationCoordinate2D) {
        selectedLocation = coordinate
        Task { do { streetAddress = try await locationService.reverseGeocode(latitude: coordinate.latitude, longitude: coordinate.longitude) } catch {} }
    }
    
    private func clearForm() { 
        addressLabel = ""; streetAddress = ""; buildingInfo = ""; district = "" 
        storage.remove(key: "delivery_form_draft")
    }
    
    // MARK: - Draft Logic
    
    private struct AddressDraft: Codable {
        let label: String
        let street: String
        let building: String
        let city: String
        let district: String
        let lat: Double?
        let lon: Double?
    }
    
    private func loadDraft() {
        if let draft: AddressDraft = storage.load(AddressDraft.self, key: "delivery_form_draft") {
            self.addressLabel = draft.label
            self.streetAddress = draft.street
            self.buildingInfo = draft.building
            self.city = draft.city
            self.district = draft.district
            if let lat = draft.lat, let lon = draft.lon {
                self.selectedLocation = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            }
        }
    }
    
    private func setupAutoSave() {
        Publishers.CombineLatest4($addressLabel, $streetAddress, $buildingInfo, $district)
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] label, street, building, district in
                guard let self = self else { return }
                let draft = AddressDraft(label: label, street: street, building: building, city: self.city, district: district, lat: self.selectedLocation?.latitude, lon: self.selectedLocation?.longitude)
                try? self.storage.save(draft, key: "delivery_form_draft")
            }
            .store(in: &cancellables)
            
        $selectedLocation
             .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
             .sink { [weak self] loc in
                 guard let self = self else { return }
                 let draft = AddressDraft(label: self.addressLabel, street: self.streetAddress, building: self.buildingInfo, city: self.city, district: self.district, lat: loc?.latitude, lon: loc?.longitude)
                 try? self.storage.save(draft, key: "delivery_form_draft")
             }
             .store(in: &cancellables)
    }
}

struct AddressSearchResult: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let coordinate: CLLocationCoordinate2D
}
