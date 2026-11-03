#if os(macOS)
import SwiftUI
import RevCore

@MainActor
final class ToolLauncherModel: ObservableObject {
    @Published var query = "" {
        didSet { if query != oldValue { refresh() } }
    }
    @Published private(set) var results: [RevTool] = []
    @Published var selection = 0

    private let registry: ToolRegistry

    init(registry: ToolRegistry) {
        self.registry = registry
        refresh()
    }

    var selected: RevTool? {
        results.indices.contains(selection) ? results[selection] : nil
    }

    func reset() {
        query = ""
        selection = 0
        refresh()
    }

    func refresh() {
        results = registry.search(query)
        selection = min(selection, max(0, results.count - 1))
    }

    func select(_ index: Int) {
        guard results.indices.contains(index) else { return }
        selection = index
    }

    func select(id: String) {
        guard let index = results.firstIndex(where: { $0.id == id }) else { return }
        selection = index
    }

    func move(_ delta: Int) {
        guard !results.isEmpty else { return }
        selection = (selection + delta + results.count) % results.count
    }
}

@MainActor
final class StandaloneEmojiModel: ObservableObject {
    @Published var query = "" {
        didSet { if query != oldValue { refresh() } }
    }
    @Published private(set) var results: [EmojiSearch.Result] = []
    @Published var selection = 0
    @Published var tone: SkinTone = .none
    @Published private(set) var scrollRevision = 0

    var selected: EmojiSearch.Result? {
        results.indices.contains(selection) ? results[selection] : nil
    }

    func reset(tone: SkinTone) {
        query = ""
        selection = 0
        self.tone = tone
        refresh()
    }

    func refresh() {
        results = AppController.shared.searchEmoji(query)
        selection = min(selection, max(0, results.count - 1))
        scrollRevision &+= 1
    }

    func select(_ index: Int) {
        guard results.indices.contains(index) else { return }
        selection = index
    }

    func move(_ delta: Int) {
        guard !results.isEmpty else { return }
        selection = (selection + delta + results.count) % results.count
    }
}

struct ToolLauncherView: View {
    @ObservedObject var model: ToolLauncherModel
    let onOpen: @MainActor () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 9) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Search tools", text: $model.query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15))
            }
            .padding(14)
            Divider()

            ScrollView {
                LazyVStack(spacing: 3) {
                    ForEach(Array(model.results.enumerated()), id: \.element.id) { index, tool in
                        HStack(spacing: 10) {
                            Image(systemName: tool.systemImageName)
                                .frame(width: 24)
                            Text(tool.name)
                                .font(.system(size: 13, weight: index == model.selection ? .semibold : .regular))
                            Spacer()
                        }
                        .foregroundStyle(index == model.selection ? Color.white : Color.primary)
                        .padding(.horizontal, 10)
                        .frame(height: 38)
                        .background(
                            index == model.selection ? Color.accentColor : Color.clear,
                            in: RoundedRectangle(cornerRadius: 7)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture { model.select(index) }
                        .onTapGesture(count: 2) { model.select(index); onOpen() }
                    }
                    if model.results.isEmpty {
                        ContentUnavailableView("No Tools", systemImage: "wrench.and.screwdriver")
                            .padding(.top, 36)
                    }
                }
                .padding(6)
            }

            Divider()
            Text("↑↓ Select   ↩ Open   Esc Close")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.vertical, 8)
        }
        .frame(width: 430, height: 300)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.secondary.opacity(0.25))
        )
    }
}

struct StandaloneEmojiView: View {
    static let panelSize = CGSize(width: 430, height: 360)

    @ObservedObject var model: StandaloneEmojiModel
    let onChoose: @MainActor () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 9) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Search emoji", text: $model.query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15))
            }
            .padding(14)
            Divider()

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(model.results.indices, id: \.self) { index in
                            let result = model.results[index]
                            HStack(spacing: 10) {
                                Text(result.emoji.rendered(tone: model.tone))
                                    .font(.system(size: 22))
                                    .frame(width: 30)
                                Text(":\(displayName(result)):")
                                    .font(.system(size: 13, weight: index == model.selection ? .semibold : .regular))
                                Spacer()
                            }
                            .foregroundStyle(index == model.selection ? Color.white : Color.primary)
                            .padding(.horizontal, 10)
                            .frame(height: 34)
                            .background(
                                index == model.selection ? Color.accentColor : Color.clear,
                                in: RoundedRectangle(cornerRadius: 7)
                            )
                            .id(index)
                            .contentShape(Rectangle())
                            .onTapGesture { model.select(index) }
                            .onTapGesture(count: 2) { model.select(index); onChoose() }
                        }
                        if model.results.isEmpty {
                            ContentUnavailableView(
                                model.query.isEmpty ? "No Frequently Used Emoji" : "No Emoji",
                                systemImage: "face.smiling",
                                description: Text(
                                    model.query.isEmpty
                                        ? "Use emoji from the inline picker to build recents."
                                        : "Try another search."
                                )
                            )
                            .padding(.top, 48)
                        }
                    }
                    .padding(6)
                }
                .onChange(of: model.selection) { _, index in
                    guard model.results.indices.contains(index) else { return }
                    proxy.scrollTo(index, anchor: .center)
                }
                .onChange(of: model.scrollRevision) { _, _ in
                    guard model.results.indices.contains(model.selection) else { return }
                    proxy.scrollTo(model.selection, anchor: .top)
                }
            }

            Divider()
            Text("↑↓ Select   ↩ Insert   Esc Close")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.vertical, 8)
        }
        .frame(width: Self.panelSize.width, height: Self.panelSize.height)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.secondary.opacity(0.25))
        )
    }

    private func displayName(_ result: EmojiSearch.Result) -> String {
        result.displayName
    }
}
#endif
