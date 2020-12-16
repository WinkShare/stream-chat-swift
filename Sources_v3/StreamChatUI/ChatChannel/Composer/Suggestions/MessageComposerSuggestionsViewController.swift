//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public protocol SuggestionsViewControllerPresenter: class {
    func presentSuggestions(with configuration: SuggestionsConfiguration)
    func dismissSuggestionsViewController()
}

public enum SuggestionsConfiguration {
    case mention
    case command
}

open class MessageComposerSuggestionsViewController<ExtraData: ExtraDataTypes>: ViewController,
    UIConfigProvider,
    UICollectionViewDelegate,
    UICollectionViewDataSource {
    // MARK: - Property

    public var configuration: SuggestionsConfiguration! {
        didSet {
            updateContent()
        }
    }

    private var collectionViewHeightObserver: NSKeyValueObservation?
    private var frameObserver: NSKeyValueObservation?

    public var bottomAnchorView: UIView?

    // MARK: - Subviews

    open private(set) lazy var collectionView = uiConfig
        .messageComposer
        .suggestionsCollectionView
        .init(layout: uiConfig.messageComposer.suggestionsCollectionViewLayout.init())
        .withoutAutoresizingMaskConstraints

    // MARK: - Overrides

    override open func setUp() {
        super.setUp()
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            uiConfig.messageComposer.suggestionsCommandCollectionViewCell,
            forCellWithReuseIdentifier: uiConfig.messageComposer.suggestionsCommandCollectionViewCell.reuseId
        )
        collectionView.register(
            uiConfig.messageComposer.suggestionsMentionCollectionViewCell,
            forCellWithReuseIdentifier: uiConfig.messageComposer.suggestionsMentionCollectionViewCell.reuseId
        )
    }

    override public func setUpAppearance() {
        view.backgroundColor = .clear
        view.layer.addShadow(color: uiConfig.colorPalette.shadow)
    }

    override public func setUpLayout() {
        view.addSubview(collectionView)
        collectionView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        collectionView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor).isActive = true

        collectionViewHeightObserver = collectionView.observe(
            \.contentSize,
            options: [.new],
            changeHandler: { [weak self] _, change in
                DispatchQueue.main.async {
                    guard let self = self, let newSize = change.newValue else { return }
                    self.view.frame.size.height = newSize.height
                    self.updateViewFrame()
                }
            }
        )
        updateContent()
    }

    override open func updateContent() {
        collectionView.reloadData()
    }

    private func updateViewFrame() {
        frameObserver = bottomAnchorView?.observe(
            \.bounds,
            options: [.new, .initial],
            changeHandler: { [weak self] bottomAnchoredView, change in
                DispatchQueue.main.async {
                    guard let self = self, let changedFrame = change.newValue else { return }

                    let newFrame = bottomAnchoredView.convert(changedFrame, to: nil)
                    self.view.frame.origin.y = newFrame.minY - self.view.frame.height
                }
            }
        )
    }

    // MARK: - UICollectionView

    private func createMentionCell(for indexPath: IndexPath) -> MessageComposerMentionCollectionViewCell<ExtraData> {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MessageComposerMentionCollectionViewCell<ExtraData>.reuseId,
            for: indexPath
        ) as! MessageComposerMentionCollectionViewCell<ExtraData>

        cell.uiConfig = uiConfig
        cell.mentionView.content = ("Damian", "@damian", UIImage(named: "pattern1", in: .streamChatUI), false)
        return cell
    }

    private func createCommandCell(for indexPath: IndexPath) -> MessageComposerCommandCollectionViewCell<ExtraData> {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MessageComposerCommandCollectionViewCell<ExtraData>.reuseId,
            for: indexPath
        ) as! MessageComposerCommandCollectionViewCell<ExtraData>

        cell.uiConfig = uiConfig
        cell.commandView.content = ("Giphy", "/giphy [query]", UIImage(named: "command_giphy", in: .streamChatUI))
        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        3 // uiConfig.commandIcons.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch configuration {
        case .command:
            return createCommandCell(for: indexPath)
        case .mention:
            return createMentionCell(for: indexPath)
        default:
            return createMentionCell(for: indexPath)
        }
    }
}
