
import Foundation
import SwiftUI

struct AnyIcon: View {
    let object: ServerObjectModel
    
    var body: some View {
        switch object.objectType {
        case ImageObjectType.objectType:
            ImageIcon(object: object)
        default:
            EmptyView()
        }
    }
}