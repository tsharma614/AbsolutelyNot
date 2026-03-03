import XCTest
@testable import AbsolutelyNot

final class MultipeerServiceTests: XCTestCase {

    func testInitialState() {
        let service = MultipeerService()
        XCTAssertFalse(service.isHost)
        XCTAssertEqual(service.connectionState, .disconnected)
        XCTAssertTrue(service.connectedPlayers.isEmpty)
    }

    func testHostGameSetsState() {
        let service = MultipeerService()
        service.hostGame(playerName: "Host", playerEmoji: "😀")

        XCTAssertTrue(service.isHost)
        XCTAssertEqual(service.connectionState, .connecting)
        XCTAssertEqual(service.connectedPlayers.count, 1)
        XCTAssertEqual(service.connectedPlayers[0].name, "Host")
    }

    func testJoinGameSetsState() {
        let service = MultipeerService()
        service.joinGame(playerName: "Joiner", playerEmoji: "🤖")

        XCTAssertFalse(service.isHost)
        XCTAssertEqual(service.connectionState, .connecting)
    }

    func testDisconnect() {
        let service = MultipeerService()
        service.hostGame(playerName: "Host", playerEmoji: "😀")
        service.disconnect()

        XCTAssertEqual(service.connectionState, .disconnected)
        XCTAssertTrue(service.connectedPlayers.isEmpty)
    }
}
