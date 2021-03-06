//
//  ShareViewModel.swift
//  Share Extension
//
//  Created by Christopher G Prince on 11/15/20.
//

import Foundation
import iOSShared
import Combine
import CoreGraphics

class ShareViewModel: ObservableObject, ModelAlertDisplaying {
    @Published var width: CGFloat = 0
    @Published var height: CGFloat = 0
    @Published var sharingGroups = [SharingGroupData]()
    @Published var selectedSharingGroupUUID: UUID?
    @Published var sharingItem: SXItemProvider?
    @Published var userAlertModel = UserAlertModel()
    
    var userEventSubscription: AnyCancellable!
    var userIsSignedInSubscription: AnyCancellable!
    var cancel:(()->())?
    private var syncSubscription:AnyCancellable!
    private var initialSync = false
    
    // Make sure `Services.session` is setup before calling this.
    func setupAfterServicesInitialized() {
        setupHandleUserEvents()

        // Have to do some wrangling to get an initial sync because user sign in may be async.
        userIsSignedInSubscription = Services.session.signInServices.manager.$userIsSignedIn.sink { [weak self] signedIn in
            guard let self = self else { return }
            if let signedIn = signedIn, signedIn {
                self.sync()
            }
            self.userIsSignedInSubscription = nil
        }

        syncSubscription = Services.session.serverInterface.$sync.sink { [weak self] syncResult in
            guard let self = self else { return }
            self.syncCompletionHelper()
        }
    }
    
    func sync() {
        do {
            try Services.session.syncServer.sync()
        }
        catch let error {
            logger.error("\(error)")
        }
    }
    
    private func syncCompletionHelper() {
        if let sharingGroups = try? Services.session.syncServer.sharingGroups() {
            self.sharingGroups = sharingGroups.enumerated().map { index, group in
                return SharingGroupData(id: group.sharingGroupUUID, name: group.sharingGroupName ?? "Album \(index)")
            }
        }
    }
    
    func upload(item: SXItemProvider, sharingGroupUUID: UUID) {
        do {
            try item.upload(toAlbum: sharingGroupUUID)
            
            // Once the upload is triggered, close the sharing extension. The upload will continue in the background! :)
            cancel?()
        } catch let error {
            logger.error("\(error)")
        }
    }
}
