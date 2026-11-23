import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

public struct NetworkGuardView<Content: View>: View {
    @ObservedObject var networkStore = NetworkGuardStore.shared
    let content: () -> Content
    
    @State private var isPulseAnimating: Bool = false
    @State private var isCopied: Bool = false
    
    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    private let ispMessage = "Please enable BDIX optical route to IP 172.16.50.4 for DhakaFlix media streaming."
    
    public var body: some View {
        ZStack {
            // Main app content
            content()
            
            // Amber banner when bypassed in Preview mode
            if networkStore.isBypassed && networkStore.status == .offline {
                VStack {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Preview Mode: DhakaFlix (172.16.50.4) unreachable. Full streaming requires home BDIX Wi-Fi.")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                        
                        Spacer()
                        
                        Button(action: {
                            networkStore.checkConnectivity()
                        }) {
                            Text("Re-check")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.4))
                                .cornerRadius(4)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(hex: "B45309"))
                    .shadow(radius: 4)
                    
                    Spacer()
                }
                .zIndex(500)
            }
            
            // Fullscreen Guard Screen (Checking or Offline)
            if !networkStore.isBypassed && networkStore.status != .online {
                ZStack {
                    Color(hex: "141414")
                        .edgesIgnoringSafeArea(.all)
                    
                    // Ambient red radial glow
                    RadialGradient(
                        colors: [HomeFlixTheme.brandRed.opacity(0.18), .clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 280
                    )
                    .edgesIgnoringSafeArea(.all)
                    
                    if networkStore.status == .checking {
                        checkingView
                            .transition(.opacity)
                    } else if networkStore.status == .offline {
                        offlineView
                            .transition(.opacity)
                    }
                }
                .zIndex(800)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: networkStore.status)
        .animation(.easeInOut(duration: 0.3), value: networkStore.isBypassed)
    }
    
    // 1. Initial Checking Animation Screen
    private var checkingView: some View {
        VStack(spacing: 24) {
            // Pulsing radar rings
            ZStack {
                Circle()
                    .stroke(HomeFlixTheme.brandRed.opacity(0.3), lineWidth: 2)
                    .frame(width: isPulseAnimating ? 110 : 64, height: isPulseAnimating ? 110 : 64)
                    .opacity(isPulseAnimating ? 0 : 1)
                
                Circle()
                    .fill(Color(hex: "221414"))
                    .frame(width: 72, height: 72)
                    .overlay(Circle().stroke(HomeFlixTheme.brandRed.opacity(0.5), lineWidth: 1.5))
                
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(HomeFlixTheme.brandRed)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 1.4).repeatForever(autoreverses: false)) {
                    isPulseAnimating = true
                }
            }
            
            VStack(spacing: 8) {
                Text("HOMEFLIX")
                    .font(.system(size: 22, weight: .black))
                    .tracking(2.5)
                    .foregroundColor(HomeFlixTheme.brandRed)
                
                Text("Verifying BDIX Peering Node...")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Probing direct optical link to DhakaFlix node 172.16.50.4")
                    .font(.system(size: 12))
                    .foregroundColor(HomeFlixTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: HomeFlixTheme.brandRed))
                .scaleEffect(1.2)
                .padding(.top, 4)
        }
        .padding(.horizontal, 32)
    }
    
    // 2. DhakaFlix Server Unreachable Screen
    private var offlineView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 18) {
                // Wifi Off Icon with red glow
                ZStack {
                    Circle()
                        .fill(Color(hex: "281414"))
                        .frame(width: 76, height: 76)
                        .overlay(Circle().stroke(HomeFlixTheme.brandRed.opacity(0.6), lineWidth: 1.5))
                    
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(HomeFlixTheme.brandRed)
                }
                .padding(.top, 24)
                
                // Badges and Heading
                VStack(spacing: 8) {
                    HStack(spacing: 5) {
                        Image(systemName: "shield.slash.fill")
                            .font(.system(size: 11))
                        Text("ISP PEERING REQUIRED")
                            .font(.system(size: 10, weight: .heavy))
                            .tracking(0.8)
                    }
                    .foregroundColor(Color(hex: "F87171"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(hex: "450A0A").opacity(0.8))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "991B1B"), lineWidth: 1))
                    
                    Text("Your Network Provider Doesn’t Have DhakaFlix Server")
                        .font(.system(size: 20, weight: .black))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                    
                    Text("We could not establish a connection to the DhakaFlix storage node at 172.16.50.4. This indicates that your internet service provider (ISP) does not have BDIX routing enabled for DhakaFlix media servers.")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color(hex: "B0B0B0"))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, 12)
                }
                
                // Actionable Message Box for ISP
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "server.rack")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(HomeFlixTheme.brandRed)
                        
                        Text("WHAT TO TELL YOUR ISP:")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(1.0)
                            .foregroundColor(HomeFlixTheme.textSecondary)
                        
                        Spacer()
                        
                        Button(action: {
                            #if canImport(UIKit)
                            UIPasteboard.general.string = ispMessage
                            #endif
                            isCopied = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                isCopied = false
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                                    .font(.system(size: 11, weight: .bold))
                                Text(isCopied ? "Copied!" : "Copy Message")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .foregroundColor(isCopied ? Color(hex: "4ADE80") : HomeFlixTheme.brandRed)
                        }
                    }
                    
                    Text("\"\(ispMessage)\"")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(hex: "1F1F1F"))
                        .cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(hex: "333333"), lineWidth: 0.8))
                }
                .padding(14)
                .background(Color(hex: "181818"))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "262626"), lineWidth: 1))
                .padding(.horizontal, 16)
                
                // Action Buttons
                VStack(spacing: 10) {
                    // Retry Button
                    Button(action: {
                        networkStore.checkConnectivity()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14, weight: .bold))
                            Text("Retry Connection")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(HomeFlixTheme.brandRed)
                        .cornerRadius(8)
                        .shadow(color: HomeFlixTheme.brandRed.opacity(0.3), radius: 6)
                    }
                    
                    // Bypass / Preview Button
                    Button(action: {
                        networkStore.bypassToPreview()
                    }) {
                        HStack(spacing: 8) {
                            Text("Continue in Preview Mode")
                                .font(.system(size: 13, weight: .semibold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(HomeFlixTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(Color(hex: "222222"))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "333333"), lineWidth: 1))
                    }
                }
                .padding(.horizontal, 16)
                
                // Collapsible Technical Diagnostics
                VStack(spacing: 6) {
                    Button(action: {
                        withAnimation {
                            networkStore.showDiagnosisDetails.toggle()
                        }
                    }) {
                        Text(networkStore.showDiagnosisDetails ? "Hide Network Diagnosis ▲" : "View Network Diagnosis ▼")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(HomeFlixTheme.textMuted)
                            .underline()
                    }
                    
                    if networkStore.showDiagnosisDetails, let diag = networkStore.diagnosis {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Target Node: \(diag.target):80 (HTTP)")
                            Text("Protocol: BDIX Direct Peering")
                            Text("Response Time: \(diag.responseTimeMs)ms")
                            Text("Status: \(diag.statusCode.map { "\($0)" } ?? "Connection Timeout / Unreachable")")
                            if let err = diag.errorMessage {
                                Text("Diagnosis: \(err)")
                            }
                            Text("Timestamp: \(diag.timestamp)")
                        }
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(Color(hex: "999999"))
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(6)
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 24)
            }
        }
    }
}
