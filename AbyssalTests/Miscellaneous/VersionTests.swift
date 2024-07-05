//
//  VersionTests.swift
//  AbyssalTests
//
//  Created by KrLite on 2024/7/5.
//

import Testing
@testable import Abyssal

struct VersionTests {
    @Test func parseVersion() async throws {
        let versionString = "1.0.0.0-alpha. 2.34 .567 -patch. beta-2, 1 ,2.3"
        let version = Version(from: versionString)
        #expect(version != nil)
        #expect(version?.string == "1.0.0.0.alpha.2.34.567.patch.beta.3")
    }
    
    @Test func parseComponent() async throws {
        let componentString = "42"
        let component = Version.Component(parsing: componentString)
        #expect(component != nil)
        #expect(component == .number(42))
    }
}
