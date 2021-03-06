
import SwiftUI
import iOSShared

struct AlbumSharingScreen: View {
    @ObservedObject var model:AlbumSharingScreenModel
    @ObservedObject var userAlertModel:UserAlertModel
    
    init() {
        let userAlertModel = UserAlertModel()
        model = AlbumSharingScreenModel(userAlertModel: userAlertModel)
        self.userAlertModel = userAlertModel
    }
    
    var body: some View {
        MenuNavBar(title: "Album Sharing") {
            iPadConditionalScreenBodySizer {
                AlbumSharingScreenBody()
                    .background(Color.screenBackground)
            }
        }
    }
}

struct AlbumSharingScreenBody: View {
    @ObservedObject var model:AlbumSharingScreenModel
    @ObservedObject var userAlertModel:UserAlertModel
    
    init() {
        let userAlertModel = UserAlertModel()
        model = AlbumSharingScreenModel(userAlertModel: userAlertModel)
        self.userAlertModel = userAlertModel
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Sharing code")
                Spacer()
            }
            
            TextField("Paste sharing code here", text: $model.sharingCode ?? "")
                
            Spacer().frame(height: 50)
            
            HStack {
                Button(action: {
                    model.acceptSharingInvitation()
                }, label: {
                    Text("Accept sharing invitation")
                })
                .enabled(model.enableAcceptSharingInvitation)
                
                Spacer()
            }
            
            Spacer()
        }
        .padding(30)
        .showUserAlert(show: $userAlertModel.show, message: userAlertModel)
    }
}

