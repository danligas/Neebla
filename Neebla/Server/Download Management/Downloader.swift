
import Foundation
import iOSShared
import iOSBasics

// Implements a relatively simple strategy for deciding which files need to be downloaded.

class Downloader {
    // Eventually will probably want this to be approx. the number of items that can be shown in the icons screen. So, the user could scroll to a screenful of icons, watch them download, then scroll some more etc.
    static let maxNumberActiveDownloads: UInt = 10
    
    static let checkDownloadsInterval: TimeInterval = 4
    static let session = Downloader()
    
    // Keep track of the N most recently accessed objects. i.e., objects viewed by the user. When we're ready to trigger downloads, use these. A consequence of this strategy is that if the user doesn't move around in the UI, more downloads may not be triggered because they were not accessed.
    private let priorityQueue:PriorityQueue<ServerObjectModel>
    
    // To periodically check for downloads.
    private var timer: Timer!
    
    private init() {
        priorityQueue = try! PriorityQueue<ServerObjectModel>(maxLength: Self.maxNumberActiveDownloads)
        timer = Timer.scheduledTimer(withTimeInterval: Self.checkDownloadsInterval, repeats: true) { [weak self] _ in
            self?.checkDownloads()
        }
    }
    
    // The object was accessed-- i.e., presented to the user in the UI. (Not yet determined if any of the files in the object need downloading).
    func objectAccessed(object: ServerObjectModel) {
        do {
            guard let _ = try Services.session.syncServer.objectNeedsDownload(fileGroupUUID: object.fileGroupUUID) else {
                return
            }
            
            Synchronized.block(self) {
                priorityQueue.add(object: object)
            }
        } catch let error {
            logger.error("\(error)")
        }
    }
    
    // Process:
    //  1) Any objects in the queue
    //  2) If yes, how many objects currently downloading?
    //  3) If capacity available, start more.
    private func checkDownloads() {
        do {
            try checkDownloadsHelper()
        }
        catch let error {
            logger.error("checkDownloads: \(error)")
        }
    }
    
    private func checkDownloadsHelper() throws {
        var downloadsToStart = [ServerObjectModel]()

        try Synchronized.block(self) {
            guard priorityQueue.current.count > 0 else {
                logger.info("Not starting more downloads: None in priority queue")
                return
            }
            
            let numberDownloadsQueued:Int
            
            numberDownloadsQueued = try Services.session.syncServer.numberQueued(.download)
            
            guard numberDownloadsQueued < Self.maxNumberActiveDownloads else {
                logger.info("Not starting more downloads: Currently at max.")
                return
            }
            
            let maxNumberDownloadsToStart = Self.maxNumberActiveDownloads - UInt(numberDownloadsQueued)
            let numberDownloadsToStart = min(maxNumberDownloadsToStart, UInt(priorityQueue.current.count))
            
            downloadsToStart = try priorityQueue.reset(first: numberDownloadsToStart)
        }
        
        guard downloadsToStart.count > 0 else {
            return
        }
        
        for objectModel in downloadsToStart {
            // Use sync server interface, just to make it simpler to get info for download.
            if let downloadable = try Services.session.syncServer.objectNeedsDownload(fileGroupUUID: objectModel.fileGroupUUID) {
                let files = downloadable.downloads.map { FileToDownload(uuid: $0.uuid, fileVersion: $0.fileVersion) }
                let downloadObject = ObjectToDownload(fileGroupUUID: downloadable.fileGroupUUID, downloads: files)
                try Services.session.syncServer.queue(download: downloadObject)
                logger.info("Started download for object: \(downloadObject.fileGroupUUID)")
            }
        }
    }
}