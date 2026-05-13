import SwiftUI

struct AppToggleRow: View {
    let title: String
    var subtitle: String? = nil
    var icon: String? = nil
    @Binding var isOn: Bool

    var body: some View {
        AppRow {
            HStack(spacing: 12) {
                if let icon {
                    IconView(name: icon)
                        .font(.system(size: 20))
                        .foregroundStyle(BaseViewColor.textSecondary)
                        .frame(width: 24)
                }

                VStack(alignment: .leading, spacing: subtitle == nil ? 0 : 4) {
                    Text(title)
                        .font(BaseViewFont.body)
                        .foregroundStyle(BaseViewColor.textPrimary)

                    if let subtitle {
                        Text(subtitle)
                            .font(BaseViewFont.label)
                            .foregroundStyle(BaseViewColor.textSecondary)
                    }
                }
            }
        } trailing: {
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(BaseViewColor.accent)
        }
    }
}

struct AppSelectableRow: View {
    let title: String
    var subtitle: String? = nil
    var icon: String? = nil
    var isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            AppListRow(
                title: title,
                subtitle: subtitle,
                icon: icon,
                showsChevron: false,
                isSelected: isSelected
            )
        }
        .buttonStyle(.plain)
    }
}

struct AppStepper: View {
    let value: String
    var decrementIcon: String = "minus"
    var incrementIcon: String = "plus"
    var isDecrementDisabled: Bool = false
    var isIncrementDisabled: Bool = false
    let onDecrement: () -> Void
    let onIncrement: () -> Void

    var body: some View {
        HStack(spacing: AppLayout.spacingSmall) {
            AppButton(icon: decrementIcon, isDisabled: isDecrementDisabled, action: onDecrement)

            Text(value)
                .font(AppFont.monoHeadline)
                .foregroundStyle(BaseViewColor.textPrimary)
                .frame(minWidth: AppLayout.quantityMinWidth)

            AppButton(icon: incrementIcon, isDisabled: isIncrementDisabled, action: onIncrement)
        }
        .fixedSize()
    }
}

struct AppQuantityStepper: View {
    let quantity: Int
    let onDecrease: () -> Void
    let onIncrease: () -> Void

    var body: some View {
        AppStepper(
            value: "\(quantity)",
            isDecrementDisabled: quantity <= 1,
            onDecrement: onDecrease,
            onIncrement: onIncrease
        )
    }
}