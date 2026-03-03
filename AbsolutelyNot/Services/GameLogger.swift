import Foundation

final class GameLogger {
    static let shared = GameLogger()

    private let queue = DispatchQueue(label: "com.absolutelynot.logger", qos: .utility)
    private let fileManager = FileManager.default

    private var logFileURL: URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("game_log.txt")
    }

    private init() {}

    /// Initialize with a custom URL (for testing)
    init(fileURL: URL) {
        self._testFileURL = fileURL
    }

    private var _testFileURL: URL?

    private var activeURL: URL {
        _testFileURL ?? logFileURL
    }

    private var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return df
    }

    func log(_ message: String, context: String = "General") {
        let timestamp = dateFormatter.string(from: Date())
        let line = "[\(timestamp)] [\(context)] \(message)\n"
        queue.async { [weak self] in
            self?.appendToFile(line)
        }
    }

    func logGameStart(config: GameConfig) {
        let playerList = (0..<config.playerCount).map { i in
            "\(config.playerNames[i])(\(config.aiFlags[i] ? "AI" : "Human"))"
        }.joined(separator: ", ")
        log("Game started — players: \(playerList), pebbles: \(config.pebblesPerPlayer), removed: \(GameConfig.removedCards)", context: "GameEngine")
    }

    func logTurn(playerName: String, action: String, cardValue: Int?, pebblesBefore: Int, pebblesAfter: Int, cardPebblesBefore: Int, cardPebblesAfter: Int) {
        var msg = "\(playerName): \(action)"
        if let cv = cardValue {
            msg += " on \(cv)"
        }
        msg += " — pebbles: \(pebblesBefore)→\(pebblesAfter), cardPebbles: \(cardPebblesBefore)→\(cardPebblesAfter)"
        log(msg, context: "GameEngine")
    }

    func logGameEnd(rankedResults: [(name: String, score: Int)]) {
        let results = rankedResults.map { "\($0.name): \($0.score)" }.joined(separator: ", ")
        log("Game ended — results: \(results)", context: "GameEngine")
    }

    func readLog() -> String {
        var result = ""
        queue.sync {
            result = (try? String(contentsOf: activeURL, encoding: .utf8)) ?? ""
        }
        return result
    }

    func clearLog() {
        queue.async { [weak self] in
            guard let self = self else { return }
            try? "".write(to: self.activeURL, atomically: true, encoding: .utf8)
        }
    }

    private func appendToFile(_ text: String) {
        let url = activeURL
        if !fileManager.fileExists(atPath: url.path) {
            fileManager.createFile(atPath: url.path, contents: nil)
        }
        if let handle = try? FileHandle(forWritingTo: url) {
            handle.seekToEndOfFile()
            if let data = text.data(using: .utf8) {
                handle.write(data)
            }
            handle.closeFile()
        }
    }
}
