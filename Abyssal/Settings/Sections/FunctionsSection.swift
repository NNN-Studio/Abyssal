//
//  FunctionsSection.swift
//  Abyssal
//
//  Created by KrLite on 2024/6/24.
//

import SwiftUI

struct FunctionsSection: View {
    @Environment(\.hasTitle) private var hasTitle
    
    var body: some View {
        Section {
            UnifiedVStack {
                AutoShowsControl()
                
                AlwaysHideAreaControl()
            }
            
            UnifiedVStack {
                MenuBarOverrideControl()
            }
        } header: {
            if hasTitle {
                Text("Functions")
            }
        }
    }
}

#Preview {
    Form {
        FunctionsSection()
    }
    .formStyle(.grouped)
}
