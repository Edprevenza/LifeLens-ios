//
//  ModernInsightsViewFixed.swift
//  LifeLens
//
//  Responsive and Progressive Insights view with fixed alignment
//

import SwiftUI

struct ModernInsightsView: View {
    @StateObject private var viewModel = HealthDashboardViewModel()
    @State private var selectedInsightType: InsightType = .sleep
    @State private var isLoading = true
    @State private var loadedSections = Set<String>()
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    var isCompact: Bool {
        horizontalSizeClass == .compact
    }
    
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
            
            if isLoading {
                ProgressView("Loading Health Insights...")
                    .foregroundColor(.white)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isLoading = false
                            }
                        }
                    }
            } else {
                VStack(spacing: 0) {
                    // Header - Always visible at top
                    InsightsHeader()
                        .padding(.horizontal, isCompact ? 16 : 20)
                        .padding(.top, isCompact ? 50 : 60)
                        .padding(.bottom, isCompact ? 16 : 20)
                    
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: isCompact ? 20 : 28) {
                        
                        // Health Score
                        HealthScoreSection(viewModel: viewModel, isCompact: isCompact)
                            .padding(.horizontal, isCompact ? 16 : 20)
                            .opacity(loadedSections.contains("score") ? 1 : 0)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 0.3).delay(0.1)) {
                                    _ = loadedSections.insert("score")
                                }
                            }
                        
                        // Insights Grid
                        InsightsGrid(selectedType: $selectedInsightType, isCompact: isCompact)
                            .padding(.horizontal, isCompact ? 16 : 20)
                            .opacity(loadedSections.contains("grid") ? 1 : 0)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 0.3).delay(0.2)) {
                                    _ = loadedSections.insert("grid")
                                }
                            }
                        
                        // Recommendations
                        RecommendationsSection(selectedType: selectedInsightType, isCompact: isCompact)
                            .padding(.horizontal, isCompact ? 16 : 20)
                            .padding(.bottom, 100)
                            .opacity(loadedSections.contains("recommendations") ? 1 : 0)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 0.3).delay(0.3)) {
                                    _ = loadedSections.insert("recommendations")
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct InsightsHeader: View {
    @State private var selectedPeriod = "Week"
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var isCompact: Bool {
        horizontalSizeClass == .compact
    }
    
    var body: some View {
        VStack(spacing: isCompact ? 10 : 14) {
            // Title centered with bigger size
            Text("Health Insights")
                .font(.system(size: isCompact ? 28 : 32, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
            
            Text("AI-powered health analysis")
                .font(.system(size: isCompact ? 13 : 15))
                .foregroundColor(Color.white.opacity(0.6))
                .frame(maxWidth: .infinity)
            
            // Time Period Selector
            HStack(spacing: isCompact ? 2 : 4) {
                ForEach(["Day", "Week", "Month"], id: \.self) { period in
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            selectedPeriod = period
                        }
                    }) {
                        Text(period)
                            .font(.system(size: isCompact ? 12 : 13, weight: .medium))
                            .foregroundColor(selectedPeriod == period ? .white : Color.white.opacity(0.5))
                            .padding(.horizontal, isCompact ? 16 : 20)
                            .padding(.vertical, isCompact ? 8 : 10)
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
    let isCompact: Bool
    @State private var animateScore = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? 16 : 20) {
            Text("Overall Health Score")
                .font(.system(size: isCompact ? 18 : 20, weight: .semibold))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
            
            Group {
                if isCompact {
                    // Vertical layout for compact size
                    VStack(spacing: 20) {
                        // Score Circle
                        ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                            .frame(width: 100, height: 100)
                        
                        Circle()
                            .trim(from: 0, to: animateScore ? 0.92 : 0)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.green, Color.blue]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 6, lineCap: .round)
                            )
                            .frame(width: 100, height: 100)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 1.5), value: animateScore)
                        
                        VStack(spacing: 2) {
                            Text("92")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                            Text("Excellent")
                                .font(.system(size: 11))
                                .foregroundColor(.green)
                        }
                    }
                    
                    // Score Breakdown
                    VStack(alignment: .leading, spacing: 12) {
                        HealthMetricRow(label: "Heart Health", score: 95, color: .red, isCompact: isCompact)
                        HealthMetricRow(label: "Blood Sugar", score: 88, color: .purple, isCompact: isCompact)
                        HealthMetricRow(label: "Activity Level", score: 94, color: .blue, isCompact: isCompact)
                        HealthMetricRow(label: "Sleep Quality", score: 91, color: .indigo, isCompact: isCompact)
                    }
                    .frame(maxWidth: .infinity)
                    }
                } else {
                // Horizontal layout for regular size
                HStack(spacing: 40) {
                    // Score Circle
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                            .frame(width: 120, height: 120)
                        
                        Circle()
                            .trim(from: 0, to: animateScore ? 0.92 : 0)
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
                            .animation(.easeInOut(duration: 1.5), value: animateScore)
                        
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
                        HealthMetricRow(label: "Heart Health", score: 95, color: .red, isCompact: isCompact)
                        HealthMetricRow(label: "Blood Sugar", score: 88, color: .purple, isCompact: isCompact)
                        HealthMetricRow(label: "Activity Level", score: 94, color: .blue, isCompact: isCompact)
                        HealthMetricRow(label: "Sleep Quality", score: 91, color: .indigo, isCompact: isCompact)
                    }
                    
                    Spacer()
                }
                }
            }
            .padding(isCompact ? 16 : 24)
            .background(
                RoundedRectangle(cornerRadius: isCompact ? 16 : 24)
                    .fill(.ultraThinMaterial.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: isCompact ? 16 : 24)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .onAppear {
            animateScore = true
        }
    }
}

struct HealthMetricRow: View {
    let label: String
    let score: Int
    let color: Color
    let isCompact: Bool
    
    var body: some View {
        HStack(spacing: isCompact ? 8 : 12) {
            Text(label)
                .font(.system(size: isCompact ? 13 : 14))
                .foregroundColor(.white)
                .frame(width: isCompact ? 90 : 100, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            
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
                .font(.system(size: isCompact ? 13 : 14, weight: .medium))
                .foregroundColor(color)
                .frame(width: 30, alignment: .trailing)
                .fixedSize()
        }
    }
}

struct InsightsGrid: View {
    @Binding var selectedType: ModernInsightsView.InsightType
    let isCompact: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? 16 : 20) {
            Text("Key Insights")
                .font(.system(size: isCompact ? 18 : 20, weight: .semibold))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: isCompact ? 12 : 16),
                GridItem(.flexible(), spacing: isCompact ? 12 : 16)
            ], spacing: isCompact ? 12 : 20) {
                InsightCard(
                    icon: "heart.fill",
                    title: "Heart Rate Trend",
                    insight: "Your resting heart rate has improved by 5% this week",
                    trend: .up,
                    color: .red,
                    insightType: .heartRate,
                    selectedType: $selectedType,
                    isCompact: isCompact
                )
                
                InsightCard(
                    icon: "figure.walk",
                    title: "Activity Pattern",
                    insight: "You're most active between 2-4 PM daily",
                    trend: .neutral,
                    color: .green,
                    insightType: .activity,
                    selectedType: $selectedType,
                    isCompact: isCompact
                )
                
                InsightCard(
                    icon: "moon.fill",
                    title: "Sleep Quality",
                    insight: "Deep sleep increased by 15 minutes on average",
                    trend: .up,
                    color: .purple,
                    insightType: .sleep,
                    selectedType: $selectedType,
                    isCompact: isCompact
                )
                
                InsightCard(
                    icon: "drop.fill",
                    title: "Glucose Control",
                    insight: "Post-meal spikes are within healthy range",
                    trend: .neutral,
                    color: .orange,
                    insightType: .glucose,
                    selectedType: $selectedType,
                    isCompact: isCompact
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
    let isCompact: Bool
    
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
            VStack(alignment: .leading, spacing: isCompact ? 12 : 16) {
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
                            .frame(width: isCompact ? 32 : 40, height: isCompact ? 32 : 40)
                        
                        Image(systemName: icon)
                            .font(.system(size: isCompact ? 16 : 20))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(trend.color.opacity(0.2))
                            .frame(width: isCompact ? 24 : 30, height: isCompact ? 24 : 30)
                        
                        Image(systemName: trend.icon)
                            .font(.system(size: isCompact ? 12 : 14, weight: .semibold))
                            .foregroundColor(trend.color)
                    }
                }
                
                Text(title)
                    .font(.system(size: isCompact ? 15 : 18, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(insight)
                    .font(.system(size: isCompact ? 12 : 14))
                    .foregroundColor(Color.white.opacity(0.7))
                    .lineLimit(showDetail ? nil : 2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: false)
                
                if showDetail {
                    HStack(spacing: 4) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: isCompact ? 10 : 12))
                            .foregroundColor(color)
                        Text("View Details")
                            .font(.system(size: isCompact ? 10 : 12, weight: .medium))
                            .foregroundColor(color)
                    }
                    .padding(.top, isCompact ? 4 : 8)
                }
            }
            .padding(isCompact ? 14 : 20)
            .frame(minHeight: isCompact ? 140 : 160)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: isCompact ? 16 : 20)
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
                    
                    RoundedRectangle(cornerRadius: isCompact ? 16 : 20)
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
            .shadow(color: color.opacity(0.2), radius: isCompact ? 6 : 10, x: 0, y: isCompact ? 3 : 5)
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
    let isCompact: Bool
    
    var recommendations: [RecommendationData] {
        switch selectedType {
        case .heartRate:
            return [
                RecommendationData(
                    icon: "heart.text.square",
                    title: "Cardio Health",
                    recommendation: "Your heart rate variability suggests good cardiac fitness. Maintain current exercise routine",
                    priority: .low
                )
            ]
        case .activity:
            return [
                RecommendationData(
                    icon: "figure.run",
                    title: "Peak Performance",
                    recommendation: "Your energy peaks at 2-4 PM - schedule important workouts then",
                    priority: .high
                )
            ]
        case .sleep:
            return [
                RecommendationData(
                    icon: "moon.zzz",
                    title: "Sleep Quality",
                    recommendation: "Avoid screens 1 hour before bed to improve deep sleep",
                    priority: .high
                )
            ]
        case .glucose:
            return [
                RecommendationData(
                    icon: "drop.fill",
                    title: "Blood Sugar Control",
                    recommendation: "Eat protein before carbs to reduce glucose spikes",
                    priority: .high
                )
            ]
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? 12 : 16) {
            Text("Recommendations")
                .font(.system(size: isCompact ? 18 : 20, weight: .semibold))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
            
            ForEach(recommendations, id: \.title) { recommendation in
                RecommendationCard(data: recommendation, isCompact: isCompact)
            }
        }
    }
}

struct RecommendationCard: View {
    let data: RecommendationData
    let isCompact: Bool
    
    var body: some View {
        HStack(spacing: isCompact ? 12 : 16) {
            Image(systemName: data.icon)
                .font(.system(size: isCompact ? 20 : 24))
                .foregroundColor(data.priority.color)
                .frame(width: isCompact ? 40 : 50, height: isCompact ? 40 : 50)
                .background(data.priority.color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(data.title)
                    .font(.system(size: isCompact ? 14 : 16, weight: .semibold))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(data.recommendation)
                    .font(.system(size: isCompact ? 12 : 14))
                    .foregroundColor(Color.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: false)
                    .lineLimit(3)
            }
            
            Spacer()
        }
        .padding(isCompact ? 12 : 16)
        .background(
            RoundedRectangle(cornerRadius: isCompact ? 12 : 16)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: isCompact ? 12 : 16)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
    }
}

struct RecommendationData {
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
    }
}