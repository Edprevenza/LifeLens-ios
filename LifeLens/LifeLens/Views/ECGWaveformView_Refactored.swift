// ECGWaveformView_Refactored.swift
// Refactored ECG waveform rendering component using shared types

import SwiftUI
import Accelerate

struct ECGWaveformDisplayView: View {
    @ObservedObject var viewModel: ECGViewModel
    @State private var animationProgress: CGFloat = 0
    @State private var sweepPosition: CGFloat = 0
    
    let samplingRate = 250 // Hz
    let displayDuration = 5.0 // seconds
    let gridSize: CGFloat = 20 // 5mm grid
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Grid background
                ECGGridView(gridSize: gridSize)
                
                // Waveform
                ECGWaveformPath(data: viewModel.waveformData, gridSize: gridSize)
                    .stroke(Color.green, lineWidth: 2)
                    .animation(.linear(duration: 0.1), value: viewModel.waveformData)
                
                // Sweep line for live recording
                if viewModel.isRecording {
                    Rectangle()
                        .fill(Color.green.opacity(0.5))
                        .frame(width: 2)
                        .position(x: sweepPosition * geometry.size.width, y: geometry.size.height / 2)
                        .onAppear {
                            withAnimation(.linear(duration: displayDuration).repeatForever(autoreverses: false)) {
                                sweepPosition = 1
                            }
                        }
                }
            }
        }
    }
}