//
//  CIImage+Rendering.swift
//  FilterCraftCore
//
//  Created by Cole Draper McNee on 8/27/25.
//

import CoreImage
#if canImport(UIKit)
import UIKit
#endif

public extension CIContext {
    static let shared: CIContext = {
        let options: [CIContextOption: Any] = [:] // customize if needed
        return CIContext(options: options)
    }()
}

public extension CIImage {
    
    /// Converts CIImage to CGImage using a provided or shared CIContext
    func toCGImage(using context: CIContext = CIContext.shared) -> CGImage? {
        return context.createCGImage(self, from: extent)
    }

    #if canImport(UIKit)
    /// Converts CIImage to UIImage
    func toUIImage(using context: CIContext = CIContext.shared) -> UIImage? {
        guard let cgImage = toCGImage(using: context) else { return nil }
        return UIImage(cgImage: cgImage)
    }
    #endif
}
