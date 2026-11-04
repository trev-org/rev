import Testing
@testable import RevCore

@Suite struct PickerCommandTests {
    private let clipboard = PickerCommand(
        id: "clipboard-history",
        name: "Clipboard History",
        aliases: ["clipboard"],
        keywords: ["clipboard", "history", "paste"],
        systemImageName: "clipboard"
    )
    private let snippets = PickerCommand(
        id: "snippets",
        name: "Snippets",
        aliases: ["snippet", "snippets"],
        keywords: ["snippet", "text", "template", "expand"],
        systemImageName: "text.quote"
    )

    @Test func commandMatchesNameAliasesAndKeywords() {
        for query in ["cl", "clip", "clipboard", "hist", "paste"] {
            let matches = PickerSearch.commandMatches(query, commands: [clipboard])
            XCTAssertEqual(matches.map(\.command.id), ["clipboard-history"], query)
            XCTAssertTrue(matches.first?.isPriority == true, query)
        }
    }

    @Test func prefixCommandsLeadAndFuzzyCommandsFollowEmoji() {
        let emojiStore = EmojiStore(emoji: [
            Emoji(emoji: "A", names: ["cl"], order: 1),
            Emoji(emoji: "B", names: ["cbh"], order: 2),
        ])
        let search = PickerSearch(
            emojiSearch: EmojiSearch(store: emojiStore),
            commands: [clipboard]
        )

        XCTAssertEqual(search.search("cl").map(\.id), [
            "command:clipboard-history",
            "emoji:A",
        ])
        XCTAssertEqual(search.search("cbh").map(\.id), [
            "emoji:B",
            "command:clipboard-history",
        ])
    }

    @Test func exactAliasesCanTriggerCommandsButKeywordsCannot() {
        let search = PickerSearch(
            emojiSearch: EmojiSearch(store: EmojiStore(emoji: [])),
            commands: [clipboard]
        )

        XCTAssertEqual(search.exactCommand(named: "clipboard")?.id, "clipboard-history")
        XCTAssertEqual(search.exactCommand(named: "clipboard_history")?.id, "clipboard-history")
        XCTAssertEqual(search.exactCommand(named: "paste"), nil)
    }

    @Test func equallyRelevantCommandsPreserveConfiguredToolOrder() {
        let matches = PickerSearch.commandMatches("i", commands: [clipboard, snippets])

        XCTAssertEqual(matches.map(\.command.id), ["clipboard-history", "snippets"])
    }
}
