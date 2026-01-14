//
//  ReportSheet.swift
//  thecoffeelinks-native-swift
//
//  Sheet for reporting a user
//

import SwiftUI

struct ReportSheet: View {
    let userId: String
    let onReport: (ReportReason, String?) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedReason: ReportReason?
    @State private var additionalDetails = ""
    @State private var isSubmitting = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.orange)
                    
                    Text("Report User")
                        .font(.brandSerif(24))
                        .foregroundStyle(Color.coffeeDark)
                    
                    Text("Help us keep the community safe")
                        .font(.brandSans(14))
                        .foregroundStyle(Color.neutral600)
                }
                .padding(.top, 24)
                
                // Reason Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("What's the issue?")
                        .font(.caption.bold())
                        .foregroundStyle(Color.neutral500)
                    
                    ForEach(ReportReason.allCases) { reason in
                        Button {
                            selectedReason = reason
                        } label: {
                            HStack {
                                Text(reason.displayName)
                                    .foregroundStyle(Color.coffeeDark)
                                
                                Spacer()
                                
                                if selectedReason == reason {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.forestCanopy)
                                }
                            }
                            .padding()
                            .background(selectedReason == reason ? Color.forestCanopy.opacity(0.1) : Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedReason == reason ? Color.forestCanopy : Color.neutral200, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                
                // Additional Details
                VStack(alignment: .leading, spacing: 8) {
                    Text("Additional details (optional)")
                        .font(.caption.bold())
                        .foregroundStyle(Color.neutral500)
                    
                    TextField("Tell us more...", text: $additionalDetails, axis: .vertical)
                        .lineLimit(3...5)
                        .padding()
                        .background(Color.neutral100)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Submit Button
                Button {
                    guard let reason = selectedReason else { return }
                    isSubmitting = true
                    onReport(reason, additionalDetails.isEmpty ? nil : additionalDetails)
                    dismiss()
                } label: {
                    HStack {
                        if isSubmitting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Submit Report")
                                .fontWeight(.semibold)
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(selectedReason != nil ? Color.red : Color.neutral300)
                    .cornerRadius(16)
                }
                .disabled(selectedReason == nil || isSubmitting)
                .padding()
                
                // Privacy note
                Text("Reports are confidential. The user won't know who reported them.")
                    .font(.caption)
                    .foregroundStyle(Color.neutral500)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.bottom)
            }
            .background(Color.brandBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if #available(iOS 26, *) {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(role: .cancel) { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .buttonStyle(.glassProminent)
                        .buttonBorderShape(.circle)
                    }
                } else {
                    ToolbarItem(placement: .topBarLeading) {
                        Button { dismiss() } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}
