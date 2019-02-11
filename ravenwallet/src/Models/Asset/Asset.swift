//
//  Setting.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2017-04-01.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import Foundation

struct Asset {
    var idAsset: Int
    var name: String
    var amount: Satoshis
    var units:UInt8
    var reissubale:UInt8
    var hasIpfs:UInt8
    var ipfsHash:String
    var ownerShip:Int
    var hidden:Int
    var sort:Int
    
    var isHidden:Bool{
        get {
            return hidden == 1 ? true : false
        }
    }
    
    var isOwnerShip:Bool{
        get {
            return ownerShip == 1 ? true : false
        }
    }
    
    var isReissuable:Bool{
        get {
            return reissubale == 1 ? true : false
        }
    }
    
    var isHasIpfs:Bool{
        get {
            return hasIpfs == 1 ? true : false
        }
    }
}

struct AssetName {
    var idAsset: Int
    var name: String
    var ipfsHash:String
    var txHash:String
    var address: String
    var timespan:Int
}
