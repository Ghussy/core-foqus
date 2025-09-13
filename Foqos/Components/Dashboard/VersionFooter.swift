import FamilyControls
import SwiftUI

struct VersionFooter: View {
    let authorizationStatus: AuthorizationStatus
    let onAuthorizationHandler: () -> Void
    
    // Get the current app version from the bundle
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        ?? "1.0"
    }
    
    private var isAuthorized: Bool {
        authorizationStatus == .approved
    }
    
    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .center, spacing: 4) {
                if isAuthorized {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(.green)
                            .frame(width: 8, height: 8)
                        Text("All systems functional")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Button(action: onAuthorizationHandler) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(.red)
                                .frame(width: 8, height: 8)
                            Text("Authorization required. Tap to authorize.")
                                .font(.footnote)
                        }
                    }
                    .foregroundColor(.red)
                }
                
                Text("(v\(appVersion))")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            // Removed external link button per request
        }
    }
    
    // Preview provider for SwiftUI canvas
    struct VersionFooter_Previews: PreviewProvider {
        static var previews: some View {
            VStack(spacing: 20) {
                VersionFooter(
                    authorizationStatus: .approved,
                    onAuthorizationHandler: {}
                )
                .previewDisplayName("Authorized")
                
                VersionFooter(
                    authorizationStatus: .denied,
                    onAuthorizationHandler: {}
                )
                .previewDisplayName("Not Authorized")
            }
        }
    }
}
