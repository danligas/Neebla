
import Foundation
import MessageKit
import iOSShared

struct DiscussionMessage: MessageType {
    static let messageIdKey = "id" // Needs to be `id` for the CommentFile class.
    let messageId: String
    
    static let senderIdKey = "senderId"
    static let senderDisplayNameKey = "senderDisplayName"
    let sender: SenderType
    
    static let sendDateKey = "sendDate"
    let sentDate: Date
    
    static let sendTimezoneKey = "sendTimezone"
    let sentTimezone: String
    
    static let messageStringKey = "messageString"
    var kind: MessageKind

    func toDictionary() -> [String: Any]? {
        guard case .text(let string) = kind else {
            return nil
        }
        
        return [
            DiscussionMessage.messageIdKey: messageId,
            DiscussionMessage.senderIdKey: sender.senderId,
            DiscussionMessage.senderDisplayNameKey: sender.displayName,
            DiscussionMessage.sendDateKey: DiscussionMessage.formatter.string(from: sentDate),
            DiscussionMessage.sendTimezoneKey: sentTimezone,
            DiscussionMessage.messageStringKey: string
        ]
    }
    
    static func fromDictionary(_ dict: [String: String]) -> DiscussionMessage? {
        guard let messageId = dict[DiscussionMessage.messageIdKey],
            let senderId = dict[DiscussionMessage.senderIdKey],
            let senderDisplayName = dict[DiscussionMessage.senderDisplayNameKey],
            let sendTimezone = dict[DiscussionMessage.sendTimezoneKey],
            let message = dict[DiscussionMessage.messageStringKey],
            let sendDateString = dict[DiscussionMessage.sendDateKey],
            let sendDate = formatter.date(from: sendDateString) else {
            logger.error("Could not get a DiscussionMessage component.")
            return nil
        }
        
        let sender = Sender(senderId: senderId, displayName: senderDisplayName)
        return DiscussionMessage(messageId: messageId, sender: sender, sentDate: sendDate, sentTimezone: sendTimezone, kind: .text(message))
    }
    
    static let formatter:DateFormatter = {
        let format = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}
