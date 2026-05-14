import SwiftUI

struct BaseViewPostComposerSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var content: String = ""
    let types = ["Hiring", "Learning", "Collab", "Event"]
    @State private var typeSelection = "Hiring"

    var body: some View {
        NavigationStack {
            VStack(spacing: BaseViewLayout.spacing) {
                VStack(alignment: .leading, spacing: BaseViewLayout.spacingCompact) {
                    Text(String(localized: "social_post_type_label"))
                        .font(BaseViewFont.headline)
                        .foregroundStyle(BaseViewColor.textPrimary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: BaseViewLayout.spacingCompact) {
                            ForEach(types, id: \.self) { type in
                                Button { typeSelection = type } label: {
                                    Text(type)
                                        .font(BaseViewFont.labelStrong)
                                        .foregroundStyle(typeSelection == type ? BaseViewColor.accentForeground : BaseViewColor.textPrimary)
                                        .padding(.horizontal, BaseViewLayout.badgeInset)
                                        .padding(.vertical, BaseViewLayout.spacingSmall)
                                        .background(typeSelection == type ? BaseViewColor.accent : BaseViewColor.elevatedSurface)
                                        .overlay(Rectangle().stroke(BaseViewColor.border, lineWidth: BaseViewLayout.cardBorderWidth))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: BaseViewLayout.spacingCompact) {
                    Text(String(localized: "social_content_label"))
                        .font(BaseViewFont.headline)
                        .foregroundStyle(BaseViewColor.textPrimary)

                    TextEditor(text: $content)
                        .font(BaseViewFont.body)
                        .frame(minHeight: 200)
                        .padding(BaseViewLayout.spacingMedium)
                        .background(BaseViewColor.elevatedSurface)
                        .overlay(Rectangle().strokeBorder(BaseViewColor.border, lineWidth: BaseViewLayout.borderWidth))
                }

                Spacer()
            }
            .padding(BaseViewLayout.spacing)
            .background(BaseViewColor.background.ignoresSafeArea())
            .navigationTitle(String(localized: "social_new_post"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common_cancel")) { dismiss() }
                        .foregroundStyle(BaseViewColor.textPrimary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "social_post_action")) {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(BaseViewColor.accent)
                    .disabled(content.isEmpty)
                }
            }
        }
    }
}

typealias PostComposerSheet = BaseViewPostComposerSheet
