//
//  VendingMachine.swift
//  VendingMachine
//
//  Created by hardik Pans on 5/11/18.
//  Copyright © 2018 Hardik. All rights reserved.
//

import Foundation
import UIKit

// Protocols


protocol VendingMachineType {
    var selection: [VendingSelection] { get }
    var inventory: [VendingSelection: ItemType] { get set }
    var amountDeposited: Double { get set }
    
    init(inventory: [VendingSelection: ItemType])
    func vend(selection: VendingSelection, quantity: Double) throws
    func deposit(amount: Double)
    func itemForCurrentSelection(selection: VendingSelection) -> ItemType?
}

protocol ItemType {
    var price: Double { get }
    var quantity: Double { get set }
}

// Error Types

enum InventoryError: Error {
    case InvalidResource
    case ConversionError
    case Invalidkey
}

enum VendingMachineError: Error {
    case InvalidSelection
    case OutOfStock
    case InsufficientFunds(required: Double)
}

// Helper Classes

class PlistConverter {
    class func dictionaryFromFile(resource: String, ofType type: String) throws -> [String : AnyObject] {
        
        guard let path = Bundle.main.path(forResource: resource, ofType: type) else {
             throw InventoryError.InvalidResource
            }
        
        guard let dictionary = NSDictionary(contentsOfFile: path), let castDictionary = dictionary as? [String: AnyObject] else {
            throw InventoryError.ConversionError
        }
        
        return castDictionary
     }
}


class InventoryUnarchiver {
    class func VendingInventoryFromDictionary(dictionary: [String : AnyObject]) throws -> [VendingSelection : ItemType]{
        
        var inventory: [VendingSelection : ItemType] = [:]
        
        for (key, value) in dictionary {
            if let itemDict = value as? [String : Double],
               let price = itemDict["price"], let quantity = itemDict["quantity"] {
                
                let item = VendingItem(price: price, quantity: quantity)
                print(item)
                guard let key = VendingSelection(rawValue: key) else {
                    throw InventoryError.Invalidkey
                }
                
                inventory.updateValue(item, forKey: key)
            }
        }
        
        return inventory
    }
}

// Concrete Types

enum VendingSelection : String {
    case soda
    case dietSoda
    case chips
    case cookie
    case sandwich
    case wrap
    case candyBar
    case popTart
    case water
    case fruitJuice
    case sportsDrink
    case gum
    
    func icon() -> UIImage {
        if let image = UIImage(named: self.rawValue) {
            return image
        } else {
            return UIImage(named: "Default")!
        }
    }
    
}

struct VendingItem: ItemType {
    let price: Double
    var quantity: Double
}

class VendingMachine: VendingMachineType {
    let selection: [VendingSelection] = [.soda, .dietSoda, .chips, .cookie, .sandwich, .wrap, .candyBar, .popTart, .water, .fruitJuice, .sportsDrink, .gum]
    var inventory: [VendingSelection : ItemType]
    var amountDeposited: Double = 10.0
    
    required init(inventory: [VendingSelection : ItemType]) {
        self.inventory = inventory

    }
    
    func vend(selection: VendingSelection, quantity: Double)  throws {
        guard var item = inventory[selection] else {
            throw VendingMachineError.InvalidSelection
        }
        
        guard item.quantity > 0 else {
            throw VendingMachineError.OutOfStock
        }
        
        item.quantity -= quantity
        inventory.updateValue(item, forKey: selection)
        
        let totalPrice = item.price * quantity
        if amountDeposited >= totalPrice {
            amountDeposited -= totalPrice
        } else {
            let amountRequired = totalPrice - amountDeposited
            throw VendingMachineError.InsufficientFunds(required: amountRequired)
        }
        
    }
    
    func itemForCurrentSelection(selection: VendingSelection) ->
        ItemType? {
         return inventory[selection]
    }
    
    
    func deposit(amount: Double) {
        amountDeposited += amount
    }
    
}


