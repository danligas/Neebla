
import Foundation
import SwiftUI
import SMLinkPreview

struct URLPreviewView: UIViewRepresentable {
    let linkData:LinkData
    @ObservedObject var model:URLPickerViewModel
    
    init(linkData:LinkData, model:URLPickerViewModel) {
        self.linkData = linkData
        self.model = model
    }
    
    func makeUIView(context: Context) -> UIView {
        let preview = LinkPreview.create(with: linkData) { loadedImage in
            model.loadedImage = loadedImage
        }
        return preview
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
    }
}
