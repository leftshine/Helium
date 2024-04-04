//
//  FoundationExtensions.swift
//  Helium
//
//  Created by lemin on 10/13/23.
//

import Foundation

extension Bundle {
    var releaseVersionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
}
