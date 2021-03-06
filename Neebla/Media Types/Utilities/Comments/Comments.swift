
import Foundation
import iOSBasics
import ChangeResolvers
import SQLite
import iOSShared

class Comments {
    let displayName = "comment"
    
    // Create an initial comment file.
    // The `reconstructionDictionary` has metadata. See comment in Comments+Keys.swift. The keys should *not* conflict with the keys used in the comments.
    // Returns Data that can be uploaded to the server representing the initial comment file.
    static func createInitialFile(mediaTitle:String?, reconstructionDictionary: [String: String]) throws -> Data {
        var commentFile = CommentFile()
        commentFile[Comments.Keys.mediaTitleKey] = mediaTitle
        
        for (key, value) in reconstructionDictionary {
            commentFile[key] = value
        }
        
        return try commentFile.getData()
    }
    
    // Upload a change to a comment file.
    // The `fileUUID` references the comment file within the object-- just a convenience. We could get it given the `object` and the file label also.
    static func queueUpload(fileUUID: UUID, comment: Data, object: ServerObjectModel) throws {
        let file = FileUpload(fileLabel: FileLabels.comments, dataSource: .data(comment), uuid: fileUUID)
        
        let pushNotificationText = try PushNotificationMessage.forAddingComment(to: object)
        let upload = ObjectUpload(objectType: object.objectType, fileGroupUUID: object.fileGroupUUID, sharingGroupUUID: object.sharingGroupUUID, pushNotificationMessage: pushNotificationText, uploads: [file])
        
        try Services.session.syncServer.queue(upload: upload)
    }
    
    // Save of comment file from a local change.
    static func save(commentFile: CommentFile, commentFileModel:ServerFileModel) throws {
        var commentFileModel = commentFileModel
        let commentFileURL: URL
        
        if let url = commentFileModel.url {
            commentFileURL = url
        }
        else {
            commentFileURL = try URLObjectType.createNewFile(for: URLObjectType.commentDeclaration.fileLabel)
            commentFileModel = try commentFileModel.update(setters: ServerFileModel.urlField.description <- commentFileURL)
        }
        
        try commentFile.save(toFile: commentFileURL)
        
        // Since this a local change, we take this as "user has read all comments".
        try Self.resetReadCounts(commentFileModel: commentFileModel)
    }
    
    // The UI-displayable title of media objects are stored in their associated comment file.
    static func displayableMediaTitle(for object: ServerObjectModel) throws -> String? {
        let fileModel = try ServerFileModel.getFileFor(fileLabel: FileLabels.comments, withFileGroupUUID: object.fileGroupUUID )
        guard let fileURL = fileModel.url else {
            return nil
        }
        
        let commentFile = try CommentFile(with: fileURL)
        return commentFile[Comments.Keys.mediaTitleKey] as? String
    }
    
    // Update the unread count for the comment file and its parent object, on the basis of the `commentFileModel.readCount`.
    static func updateUnreadCount(commentFileModel: ServerFileModel) throws {
        guard let url = commentFileModel.url else {
            return
        }
        
        let currentReadCount = commentFileModel.readCount ?? 0
        let commentFile = try CommentFile(with: url)
        let currentUnreadCount = max(commentFile.count - currentReadCount, 0)
        
        try setUnreadCount(commentFileModel: commentFileModel, unreadCount: currentUnreadCount)
    }
    
    static func resetReadCounts(commentFileModel: ServerFileModel) throws {
        guard let url = commentFileModel.url else {
            logger.warning("resetReadCounts: No URL")
            return
        }
        
        let commentFile = try CommentFile(with: url)

        try setUnreadCount(commentFileModel: commentFileModel, unreadCount: 0)
        if commentFileModel.readCount != commentFile.count {
            try commentFileModel.update(setters: ServerFileModel.readCountField.description <- commentFile.count)
        }
    }
    
    enum CommentsError: Error {
        case cannotFindObjectModel
    }
    
    // Set the unread count to `unreadCount` for the commentFileModel and its "parent" ServerObjectModel
    private static func setUnreadCount(commentFileModel: ServerFileModel, unreadCount:Int?) throws {
        if commentFileModel.unreadCount != unreadCount {
            try commentFileModel.update(setters: ServerFileModel.unreadCountField.description <- unreadCount)
        }
        
        guard let objectModel = try ServerObjectModel.fetchSingleRow(db: commentFileModel.db, where: ServerObjectModel.fileGroupUUIDField.description == commentFileModel.fileGroupUUID) else {
            throw CommentsError.cannotFindObjectModel
        }
        
        let unreadCount = unreadCount ?? 0
        
        if objectModel.unreadCount != unreadCount {
            try objectModel.update(setters: ServerObjectModel.unreadCountField.description <- unreadCount)
            commentFileModel.postUnreadCountUpdateNotification(sharingGroupUUID: objectModel.sharingGroupUUID)
        }
    }
}

