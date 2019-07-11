//
//  StageBallsProducts.swift
//  ColorBall
//
//  Created by 2AHGK Laurens.Ramsenthaler on 10.07.19.
//  Copyright © 2019 Laurens Ramsenthaler. All rights reserved.
//

import Foundation

public struct StageBallsProducts {
    
    public static let EndlessModeProduct = "1234"
    
    private static let productIdentifiers: Set<ProductIdentifier> = [StageBallsProducts.EndlessModeProduct]
  
    public static let store = IAPHelper(productIds: StageBallsProducts.productIdentifiers)
}

func resourceNameForProductIdentifier(_ productIdentifier: String) -> String? {
    return productIdentifier.components(separatedBy: ".").last
}
