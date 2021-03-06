//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

class MemberEvents_Tests: XCTestCase {
    let eventDecoder = EventDecoder<DefaultExtraData>()
    
    func test_added() throws {
        let json = XCTestCase.mockData(fromFile: "MemberAdded")
        let event = try eventDecoder.decode(from: json) as? MemberAddedEvent
        XCTAssertEqual(event?.userId, "steep-moon-9")
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "new_channel_9125"))
    }
    
    func test_updated() throws {
        let json = XCTestCase.mockData(fromFile: "MemberUpdated")
        let event = try eventDecoder.decode(from: json) as? MemberUpdatedEvent
        XCTAssertEqual(event?.userId, "steep-moon-9")
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "new_channel_9125"))
    }
    
    func test_removed() throws {
        let json = XCTestCase.mockData(fromFile: "MemberRemoved")
        let event = try eventDecoder.decode(from: json) as? MemberRemovedEvent
        XCTAssertEqual(event?.userId, "steep-moon-9")
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "new_channel_9125"))
    }
}
