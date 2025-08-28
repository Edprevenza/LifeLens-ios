// ResponsiveHealthDashboard.swift
// Responsive health dashboard matching Android design exactly

import SwiftUI
import Charts

struct ResponsiveHealthDashboard: View {
    var body: some View {
        // Use the modern dashboard design that matches Android
        ModernHealthDashboard()
            .ignoresSafeArea()
    }
}

// Keep the view models and supporting types below
// These remain compatible with the new modern design