//
//  EnterPhraseViewController.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2017-02-23.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit

enum PhraseEntryReason {
    case setSeed(EnterPhraseCallback)
    case validateForResettingPin(EnterPhraseCallback)
    case validateForWipingWallet(()->Void)
    case validateForOneTimeWipingWallet(EnterPhraseCallback)
    case importUtxoFromServer(EnterPhraseCallback)
}

typealias EnterPhraseCallback = (String) -> Void

class EnterPhraseViewController : UIViewController, UIScrollViewDelegate, CustomTitleView {

    init(walletManager: WalletManager, reason: PhraseEntryReason) {
        self.walletManager = walletManager
        self.enterPhrase = EnterPhraseCollectionViewController(walletManager: walletManager)
        self.faq = UIButton.buildFaqButton(articleId: ArticleIds.recoverWallet)
        self.reason = reason

        switch reason {
        case .setSeed(_):
            self.customTitle = S.RecoverWallet.header
        case .validateForResettingPin(_):
            self.customTitle = S.RecoverWallet.headerResetPin
        case .validateForWipingWallet(_):
            self.customTitle = S.WipeWallet.title
        case .validateForOneTimeWipingWallet(_):
            self.customTitle = S.OneTimeWipe.title
        case .importUtxoFromServer(_):
            self.customTitle = S.ImportUtxos.header
        }

        super.init(nibName: nil, bundle: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    //MARK: - Private
    private let walletManager: WalletManager
    private let reason: PhraseEntryReason
    private let enterPhrase: EnterPhraseCollectionViewController
    private let errorLabel = UILabel.wrapping(font: .customBody(size: 16.0), color: .cameraGuideNegative)
    private let instruction = UILabel(font: .customBold(size: 18.0), color: .orange)
    internal let titleLabel = UILabel.wrapping(font: .customBold(size: 26.0), color: .orange)
    private let subheader = UILabel.wrapping(font: .customBody(size: 16.0), color: .darkText)
    private let faq: UIButton
    private let scrollView = UIScrollView()
    private let container = UIView()
    private let moreInfoButton = UIButton(type: .system)
    let customTitle: String

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        addSubviews()
        addConstraints()
        setData()
    }

    private func addSubviews() {
        view.addSubview(scrollView)
        scrollView.addSubview(container)
        container.addSubview(titleLabel)
        container.addSubview(subheader)
        container.addSubview(errorLabel)
        container.addSubview(instruction)
        container.addSubview(faq)
        container.addSubview(moreInfoButton)

        addChild(enterPhrase)
        container.addSubview(enterPhrase.view)
        enterPhrase.didMove(toParent: self)
    }

    private func addConstraints() {
        scrollView.constrain(toSuperviewEdges: nil)
        scrollView.constrain([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor) ])
        container.constrain(toSuperviewEdges: nil)
        container.constrain([
            container.widthAnchor.constraint(equalTo: view.widthAnchor) ])
        titleLabel.constrain([
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: C.padding[2]),
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: C.padding[1]),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: faq.leadingAnchor) ])
        subheader.constrain([
            subheader.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subheader.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),
            subheader.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -C.padding[2]) ])
        instruction.constrain([
            instruction.topAnchor.constraint(equalTo: subheader.bottomAnchor, constant: C.padding[3]),
            instruction.leadingAnchor.constraint(equalTo: subheader.leadingAnchor) ])
        enterPhrase.view.constrain([
            enterPhrase.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: C.padding[2]),
            enterPhrase.view.topAnchor.constraint(equalTo: instruction.bottomAnchor, constant: C.padding[1]),
            enterPhrase.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -C.padding[2]),
            enterPhrase.view.heightAnchor.constraint(equalToConstant: enterPhrase.height) ])
        errorLabel.constrain([
            errorLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: C.padding[2]),
            errorLabel.topAnchor.constraint(equalTo: enterPhrase.view.bottomAnchor, constant: C.padding[1]),
            errorLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -C.padding[2]),
            errorLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -C.padding[2] )])
        faq.constrain([
            faq.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -C.padding[2]),
            faq.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            faq.widthAnchor.constraint(equalToConstant: 44.0),
            faq.heightAnchor.constraint(equalToConstant: 44.0) ])
        moreInfoButton.constrain([
            moreInfoButton.topAnchor.constraint(equalTo: subheader.bottomAnchor, constant: C.padding[2]),
            moreInfoButton.leadingAnchor.constraint(equalTo: subheader.leadingAnchor) ])
    }

    private func setData() {
        view.backgroundColor = .white
        errorLabel.text = S.RecoverWallet.invalid
        errorLabel.isHidden = true
        errorLabel.textAlignment = .center
        enterPhrase.didFinishPhraseEntry = { [weak self] phrase in
            self?.validatePhrase(phrase)
        }
        instruction.text = S.RecoverWallet.instruction

        switch reason {
        case .setSeed(_):
            titleLabel.text = S.RecoverWallet.header
            subheader.text = S.RecoverWallet.subheader
            moreInfoButton.isHidden = true
        case .validateForResettingPin(_):
            titleLabel.text = S.RecoverWallet.headerResetPin
            subheader.text = S.RecoverWallet.subheaderResetPin
            instruction.isHidden = true
            moreInfoButton.setTitle(S.RecoverWallet.resetPinInfo, for: .normal)
            moreInfoButton.tap = {
                Store.trigger(name: .presentFaq(ArticleIds.resetPinWithPaperKey))
            }
            faq.isHidden = true
        case .validateForWipingWallet(_):
            titleLabel.text = S.WipeWallet.title
            subheader.text = S.WipeWallet.instruction
        case .validateForOneTimeWipingWallet(_):
            titleLabel.text = S.OneTimeWipe.title
            subheader.text = S.OneTimeWipe.instruction
            faq.isHidden = true
        case .importUtxoFromServer(_):
            titleLabel.text = S.ImportUtxos.title
            subheader.text = S.ImportUtxos.instruction
            faq.isHidden = true
        }

        scrollView.delegate = self
        addCustomTitle()
    }

    private func validatePhrase(_ phrase: String) {
        guard walletManager.isPhraseValid(phrase) else {
            errorLabel.isHidden = false
            return
        }
        errorLabel.isHidden = true

        switch reason {
        case .setSeed(let callback):
            guard self.walletManager.setSeedPhrase(phrase) else { errorLabel.isHidden = false; return }
            //Since we know that the user had their phrase at this point,
            //this counts as a write date
            UserDefaults.writePaperPhraseDate = Date()
            Store.perform(action: LoginSuccess())
            return callback(phrase)
        case .validateForResettingPin(let callback):
            guard self.walletManager.authenticate(phrase: phrase) else { errorLabel.isHidden = false; return }
            UserDefaults.writePaperPhraseDate = Date()
            return callback(phrase)
        case .validateForWipingWallet(let callback):
            guard self.walletManager.authenticate(phrase: phrase) else { errorLabel.isHidden = false; return }
            return callback()
        case .validateForOneTimeWipingWallet(let callback):
            guard self.walletManager.authenticate(phrase: phrase) else { errorLabel.isHidden = false; return }
            return callback(phrase)
        case .importUtxoFromServer(let callback):
            self.navigationController?.popViewController(animated: true)
            return callback(phrase)
        }
    }

    @objc private func keyboardWillShow(notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        guard let frameValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        var contentInset = scrollView.contentInset
        if contentInset.bottom == 0.0 {
            contentInset.bottom = frameValue.cgRectValue.height + 44.0
        }
        scrollView.contentInset = contentInset
    }

    @objc private func keyboardWillHide(notification: Notification) {
        var contentInset = scrollView.contentInset
        if contentInset.bottom > 0.0 {
            contentInset.bottom = 0.0
        }
        scrollView.contentInset = contentInset
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        didScrollForCustomTitle(yOffset: scrollView.contentOffset.y)
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        scrollViewWillEndDraggingForCustomTitle(yOffset: targetContentOffset.pointee.y)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
