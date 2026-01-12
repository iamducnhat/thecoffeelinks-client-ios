//
//  PointsView.swift
//  thecoffeelinks-native-swift
//
//  Created by AppCafe on 2026-01-12.
//

import SwiftUI

struct PointsView: View {
    @StateObject private var viewModel = PointsViewModel()
    
    var body: some View {
        VStack(spacing: 32) {
            Text("Loyalty")
                .font(.brandSerif(24))
                .foregroundStyle(Color.coffeeDark)
                .padding(.top)
            
            if viewModel.viewState == .loading && viewModel.points == 0 {
                ProgressView()
            } else {
                // Progress Visualization
                ZStack {
                    // Background Track
                    Circle()
                        .stroke(Color.coffeeRich.opacity(0.1), lineWidth: 20)
                        .frame(width: 220, height: 220)
                    
                    // Fill
                    Circle()
                        .trim(from: 0, to: viewModel.progressToNext)
                        .stroke(
                            AngularGradient(
                                colors: [.caramel, .gold],
                                center: .center,
                                startAngle: .degrees(0),
                                endAngle: .degrees(360)
                            ),
                            style: StrokeStyle(lineWidth: 20, lineCap: .round)
                        )
                        .frame(width: 220, height: 220)
                        .rotationEffect(.degrees(-90))
                    
                    // Content
                    VStack(spacing: 4) {
                        Text("\(viewModel.points)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.coffeeDark)
                        
                        if let next = viewModel.nextTier {
                            Text("/ \(next.minPoints)")
                                .font(.brandSans(16))
                                .foregroundStyle(Color.secondary)
                        } else {
                            Text("MAX")
                                .font(.brandSans(16))
                                .foregroundStyle(Color.gold)
                        }
                    }
                }
                .onAppear {
                    // Constraint: Only animate smoothly, don't overdo it unless it's a new milestone
                    // Animation handled by swiftui state change automatically if value changes
                }
                .animation(.easeOut(duration: 1.5), value: viewModel.progressToNext)
                
                VStack(spacing: 8) {
                    if let next = viewModel.nextTier {
                        Text("\(next.minPoints - viewModel.points) Points to \(next.name) Status")
                            .font(.brandSans(16))
                            .fontWeight(.medium)
                            .foregroundStyle(Color.coffeeDark)
                    } else {
                        Text("You are \(viewModel.currentTier.name)!")
                            .font(.brandSans(16))
                            .fontWeight(.bold)
                            .foregroundStyle(Color.gold)
                    }
                    
                    Text("Unlock free refills and priority seating.")
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color.brandBackground)
        .task {
            await viewModel.fetchPoints()
        }
    }
}

#Preview {
    PointsView()
}
