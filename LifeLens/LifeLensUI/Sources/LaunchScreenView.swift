//
//  LaunchScreenView.swift
//  LifeLens
//
//  Professional launch screen with animations
//

import SwiftUI

struct LaunchScreenView: View {
    @State private var isAnimating = false
    @State private var showText = false
    @State private var pulseAnimation = false
    
    var body: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.2),
                    Color(red: 0.05, green: 0.05, blue: 0.15)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Logo Container
                ZStack {
                    // Outer ring with pulse animation
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.3, green: 0.4, blue: 1.0),
                                    Color(red: 0.5, green: 0.3, blue: 1.0)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 140, height: 140)
                        .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                        .opacity(pulseAnimation ? 0.5 : 1.0)
                        .animation(
                            Animation.easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true),
                            value: pulseAnimation
                        )
                    
                    // Inner circle background
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.15, green: 0.15, blue: 0.25),
                                    Color(red: 0.1, green: 0.1, blue: 0.2)
                                ]),
                                center: .center,
                                startRadius: 5,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)
                    
                    // ECG Wave
                    ECGWaveShape()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.red,
                                    Color(red: 1.0, green: 0.3, blue: 0.3)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 80, height: 40)
                        .scaleEffect(isAnimating ? 1.0 : 0.8)
                        .opacity(isAnimating ? 1.0 : 0.0)
                    
                    // Dots around the circle
                    ForEach(0..<12) { index in
                        Circle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 4, height: 4)
                            .offset(y: -55)
                            .rotationEffect(.degrees(Double(index) * 30))
                            .scaleEffect(isAnimating ? 1.0 : 0.0)
                            .animation(
                                Animation.easeOut(duration: 0.6)
                                    .delay(Double(index) * 0.05),
                                value: isAnimating
                            )
                    }
                }
                .rotationEffect(.degrees(isAnimating ? 0 : -90))
                .animation(.easeOut(duration: 1.0), value: isAnimating)
                
                // Brand Name
                VStack(spacing: 8) {
                    HStack(spacing: 0) {
                        Text("Life")
                            .font(.system(size: 48, weight: .light, design: .rounded))
                            
            .foregroundColor(.white)
                        
                        Text("Lens")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.4, green: 0.5, blue: 1.0),
                                        Color(red: 0.6, green: 0.4, blue: 1.0)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    .opacity(showText ? 1.0 : 0.0)
                    .offset(y: showText ? 0 : 20)
                    
                    Text("24/7 AI HEALTH MONITORING")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        
            .foregroundColor(.white.opacity(0.7))
                        .kerning(2)
                        .opacity(showText ? 1.0 : 0.0)
                        .offset(y: showText ? 0 : 20)
                }
                
                Spacer()
                
                // Loading Indicator
                VStack(spacing: 16) {
                    // Custom loading dots
                    HStack(spacing: 8) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(Color.white.opacity(0.6))
                                .frame(width: 8, height: 8)
                                .scaleEffect(pulseAnimation ? 1.0 : 0.5)
                                .animation(
                                    Animation.easeInOut(duration: 0.6)
                                        .repeatForever()
                                        .delay(Double(index) * 0.2),
                                    value: pulseAnimation
                                )
                        }
                    }
                    
                    Text("Initializing Health Systems")
                        .font(.system(size: 12, weight: .medium))
                        
            .foregroundColor(.white.opacity(0.5))
                        .opacity(showText ? 1.0 : 0.0)
                }
                .padding(.bottom, 60)
            }
            
            // Decorative elements
            GeometryReader { geometry in
                // Top left decoration
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.blue.opacity(0.3),
                                Color.blue.opacity(0.0)
                            ]),
                            center: .center,
                            startRadius: 10,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .offset(x: -100, y: -100)
                    .blur(radius: 20)
                
                // Bottom right decoration
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.purple.opacity(0.3),
                                Color.purple.opacity(0.0)
                            ]),
                            center: .center,
                            startRadius: 10,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .offset(
                        x: geometry.size.width - 100,
                        y: geometry.size.height - 100
                    )
                    .blur(radius: 20)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                isAnimating = true
            }
            
            withAnimation(.easeOut(duration: 0.8).delay(0.5)) {
                showText = true
            }
            
            pulseAnimation = true
        }
    }
}

// Custom ECG Wave Shape
struct ECGWaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        let midY = height / 2
        
        path.move(to: CGPoint(x: 0, y: midY))
        
        // Create ECG-like wave pattern
        path.addLine(to: CGPoint(x: width * 0.2, y: midY))
        path.addLine(to: CGPoint(x: width * 0.25, y: midY - height * 0.1))
        path.addLine(to: CGPoint(x: width * 0.3, y: midY))
        
        // P wave
        path.addQuadCurve(
            to: CGPoint(x: width * 0.4, y: midY),
            control: CGPoint(x: width * 0.35, y: midY - height * 0.2)
        )
        
        // QRS complex
        path.addLine(to: CGPoint(x: width * 0.45, y: midY + height * 0.1))
        path.addLine(to: CGPoint(x: width * 0.5, y: midY - height * 0.8))
        path.addLine(to: CGPoint(x: width * 0.55, y: midY + height * 0.3))
        path.addLine(to: CGPoint(x: width * 0.6, y: midY))
        
        // T wave
        path.addQuadCurve(
            to: CGPoint(x: width * 0.75, y: midY),
            control: CGPoint(x: width * 0.675, y: midY - height * 0.3)
        )
        
        path.addLine(to: CGPoint(x: width, y: midY))
        
        return path
    }
}

struct LaunchScreenView_Previews: PreviewProvider {
    static var previews: some View {
        LaunchScreenView()
    }
}