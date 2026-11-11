#if os(macOS)
import Dispatch
import SwiftUI
import RevCore

@MainActor
final class PickerModel: ObservableObject {
    @Published var query = ""
    @Published var results: [PickerSearchResult] = []
    @Published var selection = 0
    @Published var tone: SkinTone = .none
    @Published private(set) var scrollRevision = 0
    var onChoose: (@MainActor (Int) -> Void)?

    var selected: PickerSearchResult? { results.indices.contains(selection) ? results[selection] : nil }

    func set(query: String, results: [PickerSearchResult], tone: SkinTone) {
        self.results = results
        self.tone = tone
        selection = 0
        self.query = query
        scrollRevision &+= 1
    }

    func move(_ delta: Int) {
        guard !results.isEmpty else { return }
        selection = (selection + delta + results.count) % results.count
    }
}

struct PickerView: View {
    @ObservedObject var model: PickerModel

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(model.results.indices, id: \.self) { index in
                        Group {
                            switch model.results[index] {
                            case .emoji(let emoji):
                                PickerRow(
                                    result: emoji,
                                    tone: model.tone,
                                    isSelected: index == model.selection
                                )
                            case .command(let command):
                                PickerCommandRow(
                                    match: command,
                                    isSelected: index == model.selection
                                )
                            }
                        }
                        .id(index)
                        .contentShape(Rectangle())
                        .onTapGesture { model.onChoose?(index) }
                    }
                }
                .padding(6)
                .id(PickerScrollTarget.top)
            }
            .onChange(of: model.selection) { _, index in
                guard model.results.indices.contains(index) else { return }
                // With no anchor, SwiftUI only scrolls when needed to make the row fully visible.
                proxy.scrollTo(index)
            }
            .onChange(of: model.scrollRevision) { _, _ in
                guard model.results.indices.contains(model.selection) else { return }
                scrollToTop(using: proxy)
            }
            .onAppear { scrollToTop(using: proxy) }
        }
        .frame(width: PickerPanel.width, alignment: .top)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(Color.secondary.opacity(0.25)))
    }

    private func scrollToTop(using proxy: ScrollViewProxy) {
        // Target the padded content container, not row zero, so the true scroll offset is zero.
        proxy.scrollTo(PickerScrollTarget.top, anchor: .top)
        // Result publication and panel resizing happen in the same event turn. Reset once more
        // after layout so AppKit cannot preserve a stale offset while the viewport height changes.
        DispatchQueue.main.async {
            proxy.scrollTo(PickerScrollTarget.top, anchor: .top)
        }
    }
}

private enum PickerScrollTarget: Hashable {
    case top
}

private struct PickerCommandRow: View {
    let match: PickerCommandMatch
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: match.command.systemImageName)
                .font(.system(size: 15, weight: .medium))
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 1) {
                Text(match.command.name)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                    .lineLimit(1)
                Text("Command")
                    .font(.system(size: 9))
                    .foregroundStyle(isSelected ? Color.white.opacity(0.8) : Color.secondary)
            }
            Spacer(minLength: 0)
        }
        .foregroundStyle(isSelected ? Color.white : Color.primary)
        .padding(.horizontal, 8)
        .frame(height: PickerPanel.rowHeight)
        .background(isSelected ? Color.accentColor : Color.clear, in: RoundedRectangle(cornerRadius: 6))
    }
}

private struct PickerRow: View {
    let result: EmojiSearch.Result
    let tone: SkinTone
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
            Text(result.emoji.rendered(tone: tone)).font(.system(size: 18))
                .frame(width: 24)
            Text(":\(displayName):")
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .lineLimit(1)
                .foregroundStyle(isSelected ? Color.white : Color.primary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .frame(height: PickerPanel.rowHeight)
        .background(isSelected ? Color.accentColor : Color.clear, in: RoundedRectangle(cornerRadius: 6))
    }

    private var displayName: String {
        result.displayName
    }
}
#endif
