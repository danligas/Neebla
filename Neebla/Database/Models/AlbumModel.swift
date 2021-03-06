
import SQLite
import Foundation
import ServerShared
import iOSShared
import iOSBasics

class AlbumModel: DatabaseModel, ObservableObject {
    let db: Connection
    var id: Int64!

    static let sharingGroupUUIDField = Field("sharingGroupUUID", \M.sharingGroupUUID)
    @Published var sharingGroupUUID: UUID

    static let untitledAlbumName = "Untitled Album"
    static let albumNameField = Field("albumName", \M.albumName)
    @Published var albumName: String?
    
    static let permissionField = Field("permission", \M.permission)
    var permission: Permission

    // This is for when the album itself is deleted. Not for just when the user is removed from the album.
    static let deletedField = Field("deleted", \M.deleted)
    var deleted: Bool
    
    init(db: Connection,
        id: Int64! = nil,
        sharingGroupUUID: UUID,
        albumName: String?,
        permission: Permission,
        deleted: Bool = false) throws {

        self.db = db
        self.id = id
        self.sharingGroupUUID = sharingGroupUUID
        self.albumName = albumName
        self.permission = permission
        self.deleted = deleted
    }
    
    // MARK: DatabaseModel
    
    static func createTable(db: Connection) throws {
        try startCreateTable(db: db) { t in
            t.column(idField.description, primaryKey: true)
            t.column(sharingGroupUUIDField.description, unique: true)
            t.column(albumNameField.description)
            t.column(permissionField.description)
            t.column(deletedField.description)
        }
    }
    
    static func rowToModel(db: Connection, row: Row) throws -> AlbumModel {
        return try AlbumModel(db: db,
            id: row[Self.idField.description],
            sharingGroupUUID: row[Self.sharingGroupUUIDField.description],
            albumName: row[Self.albumNameField.description],
            permission: row[Self.permissionField.description],
            deleted: row[Self.deletedField.description]
        )
    }
    
    func insert() throws {
        try doInsertRow(db: db, values:
            Self.sharingGroupUUIDField.description <- sharingGroupUUID,
            Self.albumNameField.description <- albumName,
            Self.permissionField.description <- permission,
            Self.deletedField.description <- deleted
        )
    }
}

extension AlbumModel {
    static func upsertSharingGroup(db: Connection, sharingGroup: iOSBasics.SharingGroup) throws {
        if let model = try AlbumModel.fetchSingleRow(db: db, where: AlbumModel.sharingGroupUUIDField.description == sharingGroup.sharingGroupUUID) {
            if sharingGroup.sharingGroupName != model.albumName {
                try model.update(setters:
                    AlbumModel.albumNameField.description <- sharingGroup.sharingGroupName)
            }
            
            if sharingGroup.deleted {
                try model.update(setters:
                    AlbumModel.deletedField.description <- sharingGroup.deleted)
                try albumDeletionCleanup(db: db, sharingGroupUUID: sharingGroup.sharingGroupUUID)
            }
        }
        else {
            let model = try AlbumModel(db: db, sharingGroupUUID: sharingGroup.sharingGroupUUID, albumName: sharingGroup.sharingGroupName, permission: sharingGroup.permission, deleted: sharingGroup.deleted)
            try model.insert()
        }
    }
    
    static func upsertSharingGroups(db: Connection, sharingGroups: [iOSBasics.SharingGroup]) throws {
    
        // Need to deal with case of albums that we have locally but which are not listed on server. Those have been deleted.
        let localAlbums = try AlbumModel.fetch(db: db)
        
        for localAlbum in localAlbums {
            // Is this local album on the server?
            let onServer = sharingGroups.filter {$0.sharingGroupUUID == localAlbum.sharingGroupUUID}.count == 1
            if !onServer {
                // Not on server: Remove it locally.
                try localAlbum.update(setters: AlbumModel.deletedField.description <- true)
                try albumDeletionCleanup(db: db, sharingGroupUUID: localAlbum.sharingGroupUUID)
            }
        }
        
        for sharingGroup in sharingGroups {
            try upsertSharingGroup(db: db, sharingGroup: sharingGroup)
        }
    }
    
    /* After marking an album as deleted, do related cleanup:
        Remove all ServerObjectModel’s, and all ServerFileModel's.
            Remove all files associated with these.
    */
    static func albumDeletionCleanup(db: Connection, sharingGroupUUID: UUID) throws {
        let objectModelsForAlbum = try ServerObjectModel.fetch(db: db, where: AlbumModel.sharingGroupUUIDField.description == sharingGroupUUID)
        for objectModel in objectModelsForAlbum {
            let fileModels = try ServerFileModel.fetch(db: db, where: ServerFileModel.fileGroupUUIDField.description == objectModel.fileGroupUUID)
            for fileModel in fileModels {
                try fileModel.removeFile()
                try fileModel.delete()
            }
            try objectModel.delete()
        }
    }
}
