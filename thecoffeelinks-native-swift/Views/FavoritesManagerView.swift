//
//  FavoritesManagerView.swift
//  thecoffeelinks-native-swift
//
//  Full-screen manager for favorites and notes.
//  Notes are editable here, read-only in checkout.
//

import SwiftUI

struct FavoritesManagerView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var favoritesService = FavoritesService.shared
    
    @State private var editingFavorite: FavoriteItem?
    @State private var showNoteEditor = false
    @State private var selectedFavoriteForNote: FavoriteItem?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.brandBackground.ignoresSafeArea()
                
                if favoritesService.favorites.isEmpty {
                    emptyState
                } else {
                    favoritesList
                }
            }
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.headline)
                        .foregroundStyle(Color.forestCanopy)
                }
            }
            .sheet(item: $selectedFavoriteForNote) { favorite in
                NoteEditorSheet(favorite: favorite)
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(Color.neutral300)
            
            Text("No favorites yet")
                .font(.headline)
                .foregroundStyle(Color.coffeeDark)
            
            Text("Tap the heart on any product to save it here")
                .font(.subheadline)
                .foregroundStyle(Color.neutral500)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private var favoritesList: some View {
        List {
            ForEach(favoritesService.favorites) { favorite in
                FavoriteRowView(
                    favorite: favorite,
                    onAddNote: {
                        selectedFavoriteForNote = favorite
                    }
                )
                .listRowBackground(Color.white)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
            .onDelete { indexSet in
                for index in indexSet {
                    favoritesService.removeFavorite(favoritesService.favorites[index])
                }
            }
        }
        .listStyle(.plain)
    }
}

struct FavoriteRowView: View {
    let favorite: FavoriteItem
    let onAddNote: () -> Void
    
    @ObservedObject private var favoritesService = FavoritesService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Product info row
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: favorite.product.displayImageUrl ?? "")) { img in
                    img.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.neutral100)
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(favorite.product.name)
                        .font(.headline)
                        .foregroundStyle(Color.forestCanopy)
                    
                    Text("\(favorite.customization.size) • \(favorite.customization.sugar ?? "Normal") sugar")
                        .font(.caption)
                        .foregroundStyle(Color.neutral600)
                    
                    Text("Ordered \(favorite.orderCount) times")
                        .font(.caption2)
                        .foregroundStyle(Color.neutral500)
                }
                
                Spacer()
                
                Text(favorite.priceForSize.toVND())
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.sunRay)
            }
            
            // Notes section
            if !favorite.notes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(favorite.notes) { note in
                        NoteRow(
                            note: note,
                            onToggle: {
                                favoritesService.toggleNoteActive(favoriteId: favorite.id, noteId: note.id)
                            },
                            onDelete: {
                                favoritesService.removeNote(favoriteId: favorite.id, noteId: note.id)
                            }
                        )
                    }
                }
            }
            
            // Add note button
            if favorite.notes.count < 3 {
                Button {
                    onAddNote()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 14))
                        Text("Add note")
                            .font(.caption)
                    }
                    .foregroundStyle(Color.forestCanopy)
                }
            }
            
            // Suggested notes (auto-generated)
            if let suggested = favoritesService.suggestedNotes[favorite.product.id] {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.sunRay)
                    
                    Text(suggested)
                        .font(.caption)
                        .foregroundStyle(Color.neutral600)
                    
                    Spacer()
                    
                    Button {
                        favoritesService.addNote(to: favorite.id, text: suggested)
                    } label: {
                        Text("Save")
                            .font(.caption.bold())
                            .foregroundStyle(Color.forestCanopy)
                    }
                }
                .padding(10)
                .background(Color.sunRay.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
    }
}

struct NoteRow: View {
    let note: FavoriteNote
    let onToggle: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 10) {
            // Active toggle
            Button {
                onToggle()
            } label: {
                Image(systemName: note.isActive ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundStyle(note.isActive ? Color.forestCanopy : Color.neutral400)
            }
            
            // Note text
            VStack(alignment: .leading, spacing: 2) {
                Text(note.text)
                    .font(.caption)
                    .foregroundStyle(note.isActive ? Color.coffeeDark : Color.neutral500)
                    .strikethrough(!note.isActive)
                
                if note.isAutoGenerated {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 8))
                        Text("Auto-detected")
                            .font(.system(size: 9))
                    }
                    .foregroundStyle(Color.sunRay)
                }
            }
            
            Spacer()
            
            // Delete
            Button {
                onDelete()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.neutral400)
                    .frame(width: 20, height: 20)
                    .background(Color.neutral100)
                    .clipShape(Circle())
            }
        }
        .padding(10)
        .background(Color.neutral50)
        .cornerRadius(8)
    }
}

// MARK: - Note Editor Sheet

struct NoteEditorSheet: View {
    let favorite: FavoriteItem
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var favoritesService = FavoritesService.shared
    
    @State private var noteText = ""
    @FocusState private var isFocused: Bool
    
    private let maxLength = 140
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Product preview
                HStack(spacing: 12) {
                    AsyncImage(url: URL(string: favorite.product.displayImageUrl ?? "")) { img in
                        img.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.neutral100)
                    }
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    VStack(alignment: .leading) {
                        Text(favorite.displayName)
                            .font(.headline)
                        Text("Add a personal note")
                            .font(.caption)
                            .foregroundStyle(Color.neutral500)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color.neutral50)
                .cornerRadius(12)
                
                // Text input
                VStack(alignment: .leading, spacing: 8) {
                    TextEditor(text: $noteText)
                        .frame(height: 100)
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.neutral200, lineWidth: 1)
                        )
                        .focused($isFocused)
                        .onChange(of: noteText) { newValue in
                            if newValue.count > maxLength {
                                noteText = String(newValue.prefix(maxLength))
                            }
                        }
                    
                    HStack {
                        Text("Examples: \"Less sweet\", \"For meetings\", \"Don't add ice on cold days\"")
                            .font(.caption)
                            .foregroundStyle(Color.neutral500)
                        
                        Spacer()
                        
                        Text("\(noteText.count)/\(maxLength)")
                            .font(.caption)
                            .foregroundStyle(noteText.count >= maxLength ? Color.red : Color.neutral400)
                    }
                }
                
                Spacer()
                
                // Save button
                Button {
                    if !noteText.isEmpty {
                        favoritesService.addNote(to: favorite.id, text: noteText)
                    }
                    dismiss()
                } label: {
                    Text("Save Note")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(noteText.isEmpty ? Color.neutral300 : Color.forestCanopy)
                        .cornerRadius(14)
                }
                .disabled(noteText.isEmpty)
            }
            .padding()
            .navigationTitle("Add Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                isFocused = true
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Previews

#Preview("Favorites Manager") {
    FavoritesManagerView()
}
