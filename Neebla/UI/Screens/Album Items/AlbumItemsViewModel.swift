
import Foundation
import SQLite
import Combine
import iOSShared
import iOSBasics

extension AlertMessage {
    func showMessage(for errorEvent: ErrorEvent?) {
        switch errorEvent {
        case .error(let error):
            if let error = error {
                alertMessage = "Error: \(error)"
            }
            else {
                alertMessage = "Error!"
            }
            
        case .showAlert(title: let title, message: let message):
            alertMessage = "\(title): \(message)"

        case .none:
            // This isn't an error
            break
        }
    }
}

class AlbumItemsViewModel: ObservableObject, AlertMessage {
    @Published var showCellDetails: Bool = false
    @Published var loading: Bool = false {
        didSet {
            if oldValue == false && loading == true {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.sync()
                }
            }
        }
    }
    
    @Published var objects = [ServerObjectModel]()
    let sharingGroupUUID: UUID

    @Published var presentAlert = false

    var alertMessage: String! {
        didSet {
            presentAlert = alertMessage != nil
        }
    }
    
    @Published var addNewItem = false
    private var syncSubscription:AnyCancellable!
    private var errorSubscription:AnyCancellable!
    private var markAsDownloadedSubscription:AnyCancellable!
    
    init(album sharingGroupUUID: UUID) {
        self.sharingGroupUUID = sharingGroupUUID
        
        syncSubscription = Services.session.serverInterface.$sync.sink { [weak self] syncResult in
            guard let self = self else { return }
            
            self.loading = false
            self.getItemsForAlbum(album: sharingGroupUUID)
            logger.debug("Sync done")
            
            Downloader.session.start(sharingGroupUUID: self.sharingGroupUUID)
        }
        
        errorSubscription = Services.session.serverInterface.$error.sink { [weak self] errorEvent in
            guard let self = self else { return }
            self.showMessage(for: errorEvent)
        }
        
        // Once files are downloaded, update our list. Debounce to avoid too many updates too quickly.
        markAsDownloadedSubscription = Services.session.serverInterface.$objectMarkedAsDownloaded
                .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
                .sink { [weak self] fileGroupUUID in
            guard let self = self else { return }
            self.getItemsForAlbum(album: sharingGroupUUID)
        }
        
    }
    
    private func getItemsForAlbum(album sharingGroupUUID: UUID) {
        if let objects = try? ServerObjectModel.fetch(db: Services.session.db, where: ServerObjectModel.sharingGroupUUIDField.description == sharingGroupUUID) {
            self.objects = objects
        }
        else {
            self.objects = []
        }
    }
    
    func sync() {
        do {
            try Services.session.syncServer.sync(sharingGroupUUID: sharingGroupUUID)
        } catch let error {
            logger.error("\(error)")
            loading = false
            alertMessage = "Failed to sync."
        }
    }
    
    func updateAfterAddingItem() {
        // Don't rely on only a sync to update the view with the new media item. If there isn't a network connection, a sync won't do what we want.
        
        // This more directly updates the view from the local file that was added.
        getItemsForAlbum(album: sharingGroupUUID)
        
        sync()
    }
    
    func startNewAddItem() {
        addNewItem = true
    }
}
