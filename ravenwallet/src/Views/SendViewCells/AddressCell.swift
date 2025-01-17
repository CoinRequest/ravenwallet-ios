//
//  AddressCell.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2016-12-16.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit

enum AddressCellType {//BMEX
    case send
    case create
}

class AddressCell : UIView {

    init(currency: CurrencyDef, type:AddressCellType = .send, isAddressBookBtnHidden:Bool = false) {
        self.currency = currency
        self.addressCellType = type
        self.isAddressBookBtnHidden = isAddressBookBtnHidden
        super.init(frame: .zero)
        setupViews()
    }

    var displayAddress: String? {
        return contentLabel.text
    }
    
    var address: String? {
        return contentLabel.text
    }

    var didBeginEditing: (() -> Void)?
    var didReceivePaymentRequest: ((PaymentRequest) -> Void)?

    func setContent(_ content: String?) {
        contentLabel.text = content
        textField.text = content
    }

    var isEditable = false {
        didSet {
            gr.isEnabled = isEditable
        }
    }

    let textField = UITextField()
    let paste = ShadowButton(title: S.Send.pasteLabel, type: .secondary)
    let scan = ShadowButton(title: S.Send.scanLabel, type: .secondary)
    let addressBook = ShadowButton(type: .secondary, image: #imageLiteral(resourceName: "AddressBookWhite"))
    let contentLabel = UILabel(font: .customBody(size: 14.0), color: .darkText)
    let label = UILabel(font: .customBody(size: 16.0))
    fileprivate let gr = UITapGestureRecognizer()
    let tapView = UIView()
    let border = UIView(color: .secondaryShadow)
    var addressCellType: AddressCellType
    fileprivate let currency: CurrencyDef
    var isAddressBookBtnHidden: Bool = false

    private func setupViews() {
        addSubviews()
        addConstraints()
        setInitialData()
    }

    func addSubviews() {
        addSubview(label)
        addSubview(contentLabel)
        addSubview(textField)
        addSubview(tapView)
        addSubview(border)
        addSubview(paste)
        addSubview(addressBook)
        addSubview(scan)
    }

    func addConstraints() {
        label.constrain([
            label.constraint(.centerY, toView: self),
            label.constraint(.leading, toView: self, constant: C.padding[2]) ])
        contentLabel.constrain([
            contentLabel.constraint(.leading, toView: label),
            contentLabel.constraint(toBottom: label, constant: 0.0),
            contentLabel.trailingAnchor.constraint(equalTo: paste.leadingAnchor, constant: -C.padding[1]) ])
        textField.constrain([
            textField.constraint(.leading, toView: label),
            textField.constraint(toBottom: label, constant: 0.0),
            textField.trailingAnchor.constraint(equalTo: paste.leadingAnchor, constant: -C.padding[1]) ])
        tapView.constrain([
            tapView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tapView.topAnchor.constraint(equalTo: topAnchor),
            tapView.bottomAnchor.constraint(equalTo: bottomAnchor),
            tapView.trailingAnchor.constraint(equalTo: paste.leadingAnchor) ])
        scan.constrain([
            scan.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -C.padding[2]),
            scan.centerYAnchor.constraint(equalTo: centerYAnchor) ])
        addressBook.constrain([
            addressBook.centerYAnchor.constraint(equalTo: centerYAnchor),
            addressBook.trailingAnchor.constraint(equalTo: scan.leadingAnchor, constant: -C.padding[1]),
            addressBook.widthAnchor.constraint(equalTo: scan.widthAnchor, multiplier: isAddressBookBtnHidden ? 0 : 1),
            addressBook.heightAnchor.constraint(equalTo: scan.heightAnchor)])
        paste.constrain([
            paste.centerYAnchor.constraint(equalTo: centerYAnchor),
            paste.trailingAnchor.constraint(equalTo: addressBook.leadingAnchor, constant: -C.padding[1]) ])
        border.constrain([
            border.leadingAnchor.constraint(equalTo: leadingAnchor),
            border.bottomAnchor.constraint(equalTo: bottomAnchor),
            border.trailingAnchor.constraint(equalTo: trailingAnchor),
            border.heightAnchor.constraint(equalToConstant: 1.0) ])
    }
    
    func removePastAndScan()
    {
        self.scan.removeFromSuperview()
        self.paste.removeFromSuperview()
        self.addressBook.removeFromSuperview()
        contentLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -C.padding[2])
    }

    private func setInitialData() {
        self.clipsToBounds = true
        addressBook.clipsToBounds = true
        label.text = (addressCellType == .send) ? S.Send.toLabel : S.AddressBook.addressLabel
        textField.font = contentLabel.font
        textField.textColor = contentLabel.textColor
        //textField.isHidden = true
        textField.returnKeyType = .done
        textField.delegate = self
        textField.clearButtonMode = .whileEditing
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.keyboardType = .asciiCapable
        label.textColor = .grayTextTint
        contentLabel.lineBreakMode = .byTruncatingMiddle

        textField.editingChanged = strongify(self) { myself in
            myself.contentLabel.text = myself.textField.text
        }

        //GR to start editing label
        gr.addTarget(self, action: #selector(didTap))
        tapView.addGestureRecognizer(gr)
    }

    @objc private func didTap() {
        textField.becomeFirstResponder()
        contentLabel.isHidden = true
        //textField.isHidden = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AddressCell : UITextFieldDelegate {
    
    public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        // set the tool bar as this text field's input accessory view
        textField.inputAccessoryView = tbKeyboard
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        didBeginEditing?()
        contentLabel.isHidden = true
        gr.isEnabled = false
        tapView.isUserInteractionEnabled = false
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        contentLabel.isHidden = false
        //textField.isHidden = true
        gr.isEnabled = true
        tapView.isUserInteractionEnabled = true
        contentLabel.text = textField.text
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let request = PaymentRequest(string: string, currency: currency) {
            didReceivePaymentRequest?(request)
            return false
        } else {
            return true
        }
    }
}
