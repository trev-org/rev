#if os(macOS)
import SwiftUI
import RevCore

@MainActor
final class PickerModel: ObservableObject {
    @Published var query = ""
    @Published var results: [PickerSearchResult] = []
    @Published var selection = 0
    @Published var tone: SkinTone = .none
    @Published private(set) var attachmentEdge: PickerAttachmentEdge = .top
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

    func set(attachmentEdge: PickerAttachmentEdge) {
        guard self.attachmentEdge != attachmentEdge else { return }
        self.attachmentEdge = attachmentEdge
        scrollRevision &+= 1
    }

    /// Moves by on-screen direction, independent of whether results grow up or down from the caret.
    func move(_ delta: Int) {
        guard !results.isEmpty else { return }
        let resultDelta = attachmentEdge.resultIndexDelta(forVisualDelta: delta)
        selection = (selection + resultDelta + results.count) % results.count
    }
}

struct PickerView: View {
    @ObservedObject var model: PickerModel

    var body: some View {
        ScrollViewReader { proxy in
            GeometryReader { geometry in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(
                            model.attachmentEdge.orderedResultIndices(count: model.results.count),
                            id: \.self
                        ) { index in
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
                    .frame(
                        maxWidth: .infinity,
                        minHeight: geometry.size.height,
                        alignment: model.attachmentEdge.contentAlignment
                    )
                }
                .defaultScrollAnchor(model.attachmentEdge.scrollAnchor)
                .onChange(of: model.selection) { _, index in
                    guard model.results.indices.contains(index) else { return }
                    let anchor: UnitPoint = index == 0
                        ? model.attachmentEdge.scrollAnchor
                        : .center
                    proxy.scrollTo(index, anchor: anchor)
                }
                .onChange(of: model.scrollRevision, initial: true) { _, _ in
                    guard model.results.indices.contains(model.selection) else { return }
                    proxy.scrollTo(model.selection, anchor: model.attachmentEdge.scrollAnchor)
                }
            }
        }
        .frame(width: PickerPanel.width, height: PickerPanel.height)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(Color.secondary.opacity(0.25)))
    }
}

private extension PickerAttachmentEdge {
    var contentAlignment: Alignment {
        self == .top ? .top : .bottom
    }

    var scrollAnchor: UnitPoint {
        self == .top ? .top : .bottom
    }
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
