//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class MessageComposerInputAccessoryViewController<ExtraData: ExtraDataTypes>: UIInputViewController,
    UIConfigProvider,
    Customizable,
    AppearanceSetting,
    UITextViewDelegate,
    UIImagePickerControllerDelegate,
    UIDocumentPickerDelegate,
    UINavigationControllerDelegate {
    // MARK: - Underlying types
    
    public enum State {
        case initial
        case slashCommand
        case suggestions
        case reply(_ChatMessage<ExtraData>)
        case edit(_ChatMessage<ExtraData>)
    }
    
    // MARK: - Properties

    var controller: _ChatChannelController<ExtraData>!
    
    public var state: State = .initial {
        didSet {
            updateContent()
        }
    }
    
    var isEmpty: Bool = true {
        didSet {
            composerView.attachmentButton.isHidden = !isEmpty
            composerView.commandsButton.isHidden = !isEmpty
            composerView.shrinkInputButton.isHidden = isEmpty
            composerView.sendButton.isEnabled = !isEmpty
        }
    }
    
    // MARK: - Subviews
        
    public private(set) lazy var composerView: ChatChannelMessageComposerView<ExtraData> = uiConfig
        .messageComposer
        .messageComposerView.init()
        .withoutAutoresizingMaskConstraints
    
    /// Convenience getter for underlying `textView`.
    public var textView: ChatChannelMessageInputTextView<ExtraData> {
        composerView.messageInputView.textView
    }
    
    public private(set) lazy var suggestionsViewController: MessageComposerSuggestionsViewController<ExtraData> = {
        uiConfig.messageComposer.suggestionsViewController.init()
    }()
    
    public private(set) lazy var imagePicker: UIImagePickerController = {
        let picker = UIImagePickerController()
        picker.mediaTypes = ["public.image", "public.movie"]
        picker.sourceType = .photoLibrary
        picker.delegate = self
        return picker
    }()

    private var suggestionsWindow: NoKeyWindow?
    
    // MARK: Setup
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        setUp()
        (self as! Self).applyDefaultAppearance()
        setUpAppearance()
        setUpLayout()
        updateContent()
    }
    
    open func setUp() {
        setupInputView()
        observeSizeChanges()
    }
    
    open func defaultAppearance() {}
    
    open func setUpAppearance() {}
    
    open func updateContent() {
        switch state {
        case .initial:
            textView.text = ""
            textView.placeholderLabel.text = L10n.Composer.Placeholder.message
            composerView.replyView.message = nil
            composerView.sendButton.mode = .new
            composerView.attachmentsView.isHidden = true
            composerView.replyView.isHidden = true
            composerView.container.topStackView.isHidden = true
            composerView.messageInputView.setSlashCommandViews(hidden: true)
        case .slashCommand:
            textView.text = ""
            textView.placeholderLabel.text = L10n.Composer.Placeholder.giphy
            composerView.messageInputView.setSlashCommandViews(hidden: false)
            dismissSuggestionsViewController()
        case .suggestions:
            showSuggestionsViewController()
        case let .reply(messageToReply):
            composerView.titleLabel.text = L10n.Composer.Title.reply
            let image = UIImage(named: "replyArrow", in: .streamChatUI)?
                .tinted(with: uiConfig.colorPalette.messageComposerStateIcon)
            composerView.stateIcon.image = image
            composerView.container.topStackView.isHidden = false
            composerView.replyView.isHidden = false
            composerView.replyView.message = messageToReply
        case .edit:
            composerView.sendButton.mode = .edit
            composerView.titleLabel.text = L10n.Composer.Title.edit
            let image = UIImage(named: "editPencil", in: .streamChatUI)?
                .tinted(with: uiConfig.colorPalette.messageComposerStateIcon)
            composerView.stateIcon.image = image
            composerView.container.topStackView.isHidden = false
            // update ui with message to edit
        }
    }

    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        dismissSuggestionsViewController()
    }
    
    func setupInputView() {
        inputView = composerView
        
        composerView.messageInputView.textView.delegate = self
        
        composerView.attachmentButton.addTarget(self, action: #selector(showImagePicker), for: .touchUpInside)
        composerView.sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        composerView.shrinkInputButton.addTarget(self, action: #selector(shrinkInput), for: .touchUpInside)
        composerView.messageInputView.rightAccessoryButton.addTarget(
            self,
            action: #selector(dismissSlashCommand),
            for: .touchUpInside
        )
        composerView.dismissButton.addTarget(self, action: #selector(resetState), for: .touchUpInside)
        
        composerView.attachmentsView.didTapRemoveItemButton = { [weak self] index in self?.imageAttachments.remove(at: index) }
    }
    
    open func setUpLayout() {}
    
    public func observeSizeChanges() {
        composerView.addObserver(self, forKeyPath: "safeAreaInsets", options: .new, context: nil)
        textView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
    }
    
    // There are some issues with new-style KVO so that is something that will need attention later.
    // swiftlint:disable block_based_kvo
    override open func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        if object as AnyObject? === textView, keyPath == "contentSize" {
            composerView.invalidateIntrinsicContentSize()
        } else if object as AnyObject? === composerView, keyPath == "safeAreaInsets" {
            composerView.invalidateIntrinsicContentSize()
        }
    }
    
    // MARK: Button actions
    
    @objc func sendMessage() {
        guard
            let controller = controller,
            let cid = controller.cid,
            let text = composerView.messageInputView.textView.text,
            !text.replacingOccurrences(of: " ", with: "").isEmpty
        else { return }
        
        switch state {
        case .initial:
            // TODO: Attachments
            controller.createNewMessage(text: text)
        case let .reply(messageToReply):
            let messageController = controller.client.messageController(
                cid: cid,
                messageId: messageToReply.id
            )
            // TODO:
            // 1. Attachments
            // 2. Should be inline reply after backend implementation.
            messageController.createNewReply(text: textView.text, showReplyInChannel: true)
        case let .edit(messageToEdit):
            let messageController = controller.client.messageController(
                cid: cid,
                messageId: messageToEdit.id
            )
            // TODO: Adjust LLC to edit attachments also
            messageController.editMessage(text: textView.text)
        case .suggestions:
            // TODO: `createNewMessage` with `commands` value should be called.
            print("Send suggestions message")
        default: return
        }
        
        state = .initial
    }
    
    @objc func showImagePicker() {
        present(imagePicker, animated: true, completion: nil)
    }
    
    @objc func dismissSlashCommand() {
        composerView.messageInputView.setSlashCommandViews(hidden: true)
    }
    
    @objc func shrinkInput() {
        composerView.attachmentButton.isHidden = false
        composerView.commandsButton.isHidden = false
        composerView.shrinkInputButton.isHidden = true
    }
    
    @objc func resetState() {
        state = .initial
    }
    
    // MARK: Suggestions

    var done = false
    func showSuggestionsViewController() {
        guard !done else { return }

        if #available(iOS 13.0, *) {
            let windowScene = UIApplication.shared
                .connectedScenes
                .first(where: { $0.activationState == .foregroundActive })

            if let windowScene = windowScene as? UIWindowScene {
                suggestionsWindow = NoKeyWindow(windowScene: windowScene)
            }
        } else {
            suggestionsWindow = NoKeyWindow(frame: .zero)
        }

        suggestionsWindow?.translatesAutoresizingMaskIntoConstraints = false
        suggestionsWindow?.frame = .init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 190)
        suggestionsWindow?.setNeedsLayout()
        suggestionsWindow?.backgroundColor = .clear
        suggestionsWindow?.rootViewController = suggestionsViewController // UIViewController()
        suggestionsWindow?.rootViewController?.view.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width)
            .isActive = true
        suggestionsWindow?.rootViewController?.view.heightAnchor.constraint(equalToConstant: 190).isActive = true

        suggestionsWindow?.windowLevel = .alert + 1
        suggestionsWindow?.makeKeyAndVisible()

        done.toggle()
//        guard let parent = parent else { return }
//        parent.addChild(suggestionsViewController)
//        parent.view.addSubview(suggestionsViewController.view)
//        suggestionsViewController.didMove(toParent: parent)

//        guard let suggestionView = suggestionsViewController.view else { return }
//        suggestionView.bottomAnchor.constraint(equalTo: composerView.topAnchor).isActive = true
//        suggestionView.centerXAnchor.constraint(equalTo: composerView.centerXAnchor).isActive = true
//        suggestionView.leadingAnchor.constraint(equalTo: composerView.layoutMarginsGuide.leadingAnchor).isActive = true
//        suggestionView.trailingAnchor.constraint(equalTo: composerView.layoutMarginsGuide.trailingAnchor).isActive = true
    }

    func dismissSuggestionsViewController() {
        suggestionsViewController.removeFromParent()
        suggestionsViewController.view.removeFromSuperview()
    }
    
    // MARK: Attachments
    
    var imageAttachments: [UIImage] = [] {
        didSet {
            didUpdateImageAttachments()
        }
    }
    
    func didUpdateImageAttachments() {
        composerView.attachmentsView.previews = imageAttachments
        composerView.attachmentsView.isHidden = imageAttachments.isEmpty
        composerView.invalidateIntrinsicContentSize()
    }
    
    // MARK: UITextView
    
    func promptSuggestionIfNeeded() {
        if textView.text == "/" {
            showSuggestionsViewController()
        }
    }
    
    func replaceTextWithSlashCommandViewIfNeeded() {
        if textView.text == "/giphy" {
            state = .slashCommand
        }
    }

    // MARK: - UITextViewDelegate
    
    public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        composerView.messageInputView.textView.inputAccessoryView = view
        return true
    }

    public func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        composerView.messageInputView.textView.inputAccessoryView = nil
        return true
    }
    
    public func textViewDidChange(_ textView: UITextView) {
        isEmpty = textView.text.replacingOccurrences(of: " ", with: "").isEmpty
        replaceTextWithSlashCommandViewIfNeeded()
        promptSuggestionIfNeeded()
    }

    // MARK: - UIImagePickerControllerDelegate
    
    public func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        guard let selectedImage = info[.originalImage] as? UIImage else { return }
        
        imageAttachments.append(selectedImage)
        picker.dismiss(animated: true, completion: nil)
    }
}

class NoKeyWindow: UIWindow {
    override func makeKey() {}
}
