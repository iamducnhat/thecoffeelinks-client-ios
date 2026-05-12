import SwiftUI

// MARK: - Editorial Booking Sheet
struct EditorialBookingSheet: View {
    let store: Store
    @Binding var isPresented: Bool

    @State private var selectedDate = Date()
    @State private var selectedDuration = 60.0 // minutes
    @State private var numberOfPeople = 1
    @State private var needsPower = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppLayout.spacingXL) {
                    // Date & Time
                    VStack(alignment: .leading, spacing: AppLayout.spacing) {
                        Text(String(localized: "space_date_time_label"))
                            .font(AppFont.sectionHeader)
                            .foregroundStyle(Color.textPrimary)

                        DatePicker("", selection: $selectedDate, in: Date()...)
                            .datePickerStyle(.graphical)
                            .background(Color.bgPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                                    .strokeBorder(Color.border, lineWidth: 1)
                            )
                    }

                    // Duration & People
                    VStack(spacing: AppLayout.spacing) {
                        EditorialStepperRow(
                            title: "Duration",
                            value: "\(Int(selectedDuration)) min",
                            onDecrement: {
                                if selectedDuration > 30 { selectedDuration -= 30 }
                            },
                            onIncrement: {
                                if selectedDuration < 480 { selectedDuration += 30 }
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
                    VStack(alignment: .leading, spacing: AppLayout.spacing) {
                        Text(String(localized: "space_preferences_label"))
                            .font(AppFont.sectionHeader)
                            .foregroundStyle(Color.textPrimary)

                        EditorialToggleRow(title: "Need Power Outlet", isOn: $needsPower)
                    }

                    Spacer(minLength: AppLayout.spacingXL)

                    // Confirm Button
                    Button {
                        // Logic to save booking
                        isPresented = false
                    } label: {
                        Text(String(localized: "space_confirm_booking"))
                            .font(AppFont.monoCTA)
                            .foregroundStyle(Color.bgPrimary)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(Color.accentPrimary)
                            .clipShape(Capsule())
                    }
                }
                .padding(AppLayout.spacing)
                .padding(.vertical, 24)
            }
            .background(Color.bgPrimary.ignoresSafeArea())
            .navigationTitle(String(localized: "space_book_space"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common_cancel")) { isPresented = false }
                        .foregroundColor(Color.textPrimary)
                }
            }
        }
    }
}

// MARK: - Editorial Barcode Check-In View
struct EditorialQRCheckInView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: AppLayout.spacingXL) {
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

                Text(String(localized: "space_scan_barcode"))
                    .font(AppFont.displayTitle)
                    .foregroundStyle(.white)

                Spacer()

                // Scanner Frame (Sharp)
                Rectangle()
                    .strokeBorder(Color.white, style: StrokeStyle(lineWidth: 1, dash: [20]))
                    .frame(width: 280, height: 280)
                    .overlay(
                        VStack(spacing: AppLayout.spacing) {
                            Image("qrcode.viewfinder")
                                .font(.system(size: 48))
                                .foregroundStyle(.white.opacity(0.5))
                            Text(String(localized: "space_camera_preview"))
                                .font(AppFont.body)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    )

                Spacer()

                Text(String(localized: "barcode_scan_instruction"))
                    .font(AppFont.body)
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
