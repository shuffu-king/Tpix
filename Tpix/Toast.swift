//
//  Toast.swift
//  Tpix
//
//  Created by Ayo Shafau on 11/28/24.
//

import SwiftUI

struct ToastView: View {
    let message: String
    
    var body: some View {
        Text(message)
            .padding()
            .background(Color.black.opacity(0.7))
            .foregroundColor(.white)
            .cornerRadius(8)
            .padding()
            .transition(.move(edge: .bottom))
    }
}

extension View {
    func toast(isPresented: Binding<Bool>, message: String) -> some View {
        self.overlay(
            Group {
                if isPresented.wrappedValue {
                    ToastView(message: message)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                isPresented.wrappedValue = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                isPresented.wrappedValue = false
                            }
                        }
                }
            }
        )
    }
}
