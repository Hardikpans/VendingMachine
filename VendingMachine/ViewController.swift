//
//  ViewController.swift
//  VendingMachine
//
//  Created by Pasan Premaratne on 12/1/16.
//  Copyright © 2018 Hardik. All rights reserved.
//

import UIKit

fileprivate let reuseIdentifier = "vendingItem"
fileprivate let screenWidth = UIScreen.main.bounds.width

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var quantityLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    
    let vendingMachine: VendingMachineType
    var currentSelection: VendingSelection?
    var quantity: Double = 1.0
    
    required init?(coder aDecoder: NSCoder) {
        do {
            let dictionary = try PlistConverter.dictionaryFromFile(resource: "VendingInventory", ofType: "plist")
            let inventory = try InventoryUnarchiver.VendingInventoryFromDictionary(dictionary: dictionary)
            self.vendingMachine = VendingMachine(inventory: inventory)
        }
        catch let error {
            fatalError("\(error)")
        }
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setupCollectionViewCells()
        balanceLabel.text = "$\(vendingMachine.amountDeposited)"
        totalLabel.text = "$00.00"
        
        setupViews()
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func setupViews() {
        updateQuantityLabel()
        updateBalanceLabel()
        updateTotalPriceLabel()
    }
    
    // MARK: - Setup

    func setupCollectionViewCells() {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        
        let padding: CGFloat = 10
        let itemWidth = screenWidth/3 - padding
        let itemHeight = screenWidth/3 - padding
        
        layout.itemSize = CGSize(width: itemWidth, height: itemHeight)
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        
        collectionView.collectionViewLayout = layout
    }
    
    // MARK: UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 12
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? VendingItemCell else { fatalError() }
        
        let item = vendingMachine.selection[indexPath.row]
        cell.iconView.image = item.icon()
        
        return cell
    }
    
    // MARK: - UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        updateCell(having: indexPath, selected: true)
        reset()
        currentSelection = vendingMachine.selection[indexPath.row]
        updateTotalPriceLabel()
           }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        updateCell(having: indexPath, selected: false)
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        updateCell(having: indexPath, selected: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        updateCell(having: indexPath, selected: false)
    }
    
    func updateCell(having indexPath: IndexPath, selected: Bool) {
        
        let selectedBackgroundColor = UIColor(red: 41/255.0, green: 211/255.0, blue: 241/255.0, alpha: 1.0)
        let defaultBackgroundColor = UIColor(red: 27/255.0, green: 32/255.0, blue: 36/255.0, alpha: 1.0)
        
        if let cell = collectionView.cellForItem(at: indexPath) {
            cell.contentView.backgroundColor = selected ? selectedBackgroundColor : defaultBackgroundColor
        }
    }
    
    // MARK: - Helper Methods
    
    @IBAction func Purchase() {
        if let currentSelection = currentSelection {
            do {
                try vendingMachine.vend(selection: currentSelection, quantity: quantity)
            updateBalanceLabel()
            updateTotalPriceLabel()
            } catch VendingMachineError.OutOfStock {
                showAlert(title: "Out of Stock")
            } catch VendingMachineError.InvalidSelection {
                showAlert(title: "Invalid Selection!")
            } catch VendingMachineError.InsufficientFunds(let amount) {
                showAlert(title: "Insufficient funds", message: "Additional $\(amount) needed to complete the transaction")
            } catch let error {
                fatalError("\(error)")
            }
        } else {
            // FIXME: Alert user to no selection
        }
    }
    
    @IBAction func updateQuantity(_ sender: UIStepper) {
        quantity = sender.value
        updateQuantityLabel()
        updateTotalPriceLabel()
        
    }
    
    
    func updateTotalPriceLabel() {
        if let currentSelection = currentSelection, let item = vendingMachine.itemForCurrentSelection(selection: currentSelection){
            totalLabel.text = "$\(item.price)"
            
        }

    }
    
    func updateQuantityLabel() {
        quantityLabel.text = "\(quantity)"
    }
    
    func updateBalanceLabel() {
        balanceLabel.text = "$\(vendingMachine.amountDeposited)"
    }
    
    func reset() {
        quantity = 1
        updateTotalPriceLabel()
        updateQuantityLabel()
    }
    
    func showAlert(title: String, message: String? = nil, style: UIAlertControllerStyle = .alert) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: style)
        
        let okAction = UIAlertAction(title: "OK", style: .default, handler: dismissAlert)
        
        alertController.addAction(okAction)
        
        present(alertController, animated: true, completion: nil)
    }
    func dismissAlert(sender: UIAlertAction){
        reset()
    }
    @IBAction func DepositFunds() {
        vendingMachine.deposit(amount: 5.00)
        updateBalanceLabel()
    }
    
}

