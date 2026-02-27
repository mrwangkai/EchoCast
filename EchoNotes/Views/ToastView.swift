//
//  ToastView.swift
//  EchoNotes
//
//  Toast notification component
//

import SwiftUI

struct ToastMessage: Equatable {
    let message: String
    let icon: String
}

struct ToastView: View {
    let toast: ToastMessage

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: toast.icon)
                .font(.system(size: 14, weight: .semibold))
            Text(toast.message)
                .font(.system(size: 14, weight: .medium))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.8))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
    }
}
