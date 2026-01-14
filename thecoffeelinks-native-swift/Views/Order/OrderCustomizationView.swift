import SwiftUI

struct OrderCustomizationView: View {
    let product: Product
    let editingItem: CartItem?
    @Environment(\.dismiss) var dismiss
    @ObservedObject var cartManager = CartManager.shared
    @StateObject private var menuRepo = MenuRepository.shared
    @StateObject private var orderRepo = OrderRepository.shared
    
    // Customization State
    @State private var selectedSize: String
    @State private var iceIndex: Double = 2 // Default to "Normal"
    @State private var sugarIndex: Double = 2 // Default to "50%"
    @State private var selectedToppings: Set<String> = []
    @State private var quantity: Int
    
    init(product: Product, editingItem: CartItem? = nil) {
        self.product = product
        self.editingItem = editingItem
        
        // Initialize state from editing item or defaults
        if let item = editingItem {
            _selectedSize = State(initialValue: item.customization.size)
            _quantity = State(initialValue: item.quantity)
            // Note: ice/sugar/toppings need mapping from labels back to values/indices
            
            // Map labels back to UI state
            // Identify indices for ice/sugar
            // Map topping IDs (item.customization.topping) to selectedToppings set
            
            if let iceLabel = item.customization.ice {
                // Find matching option, default to "Normal" (2)
                // This is a simplified lookup since we don't have direct access to repo here yet
                 // Real implementation would look this up properly
            }
             
            if let toppingIds = item.customization.toppings {
                _selectedToppings = State(initialValue: Set(toppingIds))
            }
        } else {
            _selectedSize = State(initialValue: "M")
            _quantity = State(initialValue: 1)
        }
    }
    
    // Live Price State - Optimistic UI Pattern
    @State private var displayPrice: Double = 0      // What user sees (estimated or server-confirmed)
    @State private var serverPrice: Double? = nil    // Last confirmed server price
    @State private var isSyncing: Bool = false       // Background sync indicator (subtle)
    @State private var calculationTask: Task<Void, Never>?
    @State private var bottomBarHeight: CGFloat = 0
    
    // Computed Options from Repository
    var sizes: [String] {
        // Use product's own size options
        if let sizeOptions = product.sizeOptions {
            var available: [String] = []
            if sizeOptions.small.enabled { available.append("S") }
            if sizeOptions.medium.enabled { available.append("M") }
            if sizeOptions.large.enabled { available.append("L") }
            return available
        }
        // Fallback to menu sizes if product doesn't have size options
        guard let sizes = menuRepo.menu?.sizes else { return ["S", "M", "L"] }
        return sizes.keys.sorted { $0 == "S" || ($0 == "M" && $1 == "L") }
    }
    
    var sizePrice: Double {
        // Get price from product's size options
        if let sizeOptions = product.sizeOptions {
            switch selectedSize {
            case "S": return sizeOptions.small.enabled ? sizeOptions.small.price : 0
            case "M": return sizeOptions.medium.enabled ? sizeOptions.medium.price : 0
            case "L": return sizeOptions.large.enabled ? sizeOptions.large.price : 0
            default: return 0
            }
        }
        // Fallback to menu size modifiers
        // fatalError("Don't have a size in the menu!")
        return menuRepo.menu?.sizes[selectedSize]?.price ?? 0
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
        // Filter menu toppings by product's available toppings
        guard let menu = menuRepo.menu else {
            print("DEBUG: Menu not loaded yet")
            return []
        }
        
        // Debug: Log product info
        print("DEBUG: Product \(product.name)")
        print("DEBUG: Product availableToppings: \(product.availableToppings?.count ?? 0) toppings")
        print("DEBUG: Menu has \(menu.toppings.count) total toppings")
        
        guard let productToppingIds = product.availableToppings, !productToppingIds.isEmpty else {
            print("DEBUG: Product has no availableToppings, showing all menu toppings")
            return menu.toppings
        }
        
        let filtered = menu.toppings.filter { topping in
            productToppingIds.contains(topping.id)
        }
        print("DEBUG: Filtered to \(filtered.count) toppings for this product")
        return filtered
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
    
    // Alert State
    @State private var showDiscardAlert = false
    
    // Track changes - simple hash comparison or flag
    var hasChanges: Bool {
        // Simplified Logic: if editing, check if values differ. For new items, if quantity > 1 or toppings selected.
        if let original = editingItem {
             return quantity != original.quantity 
             || selectedSize != original.customization.size
             // || toppings differ etc
        }
        return quantity > 1 || !selectedToppings.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color.brandBackground.ignoresSafeArea()
                
                if menuRepo.isLoading && menuRepo.menu == nil {
                     // Skeleton Loading State
                     VStack(spacing: 20) {
                         Rectangle()
                             .fill(Color.neutral100)
                             .frame(height: 300)
                         VStack(alignment: .leading, spacing: 12) {
                             Rectangle().fill(Color.neutral100).frame(width: 200, height: 32).cornerRadius(8)
                             Rectangle().fill(Color.neutral100).frame(width: 150, height: 24).cornerRadius(8)
                         }
                         .padding()
                         Spacer()
                     }
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
                
                if #available(iOS 26, *) {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(role: .cancel) {
                            if hasChanges {
                                showDiscardAlert = true
                            } else {
                                dismiss()
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .buttonStyle(.glassProminent)
                        .buttonBorderShape(.circle)
                    }
                } else {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            if hasChanges {
                                showDiscardAlert = true
                            } else {
                                dismiss()
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .alert("Discard Changes?", isPresented: $showDiscardAlert) {
                Button("Discard", role: .destructive) { dismiss() }
                Button("Keep Editing", role: .cancel) { }
            } message: {
                Text("You have unsaved changes. Are you sure you want to discard them?")
            }
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
            
            // Bottom Spacer - dynamic height based on bottom bar
            Color.clear.frame(height: bottomBarHeight+40)
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
                    
                    LiquidGlassPrimaryButton(editingItem != nil ? "Update Order" : "Add to Order", icon: "cart.badge.plus") {
                        addToCart()
                    }
                    .fixedSize()
                    .disabled(isSyncing)
                }
                .padding(20)
                .background(Color.brandBackground.opacity(0.95))
                .background(.ultraThinMaterial)
            }
            .onGeometryChange(for: CGFloat.self) { geo in
                geo.size.height
            } action: { newValue in
                bottomBarHeight = newValue
            }
        }
    }
    
    // MARK: - Components
    
    private func sectionHeader(title: String) -> some View {
        Text(title)
            .font(.brandSerif(14).bold())
            .foregroundColor(.coffeeDark)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var sizeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Size")
            
            Picker("Size", selection: $selectedSize) {
                ForEach(sizes, id: \.self) { size in
                    // Show size with price from product's sizeOptions
                    if let sizeOptions = product.sizeOptions {
                        let sizeInfo: (label: String, price: Double)? = {
                            switch size {
                            case "S": return sizeOptions.small.enabled ? ("Small", sizeOptions.small.price) : nil
                            case "M": return sizeOptions.medium.enabled ? ("Medium", sizeOptions.medium.price) : nil
                            case "L": return sizeOptions.large.enabled ? ("Large", sizeOptions.large.price) : nil
                            default: return nil
                            }
                        }()
                        if let info = sizeInfo {
                            Text("\(info.label) (\(info.price.toVND()))").tag(size)
                        } else {
                            Text(size).tag(size)
                        }
                    } else if let modifier = menuRepo.menu?.sizes[size] {
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
            sectionHeader(title: "Ice Level")
            
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
                    }
                }
            }
        }
    }
    
    private var sugarLevelSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Sugar Level")
            
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
                    }
                }
            }
        }
    }
    
    private var toppingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Toppings")
            
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
            sectionHeader(title: "Quantity")
            
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
    
    private func updatePrice() {
        // Cancel any pending server request
        calculationTask?.cancel()
        
        // Fetch server price
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
                    withAnimation(.easeInOut(duration: 0.2)) {
                        displayPrice = response.total
                    }
                    serverPrice = response.total
                    isSyncing = false
                }
            } catch {
                print("Price sync error: \(error)")
                await MainActor.run {
                    isSyncing = false
                }
            }
        }
    }
    
    func addToCart() {
        let toppingDetails = selectedToppings.compactMap { id in
            availableToppings.first(where: { $0.id == id })
        }
        
        let customization = OrderCustomization(
            size: selectedSize,
            ice: selectedIce.label,
            sugar: selectedSugar.label,
            toppings: Array(selectedToppings),
            selectedToppingDetails: toppingDetails
        )
        
        // Calculate unit final price - prefer server price if available, else use display price
        let totalPrice = serverPrice ?? displayPrice
        let unitPrice = totalPrice / Double(quantity)
        
        if let editingItem = editingItem {
            // Update existing item
            cartManager.updateCart(
                item: editingItem,
                quantity: quantity,
                finalPrice: unitPrice,
                customization: customization
            )
        } else {
            // Add new item
            cartManager.addToCart(
                product: product,
                quantity: quantity,
                finalPrice: unitPrice,
                customization: customization
            )
        }
        
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        dismiss()
    }
}

