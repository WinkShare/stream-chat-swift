//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
import XCTest

class MessageDTO_Tests: XCTestCase {
    var database: DatabaseContainer!
    
    override func setUp() {
        super.setUp()
        database = try! DatabaseContainer(kind: .inMemory)
    }
    
    func test_messagePayload_isStoredAndLoadedFromDB() {
        let userId: UserId = .unique
        let messageId: MessageId = .unique
        let channelId: ChannelId = .unique
        
        let channelPayload: ChannelPayload<DefaultExtraData> = dummyPayload(with: channelId)
        
        let messagePayload: MessagePayload<DefaultExtraData> = .dummy(
            messageId: messageId,
            authorUserId: userId,
            latestReactions: [
                .dummy(messageId: messageId, user: UserPayload.dummy(userId: .unique))
            ],
            ownReactions: [
                .dummy(messageId: messageId, user: UserPayload.dummy(userId: userId))
            ]
        )
        
        // Asynchronously save the payload to the db
        database.write { session in
            // Create the channel first
            try! session.saveChannel(payload: channelPayload, query: nil)
            
            // Save the message
            try! session.saveMessage(payload: messagePayload, for: channelId)
        }
        
        // Load the message from the db and check the fields are correct
        var loadedMessage: MessageDTO? {
            database.viewContext.message(id: messageId)
        }
        
        // Load the message reactions from the db
        var loadedReactions: Set<MessageReactionDTO> {
            let request = NSFetchRequest<MessageReactionDTO>(entityName: MessageReactionDTO.entityName)
            request.predicate = .init(format: "message.id == %@", messageId)
            return Set(try! database.viewContext.fetch(request))
        }
        
        AssertAsync {
            Assert.willBeEqual(messagePayload.id, loadedMessage?.id)
            Assert.willBeEqual(messagePayload.type.rawValue, loadedMessage?.type)
            Assert.willBeEqual(messagePayload.user.id, loadedMessage?.user.id)
            Assert.willBeEqual(messagePayload.createdAt, loadedMessage?.createdAt)
            Assert.willBeEqual(messagePayload.updatedAt, loadedMessage?.updatedAt)
            Assert.willBeEqual(messagePayload.deletedAt, loadedMessage?.deletedAt)
            Assert.willBeEqual(messagePayload.text, loadedMessage?.text)
//            Assert.willBeEqual(loadedMessage?.command, messagePayload.command)
//            Assert.willBeEqual(loadedMessage?.args, messagePayload.args)
            Assert.willBeEqual(messagePayload.parentId, loadedMessage?.parentMessageId)
            Assert.willBeEqual(messagePayload.showReplyInChannel, loadedMessage?.showReplyInChannel)
            Assert.willBeEqual(
                messagePayload.mentionedUsers.map(\.id),
                loadedMessage?.mentionedUsers.map(\.id)
            )
            Assert.willBeEqual(
                messagePayload.threadParticipants.map(\.id),
                loadedMessage?.threadParticipants.map(\.id)
            )
            Assert.willBeEqual(Int32(messagePayload.replyCount), loadedMessage?.replyCount)
            Assert.willBeEqual(messagePayload.extraData, loadedMessage.map {
                try? JSONDecoder.default.decode(NoExtraData.self, from: $0.extraData)
            })
            Assert.willBeEqual(messagePayload.reactionScores, loadedMessage?.reactionScores.mapKeys(MessageReactionType.init))
            Assert.willBeEqual(loadedMessage?.reactions, loadedReactions)
            Assert.willBeEqual(messagePayload.isSilent, loadedMessage?.isSilent)
            Assert.willBeEqual(
                Set(messagePayload.attachmentIDs(cid: channelId)),
                loadedMessage.flatMap { Set($0.attachments.map(\.attachmentID)) }
            )
        }
    }
    
    func test_messagePayload_withExtraData_isStoredAndLoadedFromDB() {
        struct DeathStarMetadata: MessageExtraData {
            static var defaultValue: DeathStarMetadata = .init(isSectedDeathStarPlanIncluded: false)
            
            let isSectedDeathStarPlanIncluded: Bool
        }
        
        enum SecretExtraData: ExtraDataTypes {
            typealias Message = DeathStarMetadata
        }
        
        let userId: UserId = .unique
        let messageId: MessageId = .unique
        let channelId: ChannelId = .unique
        
        let channelPayload: ChannelPayload<DefaultExtraData> = dummyPayload(with: channelId)
        
        let messagePayload: MessagePayload<SecretExtraData> = .dummy(
            messageId: messageId,
            authorUserId: userId,
            extraData: DeathStarMetadata(isSectedDeathStarPlanIncluded: true),
            latestReactions: [
                .dummy(messageId: messageId, user: UserPayload.dummy(userId: .unique))
            ],
            ownReactions: [
                .dummy(messageId: messageId, user: UserPayload.dummy(userId: userId))
            ]
        )
        
        // Asynchronously save the payload to the db
        database.write { session in
            // Create the channel first
            try! session.saveChannel(payload: channelPayload, query: nil)
            
            // Save the message
            try! session.saveMessage(payload: messagePayload, for: channelId)
        }
        
        // Load the message from the db and check the fields are correct
        var loadedMessage: MessageDTO? {
            database.viewContext.message(id: messageId)
        }
        
        // Load the message reactions from the db
        var loadedReactions: Set<MessageReactionDTO> {
            let request = NSFetchRequest<MessageReactionDTO>(entityName: MessageReactionDTO.entityName)
            request.predicate = .init(format: "message.id == %@", messageId)
            return Set(try! database.viewContext.fetch(request))
        }
        
        AssertAsync {
            Assert.willBeEqual(messagePayload.id, loadedMessage?.id)
            Assert.willBeEqual(messagePayload.type.rawValue, loadedMessage?.type)
            Assert.willBeEqual(messagePayload.user.id, loadedMessage?.user.id)
            Assert.willBeEqual(messagePayload.createdAt, loadedMessage?.createdAt)
            Assert.willBeEqual(messagePayload.updatedAt, loadedMessage?.updatedAt)
            Assert.willBeEqual(messagePayload.deletedAt, loadedMessage?.deletedAt)
            Assert.willBeEqual(messagePayload.text, loadedMessage?.text)
            //            Assert.willBeEqual(loadedMessage?.command, messagePayload.command)
            //            Assert.willBeEqual(loadedMessage?.args, messagePayload.args)
            Assert.willBeEqual(messagePayload.parentId, loadedMessage?.parentMessageId)
            Assert.willBeEqual(messagePayload.showReplyInChannel, loadedMessage?.showReplyInChannel)
            Assert.willBeEqual(
                messagePayload.mentionedUsers.map(\.id),
                loadedMessage?.mentionedUsers.map(\.id)
            )
            Assert.willBeEqual(
                messagePayload.threadParticipants.map(\.id),
                loadedMessage?.threadParticipants.map(\.id)
            )
            Assert.willBeEqual(Int32(messagePayload.replyCount), loadedMessage?.replyCount)
            Assert.willBeEqual(messagePayload.extraData, loadedMessage.map {
                try? JSONDecoder.default.decode(DeathStarMetadata.self, from: $0.extraData)
            })
            Assert.willBeEqual(messagePayload.reactionScores, loadedMessage?.reactionScores.mapKeys(MessageReactionType.init))
            Assert.willBeEqual(loadedMessage?.reactions, loadedReactions)
            Assert.willBeEqual(messagePayload.isSilent, loadedMessage?.isSilent)
            Assert.willBeEqual(
                Set(messagePayload.attachmentIDs(cid: channelId)),
                loadedMessage.flatMap { Set($0.attachments.map(\.attachmentID)) }
            )
        }
    }
    
    func test_defaultExtraDataIsUsed_whenExtraDataDecodingFails() throws {
        let userId: UserId = .unique
        let messageId: MessageId = .unique
        let channelId: ChannelId = .unique
        
        let channelPayload: ChannelPayload<DefaultExtraData> = dummyPayload(with: channelId)
        let messagePayload: MessagePayload<DefaultExtraData> = .dummy(messageId: messageId, authorUserId: userId)
        
        try database.writeSynchronously { session in
            // Create the channel first
            try! session.saveChannel(payload: channelPayload, query: nil)
            
            // Save the message
            let messageDTO = try! session.saveMessage(payload: messagePayload, for: channelId)
            // Make the extra data JSON invalid
            messageDTO.extraData = #"{"invalid": json}"# .data(using: .utf8)!
        }
        
        let loadedMessage: ChatMessage? = database.viewContext.message(id: messageId)?.asModel()
        XCTAssertEqual(loadedMessage?.extraData, .defaultValue)
    }
    
    func test_messagePayload_asModel() throws {
        let currentUserId: UserId = .unique
        let messageAuthorId: UserId = .unique
        let messageId: MessageId = .unique
        let channelId: ChannelId = .unique

        try database.createCurrentUser(id: currentUserId)
        try database.createChannel(cid: channelId, withMessages: false)
        
        let messagePayload: MessagePayload<DefaultExtraData> = .dummy(
            messageId: messageId,
            authorUserId: messageAuthorId,
            latestReactions: (0..<3).map { _ in
                .dummy(messageId: messageId, user: .dummy(userId: .unique))
            },
            ownReactions: (0..<2).map { _ in
                .dummy(messageId: messageId, user: .dummy(userId: messageAuthorId))
            }
        )
        
        // Asynchronously save the payload to the db
        try database.writeSynchronously { session in
            // Save the message
            try session.saveMessage(payload: messagePayload, for: channelId)
        }
        
        // Load the message from the db and check the fields are correct
        let loadedMessage: ChatMessage = try XCTUnwrap(
            database.viewContext.message(id: messageId)?.asModel()
        )
        
        // Load 3 latest reactions for the message.
        let latestReactions = Set<ChatMessageReaction>(
            MessageReactionDTO
                .loadLatestReactions(for: messageId, limit: 10, context: database.viewContext)
                .map { $0.asModel() }
        )

        // Load message reactions left by the current user.
        let currentUserReactions = Set<ChatMessageReaction>(
            MessageReactionDTO
                .loadReactions(for: messageId, authoredBy: currentUserId, context: database.viewContext)
                .map { $0.asModel() }
        )

        XCTAssertEqual(loadedMessage.id, messagePayload.id)
        XCTAssertEqual(loadedMessage.type, messagePayload.type)
        XCTAssertEqual(loadedMessage.author.id, messagePayload.user.id)
        XCTAssertEqual(loadedMessage.createdAt, messagePayload.createdAt)
        XCTAssertEqual(loadedMessage.updatedAt, messagePayload.updatedAt)
        XCTAssertEqual(loadedMessage.deletedAt, messagePayload.deletedAt)
        XCTAssertEqual(loadedMessage.text, messagePayload.text)
        XCTAssertEqual(loadedMessage.command, messagePayload.command)
        XCTAssertEqual(loadedMessage.arguments, messagePayload.args)
        XCTAssertEqual(loadedMessage.parentMessageId, messagePayload.parentId)
        XCTAssertEqual(loadedMessage.showReplyInChannel, messagePayload.showReplyInChannel)
        XCTAssertEqual(loadedMessage.mentionedUsers.map(\.id), messagePayload.mentionedUsers.map(\.id))
        XCTAssertEqual(loadedMessage.threadParticipants, Set(messagePayload.threadParticipants.map(\.id)))
        XCTAssertEqual(loadedMessage.replyCount, messagePayload.replyCount)
        XCTAssertEqual(loadedMessage.extraData, messagePayload.extraData)
        XCTAssertEqual(loadedMessage.reactionScores, messagePayload.reactionScores)
        XCTAssertEqual(loadedMessage.isSilent, messagePayload.isSilent)
        XCTAssertEqual(loadedMessage.latestReactions, latestReactions)
        XCTAssertEqual(loadedMessage.currentUserReactions, currentUserReactions)
        XCTAssertEqual(loadedMessage.attachments, messagePayload.attachments(cid: channelId))
    }
    
    func test_newMessage_asRequestBody() throws {
        let currentUserId: UserId = .unique
        let cid: ChannelId = .unique
        let parentMessageId: MessageId = .unique

        // Create current user in the database.
        try database.createCurrentUser(id: currentUserId)

        // Create channel in the database.
        try database.createChannel(cid: cid, withMessages: false)

        // Create parent message in the database.
        try database.createMessage(id: parentMessageId, cid: cid)

        var messageId: MessageId!
        let messageText: String = .unique
        let messageCommand: String = .unique
        let messageArguments: String = .unique
        let messageAttachmentSeeds: [ChatMessageAttachment.Seed] = [.dummy(), .dummy(), .dummy()]
        let messageShowReplyInChannel = true
        let messageExtraData: DefaultExtraData.Message = .defaultValue

        // Create message with attachments in the database.
        try database.writeSynchronously { session in
            messageId = try session.createNewMessage(
                in: cid,
                text: messageText,
                command: messageCommand,
                arguments: messageArguments,
                parentMessageId: parentMessageId,
                attachments: messageAttachmentSeeds,
                showReplyInChannel: true,
                extraData: messageExtraData
            ).id
        }
        
        // Load the message from the database and convert to request body.
        let requestBody: MessageRequestBody<DefaultExtraData> = try XCTUnwrap(
            database.viewContext.message(id: messageId)?.asRequestBody()
        )

        // Assert request body has correct fields.
        XCTAssertEqual(requestBody.id, messageId)
        XCTAssertEqual(requestBody.user.id, currentUserId)
        XCTAssertEqual(requestBody.text, messageText)
        XCTAssertEqual(requestBody.command, messageCommand)
        XCTAssertEqual(requestBody.args, messageArguments)
        XCTAssertEqual(requestBody.parentId, parentMessageId)
        XCTAssertEqual(requestBody.showReplyInChannel, messageShowReplyInChannel)
        XCTAssertEqual(requestBody.extraData, messageExtraData)

        // Assert attachments are in correct order.
        XCTAssertEqual(requestBody.attachments.map(\.title), messageAttachmentSeeds.map(\.fileName))
    }
    
    func test_additionalLocalState_isStored() {
        let userId: UserId = .unique
        let messageId: MessageId = .unique
        let channelId: ChannelId = .unique
        
        let channelPayload: ChannelPayload<DefaultExtraData> = dummyPayload(with: channelId)
        let messagePayload: MessagePayload<DefaultExtraData> = .dummy(messageId: messageId, authorUserId: userId)
        
        // Asynchronously save the payload to the db
        database.write { session in
            // Create the channel first
            try! session.saveChannel(payload: channelPayload, query: nil)
            
            // Save the message
            try! session.saveMessage(payload: messagePayload, for: channelId)
        }
        
        // Set the local state of the message
        database.write {
            $0.message(id: messageId)?.localMessageState = .pendingSend
        }
        
        // Load the message from the db
        var loadedMessage: _ChatMessage<DefaultExtraData>? {
            database.viewContext.message(id: messageId)?.asModel()
        }
        
        // Assert the local state is set
        AssertAsync.willBeEqual(loadedMessage?.localState, .pendingSend)
        
        // Re-save the payload and check the local state is not overriden
        database.write { session in
            try! session.saveMessage(payload: messagePayload, for: channelId)
        }
        AssertAsync.staysEqual(loadedMessage?.localState, .pendingSend)
        
        // Reset the local state and check it gets propagated
        database.write {
            $0.message(id: messageId)?.localMessageState = nil
        }
        AssertAsync.willBeNil(loadedMessage?.localState)
    }
    
    func test_defaultSortingKey_isAutomaticallyAssigned() throws {
        // Prepare the current user and channel first
        let cid: ChannelId = .unique
        let currentUserId: UserId = .unique
        
        _ = try await { completion in
            database.write({ (session) in
                try session.saveCurrentUser(payload: .dummy(
                    userId: currentUserId,
                    role: .admin,
                    extraData: DefaultExtraData.User.defaultValue
                ))
                
                try session.saveChannel(payload: self.dummyPayload(with: cid))
                
            }, completion: completion)
        }
        
        // Create two messages in the DB
        
        var message1Id: MessageId!
        var message2Id: MessageId!

        _ = try await { completion in
            database.write({ session in
                let message1DTO = try session.createNewMessage(
                    in: cid,
                    text: .unique,
                    command: nil,
                    arguments: nil,
                    parentMessageId: nil,
                    attachments: [_ChatMessageAttachment<NoExtraDataTypes>.Seed](),
                    showReplyInChannel: false,
                    extraData: NoExtraData.defaultValue
                )
                message1Id = message1DTO.id
                // Assign locallyCreatedAt data do message 1
                message1DTO.locallyCreatedAt = .unique
                
                let message2DTO = try session.createNewMessage(
                    in: cid,
                    text: .unique,
                    command: nil,
                    arguments: nil,
                    parentMessageId: nil,
                    attachments: [_ChatMessageAttachment<NoExtraDataTypes>.Seed](),
                    showReplyInChannel: false,
                    extraData: NoExtraData.defaultValue
                )
                message2Id = message2DTO.id
            }, completion: completion)
        }
        
        var message1: MessageDTO? {
            database.viewContext.message(id: message1Id)
        }
        
        var message2: MessageDTO? {
            database.viewContext.message(id: message2Id)
        }
        
        AssertAsync {
            Assert.willBeTrue(message1 != nil)
            Assert.willBeTrue(message2 != nil)
            
            // Message 1 should have `locallyCreatedAt` as `defaultSortingKey`
            Assert.willBeEqual(message1?.defaultSortingKey, message1?.locallyCreatedAt)
            
            // Message 2 should have `createdAt` as `defaultSortingKey`
            Assert.willBeEqual(message2?.defaultSortingKey, message2?.createdAt)
        }
    }
    
    // MARK: - New message tests
    
    func test_creatingNewMessage() throws {
        // Prepare the current user and channel first
        let cid: ChannelId = .unique
        let currentUserId: UserId = .unique
        
        _ = try await { completion in
            database.write({ (session) in
                try session.saveCurrentUser(payload: .dummy(
                    userId: currentUserId,
                    role: .admin,
                    extraData: DefaultExtraData.User.defaultValue
                ))
                
                try session.saveChannel(payload: self.dummyPayload(with: cid))
                
            }, completion: completion)
        }
        
        // Create a new message
        var newMessageId: MessageId!
        
        let newMessageText: String = .unique
        let newMessageCommand: String = .unique
        let newMessageArguments: String = .unique
        let newMessageParentMessageId: String = .unique
        let newMessageAttachmentSeeds: [_ChatMessageAttachment<NoExtraDataTypes>.Seed] = [
            .dummy(),
            .dummy()
        ]
                
        _ = try await { completion in
            database.write({
                let messageDTO = try $0.createNewMessage(
                    in: cid,
                    text: newMessageText,
                    command: newMessageCommand,
                    arguments: newMessageArguments,
                    parentMessageId: newMessageParentMessageId,
                    attachments: newMessageAttachmentSeeds,
                    showReplyInChannel: true,
                    extraData: NoExtraData.defaultValue
                )
                newMessageId = messageDTO.id
            }, completion: completion)
        }
        
        let loadedMessage: _ChatMessage<NoExtraDataTypes> = try unwrapAsync(
            database.viewContext.message(id: newMessageId)?
                .asModel()
        )
        
        XCTAssertEqual(loadedMessage.text, newMessageText)
        XCTAssertEqual(loadedMessage.command, newMessageCommand)
        XCTAssertEqual(loadedMessage.arguments, newMessageArguments)
        XCTAssertEqual(loadedMessage.parentMessageId, newMessageParentMessageId)
        XCTAssertEqual(loadedMessage.author.id, currentUserId)
        // Assert the created date of the message is roughly "now"
        XCTAssertLessThan(loadedMessage.createdAt.timeIntervalSince(Date()), 0.1)
        XCTAssertEqual(loadedMessage.createdAt, loadedMessage.locallyCreatedAt)
        XCTAssertEqual(loadedMessage.createdAt, loadedMessage.updatedAt)
        XCTAssertEqual(
            loadedMessage.attachments,
            newMessageAttachmentSeeds.enumerated().map { index, seed in
                .init(cid: cid, messageId: newMessageId, index: index, seed: seed, localState: .pendingUpload)
            }
        )
    }
    
    func test_creatingNewMessage_withoutExistingCurrentUser_throwsError() throws {
        let result = try await { completion in
            database.write({ (session) in
                try session.createNewMessage(
                    in: .unique,
                    text: .unique,
                    command: .unique,
                    arguments: .unique,
                    parentMessageId: .unique,
                    attachments: [_ChatMessageAttachment<NoExtraDataTypes>.Seed](),
                    showReplyInChannel: true,
                    extraData: NoExtraData.defaultValue
                )
            }, completion: completion)
        }
        
        XCTAssert(result is ClientError.CurrentUserDoesNotExist)
    }
    
    func test_creatingNewMessage_withoutExistingChannel_throwsError() throws {
        // Save current user first
        _ = try await {
            database.write({
                try $0.saveCurrentUser(payload: .dummy(
                    userId: .unique,
                    role: .admin,
                    extraData: DefaultExtraData.User.defaultValue
                ))
            }, completion: $0)
        }
                
        // Try to create a new message
        let result = try await { completion in
            database.write({ (session) in
                try session.createNewMessage(
                    in: .unique,
                    text: .unique,
                    command: .unique,
                    arguments: .unique,
                    parentMessageId: .unique,
                    attachments: [_ChatMessageAttachment<NoExtraDataTypes>.Seed](),
                    showReplyInChannel: true,
                    extraData: NoExtraData.defaultValue
                )
            }, completion: completion)
        }
        
        XCTAssert(result is ClientError.ChannelDoesNotExist)
    }
    
    func test_replies_linkedToParentMessage_onCreatingNewMessage() throws {
        // Create current user
        try database.createCurrentUser()
        
        let messageId: MessageId = .unique
        let cid: ChannelId = .unique
        
        // Create parent message
        try database.createMessage(id: messageId, cid: cid)
        
        // Reply messageId
        var replyMessageId: MessageId?
                
        // Create new reply message
        try database.writeSynchronously { session in
            let replyDTO = try session.createNewMessage(
                in: cid,
                text: "Reply",
                command: nil,
                arguments: nil,
                parentMessageId: messageId,
                attachments: [_ChatMessageAttachment<NoExtraDataTypes>.Seed](),
                showReplyInChannel: false,
                extraData: NoExtraData.defaultValue
            )
            // Get reply messageId
            replyMessageId = replyDTO.id
        }
        
        // Get parent message
        let parentMessage = database.viewContext.message(id: messageId)
        
        // Assert reply linked to parent message
        XCTAssert(parentMessage?.replies.first!.id == replyMessageId)
    }
    
    func test_replies_linkedToParentMessage_onSavingMessagePayload() throws {
        // Create current user
        try database.createCurrentUser()
        
        let messageId: MessageId = .unique
        let cid: ChannelId = .unique
        
        // Create parent message
        try database.createMessage(id: messageId, cid: cid)
        
        // Reply messageId
        let replyMessageId: MessageId = .unique
        
        // Create payload for reply message
        let payload: MessagePayload<DefaultExtraData> = .dummy(
            messageId: replyMessageId,
            parentId: messageId,
            showReplyInChannel: false,
            authorUserId: .unique,
            text: "Reply",
            extraData: NoExtraData.defaultValue
        )
        
        // Save reply payload
        try database.writeSynchronously { session in
            try session.saveMessage(payload: payload, for: cid)
        }
        
        // Get parent message
        let parentMessage = database.viewContext.message(id: messageId)
        
        // Assert reply linked to parent message
        XCTAssert(parentMessage?.replies.first!.id == replyMessageId)
    }

    func test_attachmentsAreDeleted_whenMessageIsDeleted() throws {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique
        let attachmentIDs: [AttachmentId] = (0..<5).map {
            .init(cid: cid, messageId: messageId, index: $0)
        }

        // Create channel in the database.
        try database.createChannel(cid: cid)

        // Create message in the database.
        try database.createMessage(id: messageId, cid: cid)

        // Create message attachments in the database.
        try database.writeSynchronously { session in
            for id in attachmentIDs {
                try session.createNewAttachment(
                    seed: ChatMessageAttachment.Seed.dummy(),
                    id: id
                )
            }
        }

        var loadedAttachments: [AttachmentDTO] {
            attachmentIDs.compactMap {
                database.viewContext.attachment(id: $0)
            }
        }

        XCTAssertEqual(loadedAttachments.count, attachmentIDs.count)

        // Create message attachments in the database.
        try database.writeSynchronously { session in
            let message = try XCTUnwrap(session.message(id: messageId))
            session.delete(message: message)
        }

        XCTAssertEqual(loadedAttachments.count, 0)
    }
}
