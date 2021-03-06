//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

extension ChatFileAttachmentListView {
    open class ItemView: ChatMessageAttachmentInfoView<ExtraData> {
        // MARK: - Subviews

        public private(set) lazy var fileIconImageView = UIImageView()
            .withoutAutoresizingMaskConstraints

        // MARK: - Overrides

        override public func defaultAppearance() {
            backgroundColor = .white
            layer.cornerRadius = 12
            layer.masksToBounds = true
            layer.borderWidth = 1
            layer.borderColor = uiConfig.colorPalette.incomingMessageBubbleBorder.cgColor
        }

        override open func setUpLayout() {
            addSubview(fileIconImageView)
            addSubview(actionIconImageView)
            addSubview(fileNameAndSizeStack)

            NSLayoutConstraint.activate([
                fileIconImageView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
                fileIconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
                fileIconImageView.topAnchor.constraint(greaterThanOrEqualTo: layoutMarginsGuide.topAnchor),
                fileIconImageView.bottomAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.bottomAnchor),
                
                actionIconImageView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
                actionIconImageView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
                actionIconImageView.leadingAnchor.constraint(
                    equalToSystemSpacingAfter: fileNameAndSizeStack.trailingAnchor,
                    multiplier: 1
                ),
                
                fileNameAndSizeStack.leadingAnchor.constraint(
                    equalToSystemSpacingAfter: fileIconImageView.trailingAnchor,
                    multiplier: 2
                ),
                fileNameAndSizeStack.centerYAnchor.constraint(equalTo: centerYAnchor),
                fileNameAndSizeStack.topAnchor.constraint(greaterThanOrEqualTo: layoutMarginsGuide.topAnchor),
                fileNameAndSizeStack.bottomAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.bottomAnchor)
            ])
        }

        override open func updateContent() {
            super.updateContent()

            fileIconImageView.image = fileIcon
        }

        // MARK: - Private

        private var fileIcon: UIImage? {
            guard let file = content?.attachment.file else { return nil }

            let config = uiConfig
                .messageList
                .messageContentSubviews
                .attachmentSubviews

            return config.fileIcons[file.type] ?? config.fileFallbackIcon
        }
    }
}
