//
//  Untitled.swift
//  OcrApp
//
//  Created by Mudassir Abbas on 06/03/2025.
//
import AVFoundation

struct TextGroup {
    let textElements: [TextElementWithRect]
    let rect: CGRect
}

struct TextElementWithRect {
    let text: String
    let rect: CGRect
    let x: Int
    let y: Int
}
