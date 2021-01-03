
import Foundation
import SwiftUI

// None of the icon's should have specific content in the upper right when normally rendered. This is so that `AnyIcon` can put `upperRightView` there.

struct AnyIcon: View {
    let object: ServerObjectModel
    let upperRightView: AnyView?
    
    init(object: ServerObjectModel, upperRightView: AnyView? = nil) {
        self.object = object
        self.upperRightView = upperRightView
    }
    
    var body: some View {
        ZStack {
            VStack {
                switch object.objectType {
                
                case ImageObjectType.objectType:
                    ImageIcon(object: object)
                
                case URLObjectType.objectType:
                    URLIcon(object: object)
                    
                case LiveImageObjectType.objectType:
                    LiveImageIcon(.object(fileLabel: LiveImageObjectType.imageDeclaration.fileLabel, object: object))
                
                default:
                    EmptyView()
                }
            }
            
            ViewInUpperRight {
                if let upperRightView = upperRightView {
                    upperRightView
                }
            }
            
            ViewInUpperLeft {
                if let count = try? object.getCommentsUnreadCount(), count > 0 {
                    Badge("\(count)")
                }
            }
        }
        .onAppear() {
            Downloader.session.objectAccessed(object: object)
        }
    }
}
