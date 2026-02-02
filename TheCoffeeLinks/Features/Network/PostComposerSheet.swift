import SwiftUI

struct EditorialPostComposerSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var content: String = ""
    let types = ["Hiring", "Learning", "Collab", "Event"]
    @State private var typeSelection = "Hiring"
    
    var body: some View {
        NavigationStack {
            VStack(spacing: Editorial.Spacing.lg) {
                // Type Selection
                VStack(alignment: .leading, spacing: Editorial.Spacing.sm) {
                    Text(String(localized: "social_post_type_label"))
                        .font(Editorial.subheading())
                        .foregroundStyle(Editorial.Colors.textPrimary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Editorial.Spacing.sm) {
                            ForEach(types, id: \.self) { type in
                                EditorialCategoryPill(
                                    title: type,
                                    isSelected: typeSelection == type,
                                    action: { typeSelection = type }
                                )
                            }
                        }
                    }
                }
                
                // Content Input
                VStack(alignment: .leading, spacing: Editorial.Spacing.sm) {
                    Text(String(localized: "social_content_label"))
                        .font(Editorial.subheading())
                        .foregroundStyle(Editorial.Colors.textPrimary)
                    
                    TextEditor(text: $content)
                        .font(Editorial.body())
                        .frame(height: 200)
                        .padding(Editorial.Spacing.md)
                        .background(Color(UIColor.secondarySystemBackground))
                        // Flat
                        .overlay(
                            Rectangle()
                                .strokeBorder(Color.border, lineWidth: 1)
                        )
                        .cornerRadius(0)
                }
                
                Spacer()
            }
            .editorialPadding()
            .editorialBackground()
            .navigationTitle(String(localized: "social_new_post"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common_cancel")) { dismiss() }
                        .foregroundStyle(Editorial.Colors.textPrimary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "social_post_action")) {
                        // Post logic here
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Editorial.Colors.accent)
                    .disabled(content.isEmpty)
                }
            }
        }
    }
}

// Legacy alias
typealias PostComposerSheet = EditorialPostComposerSheet
