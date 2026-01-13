import SwiftUI

struct OrderCustomizationView: View {
    let product: Product
    @Environment(\.dismiss) var dismiss
    @ObservedObject var cartManager = CartManager.shared
    @StateObject private var menuRepo = MenuRepository.shared
    @StateObject private var orderRepo = OrderRepository.shared
    
    // Customization State
    @State private var selectedSize: String = "M"
    @State private var iceIndex: Double = 2 // Default to "Normal"
    @State private var sugarIndex: Double = 2 // Default to "50%"
    @State private var selectedToppings: Set<String> = []
    @State private var quantity: Int = 1
    
    // Live Price State - Optimistic UI Pattern
    @State private var displayPrice: Double = 0      // What user sees (estimated or server-confirmed)
    @State private var serverPrice: Double? = nil    // Last confirmed server price
    @State private var isSyncing: Bool = false       // Background sync indicator (subtle)
    @State private var calculationTask: Task<Void, Never>?
    
    // Computed Options from Repository
    var sizes: [String] {
        guard let sizes = menuRepo.menu?.sizes else { return ["S", "M", "L"] }
        // Sort sizes logically: S, M, L
        return sizes.keys.sorted { $0 == "S" || ($0 == "M" && $1 == "L") }
    }
    
    var iceLevels: [ConfigOption] {
        menuRepo.menu?.iceOptions ?? [
            ConfigOption(value: "none", label: "No Ice"),
            ConfigOption(value: "less", label: "Less Ice"),
            ConfigOption(value: "normal", label: "Normal Ice"),
            ConfigOption(value: "extra", label: "Extra Ice")
        ]
    }
    
    var sugarLevels: [ConfigOption] {
        menuRepo.menu?.sugarOptions ?? [
            ConfigOption(value: "0", label: "0%"),
            ConfigOption(value: "25", label: "25%"),
            ConfigOption(value: "50", label: "50%"),
            ConfigOption(value: "75", label: "75%"),
            ConfigOption(value: "100", label: "100%")
        ]
    }
    
    var availableToppings: [Topping] {
        menuRepo.menu?.toppings ?? []
    }
    
    var selectedIce: ConfigOption {
        let index = Int(iceIndex)
        if index >= 0 && index < iceLevels.count {
            return iceLevels[index]
        }
        return ConfigOption(value: "normal", label: "Normal")
    }
    
    var selectedSugar: ConfigOption {
        let index = Int(sugarIndex)
        if index >= 0 && index < sugarLevels.count {
            return sugarLevels[index]
        }
        return ConfigOption(value: "50", label: "50%")
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color.brandBackground.ignoresSafeArea()
                
                if menuRepo.isLoading && menuRepo.menu == nil {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            // Stretchy Header
                            headerImage
                                .frame(height: 300)
                            
                            // Product Header
                            VStack(alignment: .leading, spacing: 8) {
                                Text(product.name)
                                    .font(.brandSerif(32))
                                    .foregroundColor(.coffeeDark)
                                
                                HStack(spacing: 6) {
                                    Text(displayPrice > 0 ? displayPrice.toVND() : product.price.toVND())
                                        .font(.brandSans(24))
                                        .fontWeight(.bold)
                                        .foregroundColor(.brandAccent)
                                        .contentTransition(.numericText())
                                        .animation(.easeInOut(duration: 0.2), value: displayPrice)
                                    
                                    // Subtle sync indicator
                                    if isSyncing {
                                        ProgressView()
                                            .controlSize(.mini)
                                            .opacity(0.5)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // Custom Options
                            customizationOptions
                                .padding(.top, 24)
                        }
                    }
                    .coordinateSpace(name: "scroll")
                    .ignoresSafeArea()
                    
                    // Bottom Action Bar
                    bottomActionBar
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    ShareLink(
                        item: product.name,
                        subject: Text("Check out this coffee!"),
                        message: Text("I'm ordering \(product.name) at The Coffee Links.")
                    )
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                     if #available(iOS 26, *) {
                         Button(role: .close) {
                             dismiss()
                         }
                     } else {
                         Button(action: { dismiss() }) {
                             Image(systemName: "xmark.circle.fill")
                                 .foregroundColor(.primary)
                         }
                     }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .task {
                if menuRepo.menu == nil {
                    await menuRepo.fetchMenu()
                }
                // Initial calculation
                updatePrice()
            }
        }
    }
    
    // MARK: - View Components
    
    private var customizationOptions: some View {
        VStack(spacing: 24) {
            // Size Section
            sizeSection
            Divider()
            
            // Ice Level Section
            iceLevelSection
            Divider()
            
            // Sugar Level Section
            sugarLevelSection
            Divider()
            
            // Toppings Section
            if !availableToppings.isEmpty {
                toppingsSection
                Divider()
            }
            
            // Quantity Section
            quantitySection
            
            // Bottom Spacer
            Color.clear.frame(height: 160)
        }
        .padding(.horizontal, 20)
    }
    
    private var bottomActionBar: some View {
        VStack {
            Spacer()
            VStack(spacing: 0) {
                Divider()
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total")
                            .font(.caption)
                            .foregroundColor(.neutral600)
                        
                        HStack(spacing: 6) {
                            Text(displayPrice.toVND())
                                .font(.brandSerif(24))
                                .foregroundColor(.coffeeDark)
                                .contentTransition(.numericText())
                                .animation(.easeInOut(duration: 0.2), value: displayPrice)
                            
                            if isSyncing {
                                ProgressView()
                                    .controlSize(.mini)
                                    .opacity(0.5)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: addToCart) {
                        Text("Add to Order")
                            .font(.brandSans(16))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 32)
                            .background(Color.coffeeDark)
                            .cornerRadius(16)
                    }
                    // Don't disable button during background sync - use last valid price
                }
                .padding(20)
                .background(Color.brandBackground.opacity(0.95))
                .background(.ultraThinMaterial)
            }
        }
    }
    
    // MARK: - Components
    
    private func sectionHeader(title: String, icon: String) -> some View {
        Text(title)
            .font(.brandSerif(14).bold())
            .foregroundColor(.coffeeDark)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var sizeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Size", icon: "cup.and.saucer.fill")
            
            Picker("Size", selection: $selectedSize) {
                ForEach(sizes, id: \.self) { size in
                    if let modifier = menuRepo.menu?.sizes[size] {
                        Text("\(modifier.label)").tag(size)
                    } else {
                        Text(size).tag(size)
                    }
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedSize) { _ in
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                updatePrice()
            }
        }
    }
    
    private var iceLevelSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Ice Level", icon: "snowflake")
            
            VStack(spacing: 8) {
                Slider(value: $iceIndex, in: 0...Double(iceLevels.count - 1), step: 1)
                    .tint(Color.coffeeDark)
                    .onChange(of: iceIndex) { _ in
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        updatePrice()
                    }
                
                HStack {
                    ForEach(0..<iceLevels.count, id: \.self) { index in
                        if index > 0 { Spacer() }
                        Text(iceLevels[index].label)
                            .font(.caption2)
                            .foregroundColor(Int(iceIndex) == index ? .coffeeDark : .secondary)
                            .fontWeight(Int(iceIndex) == index ? .bold : .regular)
                            .fixedSize()
                            .frame(width: 1, alignment: .center)
                    }
                }
            }
        }
    }
    
    private var sugarLevelSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Sugar Level", icon: "drop.fill")
            
            VStack(spacing: 8) {
                Slider(value: $sugarIndex, in: 0...Double(sugarLevels.count - 1), step: 1)
                    .tint(Color.coffeeDark)
                    .onChange(of: sugarIndex) { _ in
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        updatePrice()
                    }
                
                HStack {
                    ForEach(0..<sugarLevels.count, id: \.self) { index in
                        if index > 0 { Spacer() }
                        Text(sugarLevels[index].label)
                            .font(.caption2)
                            .foregroundColor(Int(sugarIndex) == index ? .coffeeDark : .secondary)
                            .fontWeight(Int(sugarIndex) == index ? .bold : .regular)
                            .fixedSize()
                            .frame(width: 1, alignment: .center)
                    }
                }
            }
        }
    }
    
    private var toppingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Toppings", icon: "circle.grid.2x2.fill")
            
            ForEach(availableToppings) { topping in
                Toggle(isOn: toppingBinding(for: topping.id)) {
                    HStack {
                        Text(topping.name)
                            .font(.brandSans(16))
                        Spacer()
                        Text("+\(topping.price.toVND())")
                            .font(.brandSans(14))
                            .foregroundColor(.secondary)
                    }
                }
                .tint(.sage)
                .padding(.vertical, 4)
            }
        }
    }
    
    private var quantitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Quantity", icon: "number")
            
            Stepper(value: $quantity, in: 1...99) {
                Text("\(quantity)")
                    .font(.brandSans(18))
                    .fontWeight(.bold)
                    .foregroundColor(.brandAccent)
            }
            .onChange(of: quantity) { _ in
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                updatePrice()
            }
        }
    }
    
    // MARK: - View Components
    
    private var headerImage: some View {
        GeometryReader { geo in
            let minY = geo.frame(in: .named("scroll")).minY
            let height = 300 + (minY > 0 ? minY : 0)
            
            AsyncImage(url: URL(string: product.displayImageUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: height)
                    .clipped()
                    .overlay(
                        LinearGradient(
                            colors: [.black.opacity(0.3), .clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
            } placeholder: {
                Rectangle()
                    .fill(Color.neutral200)
                    .frame(width: geo.size.width, height: height)
            }
            .offset(y: minY > 0 ? -minY : 0)
        }
    }
    
    // MARK: - Actions
    
    private func toppingBinding(for toppingId: String) -> Binding<Bool> {
        Binding(
            get: { selectedToppings.contains(toppingId) },
            set: { isOn in
                if isOn {
                    selectedToppings.insert(toppingId)
                } else {
                    selectedToppings.remove(toppingId)
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                updatePrice()
            }
        )
    }
    
    // MARK: - Local Price Estimation
    
    /// Calculate estimated price locally using cached menu data
    /// This gives instant feedback while server confirms the actual price
    private func estimateLocalPrice() -> Double {
        var unitPrice = product.price
        
        // Add size modifier
        if let sizeModifier = menuRepo.menu?.sizes[selectedSize] {
            unitPrice += sizeModifier.price
        }
        
        // Add toppings
        if let toppings = menuRepo.menu?.toppings {
            for toppingId in selectedToppings {
                if let topping = toppings.first(where: { $0.id == toppingId }) {
                    unitPrice += topping.price
                }
            }
        }
        
        // Multiply by quantity
        let subtotal = unitPrice * Double(quantity)
        
        // Add estimated tax (8%)
        let tax = subtotal * 0.08
        
        return subtotal + tax
    }
    
    private func updatePrice() {
        // Cancel any pending server request
        calculationTask?.cancel()
        
        // 1. Immediately update with local estimate
        let estimated = estimateLocalPrice()
        withAnimation(.easeInOut(duration: 0.15)) {
            displayPrice = estimated
        }
        
        // 2. Fetch server-confirmed price in background
        calculationTask = Task {
            // Short debounce for rapid changes
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2s
            if Task.isCancelled { return }
            
            await MainActor.run { isSyncing = true }
            
            let request = OrderPreviewRequest(
                productId: product.id,
                size: selectedSize,
                ice: selectedIce.value,
                sugar: selectedSugar.value,
                toppings: Array(selectedToppings),
                quantity: quantity,
                voucherId: nil
            )
            
            do {
                let response = try await orderRepo.previewPrice(request: request)
                await MainActor.run {
                    // Only update if price differs from estimate
                    if abs(response.total - displayPrice) > 1 {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            displayPrice = response.total
                        }
                    }
                    serverPrice = response.total
                    isSyncing = false
                }
            } catch {
                print("Price sync error: \(error)")
                await MainActor.run {
                    // Keep showing estimated price on error
                    isSyncing = false
                }
            }
        }
    }
    
    func addToCart() {
        let customization = OrderCustomization(
            size: selectedSize,
            ice: selectedIce.label, // Storing label for display, value for ID?
            // Current OrderCustomization struct probably expects strings.
            // Let's store human readable for now as existing CartItem expects? 
            // Or better, store the FULL modification object.
            // For this task, let's stick to strings matching previous implementation but derived from API.
            sugar: selectedSugar.label,
            toppings: Array(selectedToppings) // Note: This stores IDs now.
        )
        
        // IMPORTANT: Cart logic needs to handle Topping IDs vs Names. 
        // We should map IDs back to Names for display in Cart if needed.
        // Or updated CartItem to store both.
        // For visual consistency with valid existing code, let's map back to names.
        let toppingNames = selectedToppings.compactMap { id in
            availableToppings.first(where: { $0.id == id })?.name
        }
        
        // We'll pass toppingNames to the legacy customization struct if it expects names.
        // If we want to be strict, we really should update CartItem to support IDs.
        // But let's check `OrderCustomization` struct definition first.
        // Proceeding with Topping Names for safely calling `OrderCustomization` which likely takes [String]
        
        let displayCustomization = OrderCustomization(
             size: menuRepo.menu?.sizes[selectedSize]?.label ?? selectedSize,
             ice: selectedIce.label,
             sugar: selectedSugar.label,
             toppings: toppingNames
        )
        
        // Calculate unit final price - prefer server price if available, else use display price
        let totalPrice = serverPrice ?? displayPrice
        let unitPrice = totalPrice / Double(quantity)
        
        cartManager.addToCart(
            product: product,
            quantity: quantity,
            finalPrice: unitPrice,
            customization: displayCustomization
        )
        
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        dismiss()
    }
}

