//
//  Alert.swift
//  BuildAnalyzer
//
//  Created by Bartosz Polaczyk on 9/11/23.
//

import SwiftUI

extension View {
    @ViewBuilder func errorAlert<E>(error: Binding<E?>, buttonTitle: LocalizedStringKey = "OK", action: (() -> Void)? = nil) -> some View where E: LocalizedError{
        let errorValue = error.wrappedValue
        alert(isPresented: .constant(errorValue != nil), error: errorValue) { _ in
            Button(buttonTitle) {
                action?()
                error.wrappedValue = nil
            }
        } message: { error in
            Text([error.failureReason, error.recoverySuggestion].compactMap({$0}).joined(separator: "\n\n"))
        }
    }
}
