//
//  RecordButton.swift
//  Sandbox
//
//  Created by Wataru Nagasawa on 2019/07/21.
//  Copyright © 2019 junkapp. All rights reserved.
//

import UIKit

@IBDesignable
final class RecordButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }

    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        configure()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = frame.size.width / 2.0
    }

    private func configure() {
        isExclusiveTouch = true
        backgroundColor = .white
        titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        setTitleColor(.darkText, for: .normal)
    }

    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.width = 96
        size.height = 96
        return size
    }
}
