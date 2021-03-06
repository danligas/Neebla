
// Initial landing view, when the app first starts: Enable the user to sign in.
// Menu functionality adapted from https://github.com/Vidhyadharan24/SideMenu

import SwiftUI
import iOSShared

struct SignInScreen: View {
    @ObservedObject var userAlertModel:UserAlertModel
    @ObservedObject var model:SignInScreenModel

    init() {
        let userAlertModel = UserAlertModel()
        model = SignInScreenModel(userAlertModel: userAlertModel)
        self.userAlertModel = userAlertModel
        
        // so the `signInView` can show alerts.
        Services.session.signInServices.userAlertDelegate = userAlertModel
    }
    
    var body: some View {
        MenuNavBar(title: "Sign In") {
            VStack {
                if !Services.setupState.isComplete {
                    Text("Setup Failure!")
                        .background(Color.red)
                }

                Services.session.signInServices.signInView
            }
            .showUserAlert(show: $userAlertModel.show, message: userAlertModel)
        }
    }
}

#if DEBUG
struct PopularPhotosView_Previews : PreviewProvider {
    static var previews: some View {
        SignInScreen()
    }
}
#endif
