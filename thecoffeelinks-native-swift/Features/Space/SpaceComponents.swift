import SwiftUI

// MARK: - Editorial Booking Sheet
struct EditorialBookingSheet: View {
    let store: Store
    @Binding var isPresented: Bool
    
    @State private var selectedDate = Date()
    @State private var selectedDirecton = 60.0 // minutes
    @State private var numberOfPeople = 1
    @State private var needsPower = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Editorial.Spacing.lg) {
                    // Date & Time
                    VStack(alignment: .leading, spacing: Editorial.Spacing.sm) {
                        Text("Date & Time")
                            .font(Editorial.subheading())
                            .foregroundStyle(Editorial.Colors.textPrimary)
                        
                        DatePicker("", selection: $selectedDate, in: Date()...)
                            .datePickerStyle(.graphical)
                            .background(Color.white)
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.border, lineWidth: 1))
                    }
                    
                    // Duration & People
                    VStack(spacing: Editorial.Spacing.md) {
                        EditorialStepperRow(
                            title: "Duration",
                            value: "\(Int(selectedDirecton)) min",
                            onDecrement: {
                                if selectedDirecton > 30 { selectedDirecton -= 30 }
                            },
                            onIncrement: {
                                if selectedDirecton < 480 { selectedDirecton += 30 }
                            }
                        )
                        
                        EditorialStepperRow(
                            title: "People",
                            value: "\(numberOfPeople)",
                            onDecrement: {
                                if numberOfPeople > 1 { numberOfPeople -= 1 }
                            },
                            onIncrement: {
                                if numberOfPeople < 10 { numberOfPeople += 1 }
                            }
                        )
                    }
                    
                    // Preferences
                    VStack(alignment: .leading, spacing: Editorial.Spacing.sm) {
                        Text("Preferences")
                            .font(Editorial.subheading())
                            .foregroundStyle(Editorial.Colors.textSecondary)
                        
                        EditorialToggleRow(title: "Need Power Outlet", isOn: $needsPower)
                    }
                    
                    Spacer(minLength: Editorial.Spacing.lg)
                    
                    // Confirm Button
                    EditorialButton(title: "Confirm Booking") {
                        // Logic to save booking
                        isPresented = false
                    }
                }
                .editorialPadding()
                .padding(.vertical, 24)
            }
            .editorialBackground()
            .navigationTitle("Book Space")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                        .foregroundColor(.textInk)
                }
            }
        }
    }
}

// MARK: - Editorial QR Check-In View
struct EditorialQRCheckInView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: Editorial.Spacing.xl) {
                // Header
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                }
                .padding()
                
                Text("Scan Table QR")
                    .font(Editorial.title())
                    .foregroundStyle(.white)
                
                Spacer()
                
                // Scanner Frame (Sharp)
                Rectangle()
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 4, dash: [20]))
                    .frame(width: 280, height: 280)
                    .overlay(
                        VStack(spacing: Editorial.Spacing.md) {
                            Image(systemName: "qrcode.viewfinder")
                                .font(.system(size: 48))
                                .foregroundStyle(.white.opacity(0.5))
                            Text("Camera Preview")
                                .font(Editorial.body())
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    )
                
                Spacer()
                
                Text("Align the QR code within the frame to check in")
                    .font(Editorial.body())
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 40)
            }
        }
    }
}

// Legacy aliases (removed duplications as they are in EditorialLayout now or self-contained)
typealias BookingSheet = EditorialBookingSheet
typealias QRCheckInView = EditorialQRCheckInView
