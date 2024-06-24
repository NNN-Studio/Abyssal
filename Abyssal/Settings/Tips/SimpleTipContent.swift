//
//  SimpleTipContent.swift
//  Abyssal
//
//  Created by KrLite on 2024/6/23.
//

import SwiftUI
import SwiftUIIntrospect

struct SimpleTipContent<Content>: View where Content: View {
    @ViewBuilder var content: () -> Content
    
    @State private var size: CGSize = .zero
    
    var body: some View {
        content()
            .padding()
    }
}