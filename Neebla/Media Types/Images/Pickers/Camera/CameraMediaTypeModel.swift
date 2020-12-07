
import Foundation
import iOSShared

class CameraMediaTypeModel {
    let sharingGroupUUID: UUID
    let alertMessage: AlertMessage
    let dismisser:MediaTypeListDismisser
    
    init(album sharingGroupUUID: UUID, alertMessage: AlertMessage, dismisser:MediaTypeListDismisser) {
        self.sharingGroupUUID = sharingGroupUUID
        self.alertMessage = alertMessage
        self.dismisser = dismisser
    }
    
    func uploadImage(asset: ImageObjectTypeAssets) {
        do {
            try AnyTypeManager.session.uploadNewObject(assets: asset, sharingGroupUUID: sharingGroupUUID)
        } catch let error {
            logger.error("\(error)")
        }
    }
}
