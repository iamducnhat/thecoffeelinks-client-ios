import SwiftUI

// MARK: - BaseView Booking Sheet
struct BaseViewBookingSheet: View {
    let store: Store
    @Binding var isPresented: Bool

    @State private var selectedDate = Date()
    @State private var selectedDuration = 60.0 // minutes
    @State private var numberOfPeople = 1
    @State private var needsPower = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: BaseViewLayout.spacingXL) {
                    // Date & Time
                    VStack(alignment: .leading, spacing: BaseViewLayout.spacing) {
                        Text(String(localized: "space_date_time_label"))
                            .font(BaseViewFont.sectionHeader)
                            .foregroundStyle(BaseViewColor.textPrimary)

                        DatePicker("", selection: $selectedDate, in: Date()...)
                            .datePickerStyle(.graphical)
                            .background(BaseViewColor.background)
                            .clipShape(RoundedRectangle(cornerRadius: BaseViewLayout.radiusMedium, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: BaseViewLayout.radiusMedium, style: .continuous)
                                    .strokeBorder(BaseViewColor.border, lineWidth: 1)
                            )
                    }

                    // Duration & People
                    VStack(spacing: BaseViewLayout.spacing) {
                        BaseViewStepperRow(
                            title: "Duration",
                            value: "\(Int(selectedDuration)) min",
                            onDecrement: {
                                if selectedDuration > 30 { selectedDuration -= 30 }
                            },
                            onIncrement: {
                                if selectedDuration < 480 { selectedDuration += 30 }
                            }
                        )

                        BaseViewStepperRow(
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
                    VStack(alignment: .leading, spacing: BaseViewLayout.spacing) {
                        Text(String(localized: "space_preferences_label"))
                            .font(BaseViewFont.sectionHeader)
                            .foregroundStyle(BaseViewColor.textPrimary)

                        BaseViewToggleRow(title: "Need Power Outlet", isOn: $needsPower)
                    }

                    Spacer(minLength: BaseViewLayout.spacingXL)

                    // Confirm Button
                    Button {
                        // Logic to save booking
                        isPresented = false
                    } label: {
                        Text(String(localized: "space_confirm_booking"))
                            .font(BaseViewFont.monoCTA)
                            .foregroundStyle(BaseViewColor.background)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(BaseViewColor.accent)
                            .clipShape(Capsule())
                    }
                }
                .padding(BaseViewLayout.spacing)
                .padding(.vertical, 24)
            }
            .background(BaseViewColor.background.ignoresSafeArea())
            .navigationTitle(String(localized: "space_book_space"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common_cancel")) { isPresented = false }
                        .foregroundColor(BaseViewColor.textPrimary)
                }
            }
        }
    }
}

// MARK: - BaseView Barcode Check-In View
struct BaseViewQRCheckInView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: BaseViewLayout.spacingXL) {
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
                    .font(BaseViewFont.displayTitle)
                    .foregroundStyle(.white)

                Spacer()

                // Scanner Frame (Sharp)
                Rectangle()
                    .strokeBorder(Color.white, style: StrokeStyle(lineWidth: 1, dash: [20]))
                    .frame(width: 280, height: 280)
                    .overlay(
                        VStack(spacing: BaseViewLayout.spacing) {
                            Image("qrcode.viewfinder")
                                .font(.system(size: 48))
                                .foregroundStyle(.white.opacity(0.5))
                            Text(String(localized: "space_camera_preview"))
                                .font(BaseViewFont.body)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    )

                Spacer()

                Text(String(localized: "barcode_scan_instruction"))
                    .font(BaseViewFont.body)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 40)
            }
        }
    }
}

private struct BaseViewStepperRow: View {
    let title: String
    let value: String
    let onDecrement: () -> Void
    let onIncrement: () -> Void

    var body: some View {
        AppRow {
            Text(title)
                .font(BaseViewFont.body)
                .foregroundStyle(BaseViewColor.textPrimary)
        } trailing: {
            AppStepper(value: value, onDecrement: onDecrement, onIncrement: onIncrement)
        }
    }
}

private struct BaseViewToggleRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        AppToggleRow(title: title, isOn: $isOn)
    }
}

// Legacy aliases (removed duplications as they are in BaseViewLayout now or self-contained)
typealias BookingSheet = BaseViewBookingSheet
typealias QRCheckInView = BaseViewQRCheckInView
