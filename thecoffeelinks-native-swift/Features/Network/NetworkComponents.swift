import SwiftUI

// MARK: - Editorial Community Board
struct EditorialCommunityBoardView: View {
    @State private var selectedFilter: String = "ALL"
    // Mock posts
    let posts = [
        Post(id: 1, type: "HIRING", content: "Looking for a Swift developer for a coffee app project!", author: "Nhat Nguyen", time: "2h ago"),
        Post(id: 2, type: "LEARNING", content: "Studying for IELTS today at table 5. Join me?", author: "Sarah Lee", time: "15m ago")
    ]
    
    var body: some View {
        ZStack {
            Color.backgroundTerminal.ignoresSafeArea()
            
            VStack(spacing: 0) {
                 // Filter Bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(["ALL", "HIRING", "LEARNING", "COLLAB", "EVENT"], id: \.self) { type in
                            TerminalFilterButton(title: type, isSelected: selectedFilter == type) {
                                selectedFilter = type
                            }
                        }
                    }
                    .padding(24)
                }
                
                // Posts List
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(posts) { post in
                            TerminalPostCard(post: post)
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
    }
}

struct TerminalFilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(isSelected ? .black : Editorial.Colors.textInk)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Editorial.Colors.primaryEspresso : Color.black)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Editorial.Colors.textInk, lineWidth: 1))
        }
    }
}

struct Post: Identifiable {
    let id: Int, type: String, content: String, author: String, time: String
    
    var typeColor: Color {
        switch type {
        case "HIRING": return .blue
        case "LEARNING": return .orange
        case "COLLAB": return .purple
        case "EVENT": return .green
        default: return Editorial.Colors.primaryEspresso
        }
    }
}

struct TerminalPostCard: View {
    let post: Post
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
             HStack {
                 Text("TYPE :: \(post.type)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(post.typeColor)
                
                 Spacer()
                 
                 Text("TS :: \(post.time.uppercased())")
                     .font(.system(size: 10, design: .monospaced))
                     .foregroundStyle(Editorial.Colors.textMuted)
             }
            
            Text(post.content.uppercased())
                .font(.system(size: 16, design: .monospaced))
                .foregroundStyle(Editorial.Colors.textInk)
                .lineSpacing(4)
            
            Rectangle()
                .fill(Editorial.Colors.separator)
                .frame(height: 1)
            
            HStack(spacing: 12) {
                Rectangle()
                    .fill(Editorial.Colors.surfaceTerminal)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Text(post.author.prefix(1).uppercased())
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(Editorial.Colors.primaryEspresso)
                    )
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Editorial.Colors.separator, lineWidth: 1))
                
                Text(post.author.uppercased())
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(Editorial.Colors.textInk)
                
                Spacer()
                
                Button("[ REPLY ]") {}
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Editorial.Colors.primaryEspresso)
            }
        }
        .padding(20)
        .background(Color.black)
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Editorial.Colors.separator, lineWidth: 1))
    }
}


// MARK: - Legacy Aliases
typealias CommunityBoardView = EditorialCommunityBoardView
typealias PostCard = TerminalPostCard
