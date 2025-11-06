//
//  DeviceTypeUtil.swift
//  AirSync
//
//  FIXED VERSION - Corrects device detection for newer Macs
//  Replace: airsync-mac/Core/Util/DeviceTypeUtil.swift
//

import Foundation

enum DeviceTypeUtil {
    private static var deviceMappings: [String: [String: String]] = {
        guard let url = Bundle.main.url(forResource: "MacDeviceMappings", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: [String: String]] else {
            return [:]
        }
        return json
    }()

    static func modelIdentifier() -> String {
        var size: size_t = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var model = [CChar](repeating: 0, count: Int(size))
        sysctlbyname("hw.model", &model, &size, nil, 0)
        return String(cString: model)
    }

    static func deviceTypeDescription() -> String {
        let identifier = modelIdentifier()
        
        // CRITICAL FIX: Check mappings first before fallback logic
        for (category, models) in deviceMappings {
            if models.keys.contains(identifier) {
                return category
            }
        }
        
        // Enhanced fallback logic for newer Macs using "Mac" prefix
        // Mac16,x = M4 generation (2024-2025)
        // Mac15,x = M3 generation (2023-2024)
        // Mac14,x = M2 generation (2022-2023)
        if identifier.hasPrefix("Mac") {
            // Extract the model number (e.g., "Mac16,12" -> 16)
            let components = identifier.split(separator: ",")
            if let firstPart = components.first,
               let modelNum = Int(firstPart.dropFirst(3)) { // Drop "Mac" prefix
                
                // Mac16,12-13 = MacBook Air M4 (2025)
                if modelNum == 16 {
                    if identifier == "Mac16,12" || identifier == "Mac16,13" {
                        return "MacBook Air"
                    }
                    // Mac16,1-2, Mac16,5-8 = MacBook Pro M4 (2024)
                    else if [1, 2, 5, 6, 7, 8].contains(Int(components.last ?? "0") ?? 0) {
                        return "MacBook Pro"
                    }
                    // Mac16,10-11 = Mac mini M4 (2024)
                    else if identifier == "Mac16,10" || identifier == "Mac16,11" {
                        return "Mac mini"
                    }
                    // Mac16,13-15 = Mac Studio/Pro M4 (2024)
                    else if [13, 14, 15].contains(Int(components.last ?? "0") ?? 0) {
                        return "Mac Studio"
                    }
                }
                // Mac15,12-13 = MacBook Air M3 (2024)
                else if modelNum == 15 {
                    if identifier == "Mac15,12" || identifier == "Mac15,13" {
                        return "MacBook Air"
                    }
                    // Mac15,3 and Mac15,6-11 = MacBook Pro M3 (2023)
                    else {
                        return "MacBook Pro"
                    }
                }
                // Mac14,2 and Mac14,5 = MacBook Air M2 (2022-2023)
                else if modelNum == 14 {
                    if identifier == "Mac14,2" || identifier == "Mac14,5" {
                        return "MacBook Air"
                    }
                    // Mac14,7, Mac14,9-10 = MacBook Pro M2 (2022-2023)
                    else if [7, 9, 10].contains(Int(components.last ?? "0") ?? 0) {
                        return "MacBook Pro"
                    }
                    // Mac14,3 and Mac14,12 = Mac mini M2 (2022-2023)
                    else if identifier == "Mac14,3" || identifier == "Mac14,12" {
                        return "Mac mini"
                    }
                    // Mac14,13-14 = Mac Studio M2 (2023)
                    else {
                        return "Mac Studio"
                    }
                }
            }
        }
        
        // Original fallback for older identifiers
        if identifier.starts(with: "MacBookPro") {
            return "MacBook Pro"
        } else if identifier.starts(with: "MacBookAir") {
            return "MacBook Air"
        } else if identifier.starts(with: "Macmini") {
            return "Mac mini"
        } else if identifier.starts(with: "iMac") {
            return "iMac"
        } else if identifier.starts(with: "MacStudio") {
            return "Mac Studio"
        } else if identifier.starts(with: "MacPro") {
            return "Mac Pro"
        } else {
            // Unknown identifier - log it for debugging
            print("[device-util] Unknown Mac model identifier: \(identifier)")
            // Try to guess based on common patterns
            if identifier.lowercased().contains("air") {
                return "MacBook Air"
            } else if identifier.lowercased().contains("book") {
                return "MacBook Pro"
            } else if identifier.lowercased().contains("mini") {
                return "Mac mini"
            } else if identifier.lowercased().contains("imac") {
                return "iMac"
            } else if identifier.lowercased().contains("studio") {
                return "Mac Studio"
            } else if identifier.lowercased().contains("pro") {
                return "Mac Pro"
            }
            return identifier // fallback to raw model id
        }
    }

    static func deviceFullDescription() -> String {
        let identifier = modelIdentifier()
        
        // Check mappings first
        for (_, models) in deviceMappings {
            if let name = models[identifier] {
                return name
            }
        }
        
        // Fallback to type description
        return deviceTypeDescription()
    }

    static func deviceIconName() -> String {
        let identifier = modelIdentifier()
        
        // First, look for an explicit per-model icon key in any category
        for (_, models) in deviceMappings {
            if let icon = models["\(identifier)_icon"] {
                return icon
            }
        }
        
        // Next, use category-based defaults
        let type = deviceTypeDescription()
        switch type {
        case "MacBook Pro", "MacBook Air":
            return "macbook"
        case "Mac mini":
            return "macmini"
        case "iMac":
            return "desktopcomputer"
        case "Mac Studio":
            return "macstudio"
        case "Mac Pro":
            return "macpro.gen3"
        default:
            return "desktopcomputer"
        }
    }
    
    /// Check if the current Mac has a battery (i.e., is a portable Mac)
    static func hasBattery() -> Bool {
        let type = deviceTypeDescription()
        // Only MacBook Air and MacBook Pro have batteries
        return type == "MacBook Air" || type == "MacBook Pro"
    }
}
