//
//  TagInputView.swift
//  EchoNotes
//
//  Reusable tag input component with autocomplete and token chips
//

import SwiftUI

/// Reusable tag input component for notes
struct TagInputView: View {
    @Binding var selectedTags: [String]
    let allExistingTags: [String]

    @State private var inputText = ""
    @State private var showSuggestions = false
    @FocusState private var isInputFocused: Bool

    // Filter suggestions based on input
    private var filteredSuggestions: [String] {
        guard !inputText.isEmpty else {
            // Show recent/frequent tags when no input
            return Array(allExistingTags.prefix(5))
        }

        let trimmed = inputText.trimmingCharacters(in: .whitespaces).lowercased()
        return allExistingTags.filter { tag in
            tag.lowercased().contains(trimmed) && !selectedTags.contains(tag)
        }
    }

    private var shouldShowCreateOption: Bool {
        let trimmed = inputText.trimmingCharacters(in: .whitespaces)
        return !trimmed.isEmpty &&
               !selectedTags.contains(trimmed) &&
               !allExistingTags.contains(trimmed)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Tag tokens (chips) - wrapped layout
            if !selectedTags.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(selectedTags, id: \.self) { tag in
                        TagChip(tag: tag) {
                            removeTag(tag)
                        }
                    }
                }
            }

            // Input field
            HStack(spacing: 8) {
                Image(systemName: "tag")
                    .foregroundColor(.echoTextSecondary)
                    .font(.body)

                TextField("Add tag", text: $inputText)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .focused($isInputFocused)
                    .onSubmit {
                        addTag(inputText)
                    }
                    .onChange(of: inputText) { _, _ in
                        showSuggestions = true
                    }

                if !inputText.isEmpty {
                    Button(action: {
                        addTag(inputText)
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.searchFieldBackground)
            .cornerRadius(10)

            // Autocomplete suggestions
            if showSuggestions && isInputFocused && (!filteredSuggestions.isEmpty || shouldShowCreateOption) {
                VStack(alignment: .leading, spacing: 0) {
                    // "Create new tag" option
                    if shouldShowCreateOption {
                        Button(action: {
                            addTag(inputText)
                        }) {
                            HStack {
                                Image(systemName: "plus.circle")
                                    .foregroundColor(.blue)
                                Text("Create tag \"\(inputText.trimmingCharacters(in: .whitespaces))\"")
                                    .foregroundColor(.echoTextPrimary)
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                        }

                        if !filteredSuggestions.isEmpty {
                            Divider()
                        }
                    }

                    // Existing tag suggestions
                    ForEach(filteredSuggestions, id: \.self) { tag in
                        Button(action: {
                            selectExistingTag(tag)
                        }) {
                            HStack {
                                Image(systemName: "tag")
                                    .foregroundColor(.echoTextSecondary)
                                Text(tag)
                                    .foregroundColor(.echoTextPrimary)
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                        }

                        if tag != filteredSuggestions.last {
                            Divider()
                        }
                    }
                }
                .background(Color.noteCardBackground)
                .cornerRadius(10)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
            }
        }
    }

    private func addTag(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !selectedTags.contains(trimmed) else { return }

        withAnimation(.spring(response: 0.3)) {
            selectedTags.append(trimmed)
        }
        inputText = ""
        showSuggestions = false
    }

    private func selectExistingTag(_ tag: String) {
        guard !selectedTags.contains(tag) else { return }

        withAnimation(.spring(response: 0.3)) {
            selectedTags.append(tag)
        }
        inputText = ""
        showSuggestions = false
    }

    private func removeTag(_ tag: String) {
        withAnimation(.spring(response: 0.3)) {
            selectedTags.removeAll { $0 == tag }
        }
    }
}

/// Tag chip component
struct TagChip: View {
    let tag: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.subheadline)
                .foregroundColor(.blue)

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.blue.opacity(0.6))
            }
            .accessibilityLabel("Remove tag \(tag)")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(16)
    }
}

// Note: FlowLayout is defined in ContentView.swift and reused here

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedTags = ["productivity", "ideas"]
        let allTags = ["productivity", "ideas", "work", "personal", "meeting", "todo"]

        var body: some View {
            Form {
                Section(header: Text("Tags")) {
                    TagInputView(
                        selectedTags: $selectedTags,
                        allExistingTags: allTags
                    )
                }
            }
        }
    }

    return PreviewWrapper()
}
