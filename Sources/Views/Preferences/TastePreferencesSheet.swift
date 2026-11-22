import SwiftUI

public struct TastePreferencesSheet: View {
    @ObservedObject var watchlistStore = WatchlistStore.shared
    let onClose: () -> Void
    
    public init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }
    
    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Personalize Your Feed")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    Text("Select categories you love to tailor your Netflix rows.")
                        .font(.system(size: 12))
                        .foregroundColor(NetflixTheme.textSecondary)
                }
                
                Spacer()
                
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Circle().fill(Color(hex: "262626")))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            // 18 Taste Profiles Grid
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(TastePreference.all) { pref in
                        let isSelected = watchlistStore.preferences.contains(pref.id)
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                watchlistStore.togglePreference(pref.id)
                            }
                        }) {
                            HStack(spacing: 8) {
                                Text(pref.badge)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(NetflixTheme.brandRed)
                                        .font(.system(size: 16))
                                } else {
                                    Circle()
                                        .stroke(Color(hex: "444444"), lineWidth: 1.5)
                                        .frame(width: 16, height: 16)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                            .background(isSelected ? Color(hex: "2A1414") : Color(hex: "1F1F1F"))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isSelected ? NetflixTheme.brandRed : Color(hex: "333333"), lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            }
            
            // Bottom Confirm Button
            Button(action: onClose) {
                Text("Save Preferences")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(NetflixTheme.brandRed)
                    .cornerRadius(6)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(NetflixTheme.background)
    }
}
