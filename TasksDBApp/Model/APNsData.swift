//
//  ApnsData.swift
//  TasksDBApp
//
//  Created by Kyrylo Derkach on 24.10.2023.
//

import Foundation

// MARK: - APNs structure for decoding with more parameters
struct APNsData: Codable {
    let aps: APNsDataAps
}
struct APNsDataAps: Codable {
    let alert: APNsDataApsAlert
    let badge: Int
    let category: String
    let sound: APNsDataApsSound
}
struct APNsDataApsAlert: Codable {
    let title: String
    let body: String
}
struct APNsDataApsSound: Codable {
    let critical: Int
    let name: String
    let volume: Double
}
