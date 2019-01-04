//
//  Constants.swift
//  Sandbox
//
//  Created by Wataru Nagasawa on 11/1/18.
//  Copyright © 2018 junkapp. All rights reserved.
//

import UIKit

struct Constants {

    struct AppInfo {
        static let bundleIdentifier = Bundle.main.infoDictionary!["CFBundleIdentifier"] as! String
        static let version = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        static let name = Bundle.main.infoDictionary!["CFBundleName"] as! String
        static let displayName = Bundle.main.infoDictionary!["CFBundleDisplayName"] as! String
        static let UUID = UIDevice.current.identifierForVendor!.uuidString
        static let customURLScheme: String = {
            let types = Bundle.main.infoDictionary!["CFBundleURLTypes"] as! [[String: Any]]
            let type = types.first(where: { $0["CFBundleURLName"] != nil && ($0["CFBundleURLName"] as! String) == bundleIdentifier })!
            return (type["CFBundleURLSchemes"] as! [String])[0]
        }()
    }
}
