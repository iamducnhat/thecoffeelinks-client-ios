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
                    Text("Post Type")
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
                    Text("Content")
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
                                .stroke(Color.border, lineWidth: 1)
                        )
                        .cornerRadius(0)
                }
                
                Spacer()
            }
            .editorialPadding()
            .editorialBackground()
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Editorial.Colors.textPrimary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") {
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
