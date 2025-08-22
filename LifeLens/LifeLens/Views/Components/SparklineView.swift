//
//  SparklineView.swift
//  LifeLens
//
//  Lightweight sparkline chart component
//

import SwiftUI

struct SparklineView: View {
    let data: [Double]
    let color: Color
    let lineWidth: CGFloat
    
    init(data: [Double], color: Color = .blue, lineWidth: CGFloat = 2) {
        self.data = data
        self.color = color
        self.lineWidth = lineWidth
    }
    
    var body: some View {
        GeometryReader { geometry in
            if !data.isEmpty {
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    
                    let minValue = data.min() ?? 0
                    let maxValue = data.max() ?? 1
                    let range = maxValue - minValue
                    
                    for (index, value) in data.enumerated() {
                        let x = width * CGFloat(index) / CGFloat(max(1, data.count - 1))
                        let normalizedValue = range > 0 ? (value - minValue) / range : 0.5
                        let y = height * (1 - normalizedValue)
                        
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(color, lineWidth: lineWidth)
            } else {
                // Empty state
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
            }
        }
    }
}