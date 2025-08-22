//
//  ModernInsightsView.swift
//  LifeLens
//
//  Production-ready Insights view
//

import SwiftUI

struct ModernInsightsView: View {
    @StateObject private var viewModel = HealthDashboardViewModel()
    @State private var selectedInsightType: InsightType = .sleep
    
    enum InsightType: String, CaseIterable {
        case heartRate = "Heart Rate"
        case activity = "Activity"
        case sleep = "Sleep"
        case glucose = "Glucose"
    }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.02, green: 0.02, blue: 0.05),
                    Color(red: 0.05, green: 0.05, blue: 0.08)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header without logo for cleaner look
                    InsightsHeader()
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    
                    // Health Score
                    HealthScoreSection(viewModel: viewModel)
                        .padding(.horizontal, 20)
                    
                    // Insights Grid
                    InsightsGrid(selectedType: $selectedInsightType)
                        .padding(.horizontal, 20)
                    
                    // Recommendations
                    RecommendationsSection(selectedType: selectedInsightType)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct InsightsHeader: View {
    @State private var selectedPeriod = "Week"
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Health Insights")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("AI-powered health analysis")
                        .font(.system(size: 14))
                        .foregroundColor(Color.white.opacity(0.6))
                }
                
                Spacer()
            }
            
            // Time Period Selector
            HStack(spacing: 4) {
                ForEach(["Day", "Week", "Month"], id: \.self) { period in
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            selectedPeriod = period
                        }
                    }) {
                        Text(period)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(selectedPeriod == period ? .white : Color.white.opacity(0.5))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                ZStack {
                                    if selectedPeriod == period {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                    }
                                }
                            )
                    }
                }
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
            )
        }
    }
}

struct HealthScoreSection: View {
    @ObservedObject var viewModel: HealthDashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Overall Health Score")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            HStack(spacing: 40) {
                // Score Circle
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .trim(from: 0, to: 0.92)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.green, Color.blue]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                    
                    VStack {
                        Text("92")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                        Text("Excellent")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                    }
                }
                
                // Score Breakdown
                VStack(alignment: .leading, spacing: 16) {
                    HealthMetricRow(label: "Heart Health", score: 95, color: .red)
                    HealthMetricRow(label: "Blood Sugar", score: 88, color: .purple)
                    HealthMetricRow(label: "Activity Level", score: 94, color: .blue)
                    HealthMetricRow(label: "Sleep Quality", score: 91, color: .indigo)
                }
                
                Spacer()
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
}

struct HealthMetricRow: View {
    let label: String
    let score: Int
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .frame(width: 100, alignment: .leading)
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(score) / 100, height: 6)
                }
            }
            .frame(height: 6)
            
            Text("\(score)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(color)
                .frame(width: 30, alignment: .trailing)
        }
    }
}

struct InsightsGrid: View {
    @Binding var selectedType: ModernInsightsView.InsightType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Key Insights")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 20) {
                InsightCard(
                    icon: "heart.fill",
                    title: "Heart Rate Trend",
                    insight: "Your resting heart rate has improved by 5% this week",
                    trend: .up,
                    color: .red,
                    insightType: .heartRate,
                    selectedType: $selectedType
                )
                
                InsightCard(
                    icon: "figure.walk",
                    title: "Activity Pattern",
                    insight: "You're most active between 2-4 PM daily",
                    trend: .neutral,
                    color: .green,
                    insightType: .activity,
                    selectedType: $selectedType
                )
                
                InsightCard(
                    icon: "moon.fill",
                    title: "Sleep Quality",
                    insight: "Deep sleep increased by 15 minutes on average",
                    trend: .up,
                    color: .purple,
                    insightType: .sleep,
                    selectedType: $selectedType
                )
                
                InsightCard(
                    icon: "drop.fill",
                    title: "Glucose Control",
                    insight: "Post-meal spikes are within healthy range",
                    trend: .neutral,
                    color: .orange,
                    insightType: .glucose,
                    selectedType: $selectedType
                )
            }
        }
    }
}

struct InsightCard: View {
    let icon: String
    let title: String
    let insight: String
    let trend: TrendDirection
    let color: Color
    var insightType: ModernInsightsView.InsightType?
    var selectedType: Binding<ModernInsightsView.InsightType>?
    
    @State private var isPressed = false
    @State private var showDetail = false
    @State private var animateGradient = false
    
    enum TrendDirection {
        case up, down, neutral
        
        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .neutral: return "minus"
            }
        }
        
        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .neutral: return .blue
            }
        }
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                if let type = insightType, let binding = selectedType {
                    binding.wrappedValue = type
                }
                showDetail.toggle()
            }
        }) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [color, color.opacity(0.6)]),
                                    startPoint: animateGradient ? .topLeading : .bottomTrailing,
                                    endPoint: animateGradient ? .bottomTrailing : .topLeading
                                )
                            )
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: icon)
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(trend.color.opacity(0.2))
                            .frame(width: 30, height: 30)
                        
                        Image(systemName: trend.icon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(trend.color)
                    }
                }
                
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(insight)
                    .font(.system(size: 14))
                    .foregroundColor(Color.white.opacity(0.7))
                    .lineLimit(showDetail ? nil : 2)
                    .fixedSize(horizontal: false, vertical: !showDetail)
                
                if showDetail {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 12))
                            .foregroundColor(color)
                        Text("View Details")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(color)
                    }
                    .padding(.top, 8)
                }
            }
            .padding(20)
            .frame(minHeight: 160)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.05),
                                    Color.white.opacity(0.02)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    color.opacity(0.4),
                                    color.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .shadow(color: color.opacity(0.2), radius: 10, x: 0, y: 5)
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        } perform: {}
    }
}

struct RecommendationsSection: View {
    let selectedType: ModernInsightsView.InsightType
    
    var recommendations: [RecommendationData] {
        switch selectedType {
        case .heartRate:
            return [
                RecommendationData(
                    icon: "heart.text.square",
                    title: "Cardio Health",
                    recommendation: "Your heart rate variability suggests good cardiac fitness. Maintain current exercise routine",
                    priority: .low
                ),
                RecommendationData(
                    icon: "figure.walk.motion",
                    title: "Zone Training",
                    recommendation: "Spend 20-30 minutes in Zone 2 (120-140 bpm) for optimal fat burning",
                    priority: .medium
                ),
                RecommendationData(
                    icon: "waveform.path.ecg",
                    title: "Recovery Time",
                    recommendation: "Allow 48 hours between high-intensity workouts for heart recovery",
                    priority: .high
                )
            ]
        case .activity:
            return [
                RecommendationData(
                    icon: "figure.run",
                    title: "Peak Performance",
                    recommendation: "Your energy peaks at 2-4 PM - schedule important workouts then",
                    priority: .high
                ),
                RecommendationData(
                    icon: "figure.step.training",
                    title: "Step Goal",
                    recommendation: "Increase daily steps by 500 to reach optimal 10,000 steps",
                    priority: .medium
                ),
                RecommendationData(
                    icon: "sportscourt",
                    title: "Activity Variety",
                    recommendation: "Add strength training 2x/week to complement cardio",
                    priority: .low
                )
            ]
        case .sleep:
            return [
                RecommendationData(
                    icon: "clock",
                    title: "Sleep Schedule",
                    recommendation: "Try going to bed 30 minutes earlier for better recovery",
                    priority: .medium
                ),
                RecommendationData(
                    icon: "moon.zzz",
                    title: "Sleep Quality",
                    recommendation: "Avoid screens 1 hour before bed to improve deep sleep",
                    priority: .high
                ),
                RecommendationData(
                    icon: "bed.double",
                    title: "Sleep Environment",
                    recommendation: "Keep bedroom at 65-68°F for optimal sleep quality",
                    priority: .low
                )
            ]
        case .glucose:
            return [
                RecommendationData(
                    icon: "drop.fill",
                    title: "Blood Sugar Control",
                    recommendation: "Eat protein before carbs to reduce glucose spikes",
                    priority: .high
                ),
                RecommendationData(
                    icon: "fork.knife",
                    title: "Meal Timing",
                    recommendation: "Space meals 4-5 hours apart for stable glucose levels",
                    priority: .medium
                ),
                RecommendationData(
                    icon: "figure.walk.motion",
                    title: "Post-Meal Activity",
                    recommendation: "Take a 10-minute walk after meals to lower glucose",
                    priority: .low
                )
            ]
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Personalized Recommendations")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(selectedType.rawValue)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(8)
            }
            
            VStack(spacing: 16) {
                ForEach(recommendations.indices, id: \.self) { index in
                    RecommendationRow(
                        icon: recommendations[index].icon,
                        title: recommendations[index].title,
                        recommendation: recommendations[index].recommendation,
                        priority: recommendations[index].priority
                    )
                }
            }
        }
    }
}

struct RecommendationData {
    let icon: String
    let title: String
    let recommendation: String
    let priority: RecommendationRow.Priority
}

struct RecommendationRow: View {
    let icon: String
    let title: String
    let recommendation: String
    let priority: Priority
    
    enum Priority {
        case high, medium, low
        
        var color: Color {
            switch self {
            case .high: return .red
            case .medium: return .orange
            case .low: return .green
            }
        }
        
        var text: String {
            switch self {
            case .high: return "High"
            case .medium: return "Medium"
            case .low: return "Low"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.blue)
                .frame(width: 40, height: 40)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Text(recommendation)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Text(priority.text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(priority.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(priority.color.opacity(0.1))
                .cornerRadius(8)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial.opacity(0.2))
        )
    }
}

struct ModernInsightsView_Previews: PreviewProvider {
    static var previews: some View {
        ModernInsightsView()
    }
}