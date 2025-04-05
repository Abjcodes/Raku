import SwiftUI

struct NotificationManagerView: View {
    @State var yOffset: CGFloat = -150
    @State private var timeRemaining: Double = 59.0
    @State private var closeTimeRemaining: Double = 10.0
    @State private var breakTimeRemaining: Double = 0  // Add this for break timer
    let onDismiss: () -> Void
    let onAddOneMinute: () -> Void
    let onAddFiveMinutes: () -> Void
    let onStartBreakTimer: () -> Void
    let isBreakMode: Bool
    let breakDuration: Double  // Add this to receive break duration
    
    var body: some View {
        VStack(spacing: 20) {
            // Top row with logo and close button
            ZStack {
                // Logo/icon - using different image based on mode
                Image(isBreakMode ? "RakuCompanion" : "RakuIcon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                
                // Position the close button on the right
                if !isBreakMode {
                    HStack {
                        Spacer()
                        // Close button with circular progress
                        ZStack {
                            // Circular progress background
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                                .frame(width: 22, height: 22)
                            
                            // Circular progress indicator
                            Circle()
                                .trim(from: 0, to: CGFloat(closeTimeRemaining / 10.0))
                                .stroke(Color(hex: "D1CFC2"), lineWidth: 2)
                                .frame(width: 22, height: 22)
                                .rotationEffect(.degrees(-90))
                            
                            // X icon
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Color(hex: "D1CFC2"))
                        }
                        .frame(width: 24, height: 24)
                        .onTapGesture {
                            endNotification()
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            // Main text
            Text(isBreakMode ? "Take a break, you deserve it \(Int(breakTimeRemaining))s" : "Session is ending in \(Int(timeRemaining))s")
                .font(.system(size: 20))
                .foregroundColor(.white)
            
            // Buttons row
            HStack(spacing: 15) {
                if isBreakMode {
                    Button(action: {
                        onStartBreakTimer()
                        endNotification()
                    }) {
                        Text("Skip")
                            .fontWeight(.medium)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .foregroundColor(Color(hex: "D1CFC2"))
                            .background(Color(hex: "363636"))
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    // Existing buttons for focus mode
                    Button(action: {
                        onStartBreakTimer()
                        endNotification()
                    }) {
                        Text("Take a break")
                            .fontWeight(.medium)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Color(hex: "D1CFC2"))
                            .foregroundColor(Color(hex: "323230"))
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        onAddOneMinute()
                        endNotification()
                    }) {
                        Text("+1 min")
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .foregroundColor(Color(hex: "D1CFC2"))
                            .background(Color(hex: "363636"))
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        onAddFiveMinutes()
                        endNotification()
                    }) {
                        Text("+5 mins")
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .foregroundColor(Color(hex: "D1CFC2"))
                            .background(Color(hex: "363636"))
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .frame(width: 420, height: 180)
        .background(Color(hex: "1F1F1F"))
        .cornerRadius(20)
        .foregroundColor(.white)
        .offset(y: yOffset)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                yOffset = 0
            }
            
            if isBreakMode {
                breakTimeRemaining = breakDuration
                startBreakTimer()
            } else {
                startTimer()
                startCloseTimer()
            }
        }
    }
    
    private func startBreakTimer() {
        let timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if breakTimeRemaining > 0 {
                breakTimeRemaining -= 1
            } else {
                timer.invalidate()
                endNotification()
            }
        }
        RunLoop.current.add(timer, forMode: .common)
    }
    
    private func endNotification() {
        withAnimation(.easeIn(duration: 0.3)) {
            yOffset = -150
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
    
    private func startTimer() {
        let timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
            if timeRemaining > 0.01 {
                timeRemaining -= 0.01
            } else {
                timer.invalidate()
                // Animate out when timer completes
                endNotification()
            }
        }
        RunLoop.current.add(timer, forMode: .common)
    }
    
    private func startCloseTimer() {
        let timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
            if closeTimeRemaining > 0.01 {
                closeTimeRemaining -= 0.01
            } else {
                timer.invalidate()
                // Auto-close notification after 10 seconds
                endNotification()
            }
        }
        RunLoop.current.add(timer, forMode: .common)
    }
}

// Add this extension to support hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
