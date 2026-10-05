import SwiftUI
#if canImport(UIKit)
import UIKit

// Attachments participate in the same text layout as the title, so wrapped lines
// start at the left edge instead of remaining indented after a separate chip view.
struct InlineTaggedTextView: UIViewRepresentable {
    @Binding var text: String
    @Binding var tags: [TaskTag]
    @Binding var focused: Bool
    var completed: Bool
    var multiline: Bool
    var onSubmit: () -> Void
    var availableTags: [TaskTag] = []
    var focusRequest = 0

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.backgroundColor = .clear
        view.font = .systemFont(ofSize: 18)
        view.isScrollEnabled = false
        view.textContainerInset = .zero
        view.textContainer.lineFragmentPadding = 0
        view.delegate = context.coordinator
        view.accessibilityLabel = String(localized: "Título de la tarea. Borra una etiqueta para quitarla de esta tarea.")
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return view
    }

    func updateUIView(_ view: UITextView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.updating = true
        defer { context.coordinator.updating = false }
        let signature = tags.map { "\($0.id)|\($0.name)|\($0.red)|\($0.green)|\($0.blue)" }.joined()
        let current = Coordinator.contents(view.attributedText)
        if current.text != text || current.ids != tags.map(\.id)
            || context.coordinator.signature != signature || context.coordinator.completed != completed
            || context.coordinator.pendingCaret != nil {
            let selection = view.selectedRange
            let result = NSMutableAttributedString(string: "")
            for tag in tags {
                let attachment = TagAttachment()
                attachment.tagID = tag.id
                attachment.image = chip(tag, traits: view.traitCollection)
                let size = attachment.image!.size
                attachment.bounds = CGRect(x: 0, y: -5, width: size.width, height: size.height)
                result.append(NSAttributedString(attachment: attachment))
                result.append(NSAttributedString(string: " ", attributes: [.tagSpacing: true]))
            }
            result.append(NSAttributedString(string: text, attributes: titleAttributes))
            view.attributedText = result
            let caret = context.coordinator.pendingCaret.map { tags.count * 2 + $0 } ?? selection.location
            view.selectedRange = NSRange(location: min(caret, result.length), length: 0)
            context.coordinator.pendingCaret = nil
            context.coordinator.signature = signature
            context.coordinator.completed = completed
        }
        view.typingAttributes = titleAttributes
        context.coordinator.refreshSuggestions(view)
        if context.coordinator.lastFocusRequest != focusRequest {
            context.coordinator.lastFocusRequest = focusRequest
            DispatchQueue.main.async { [weak view] in
                guard let view, view.window != nil, !view.isFirstResponder else { return }
                view.becomeFirstResponder()
            }
        }
    }

    private var titleAttributes: [NSAttributedString.Key: Any] {
        [.font: UIFont.systemFont(ofSize: 18),
         .foregroundColor: completed ? UIColor.secondaryLabel : UIColor.label,
         .strikethroughStyle: completed ? NSUnderlineStyle.single.rawValue : 0]
    }

    private func chip(_ tag: TaskTag, traits: UITraitCollection) -> UIImage {
        let font = UIFont.systemFont(ofSize: 13, weight: .medium)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font, .foregroundColor: UIColor.label.resolvedColor(with: traits)
        ]
        let label = tag.name as NSString
        let labelSize = label.size(withAttributes: attributes)
        let size = CGSize(width: ceil(labelSize.width) + 16, height: 25)
        return UIGraphicsImageRenderer(size: size).image { _ in
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: 0.5, dy: 0.5)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: 12)
            UIColor(tag.color).withAlphaComponent(0.24).setFill()
            path.fill()
            UIColor(tag.color).withAlphaComponent(0.6).setStroke()
            path.lineWidth = 1
            path.stroke()
            label.draw(at: CGPoint(x: 8, y: (size.height - labelSize.height) / 2), withAttributes: attributes)
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        guard let width = proposal.width, width > 0 else { return nil }
        let size = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: width, height: max(25, ceil(size.height)))
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: InlineTaggedTextView
        var signature = ""
        var completed = false
        var lastFocusRequest = 0
        var updating = false
        var pendingCaret: Int?
        private var suggestionIDs: [UUID] = []
        init(_ parent: InlineTaggedTextView) { self.parent = parent }

        static func contents(_ value: NSAttributedString) -> (text: String, ids: [UUID]) {
            var ids: [UUID] = []
            let plain = NSMutableAttributedString(attributedString: value)
            var removals: [NSRange] = []
            value.enumerateAttributes(in: NSRange(location: 0, length: value.length)) { attributes, range, _ in
                if let attachment = attributes[.attachment] as? TagAttachment {
                    ids.append(attachment.tagID)
                    removals.append(range)
                } else if attributes[.tagSpacing] != nil {
                    removals.append(range)
                }
            }
            for range in removals.reversed() { plain.deleteCharacters(in: range) }
            return (plain.string, ids)
        }

        func textViewDidChange(_ textView: UITextView) {
            let value = Self.contents(textView.attributedText)
            parent.text = value.text
            parent.tags.removeAll { !value.ids.contains($0.id) }
            refreshSuggestions(textView)
        }
        func textViewDidBeginEditing(_ textView: UITextView) {
            parent.focused = true
            refreshSuggestions(textView)
        }
        func textViewDidChangeSelection(_ textView: UITextView) {
            if !updating { refreshSuggestions(textView) }
        }

        func refreshSuggestions(_ view: UITextView) {
            let active = TagCompletion.active(in: view.text, selection: view.selectedRange)
            let matches = active.map { token in
                parent.availableTags.filter { TagCompletion.matches($0.name, query: token.query) }
                    .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            } ?? []
            let ids = matches.map(\.id)
            guard ids != suggestionIDs else { return }
            suggestionIDs = ids
            if matches.isEmpty {
                view.inputAccessoryView = nil
            } else {
                let accessory = UIInputView(frame: CGRect(x: 0, y: 0, width: view.window?.bounds.width ?? 320, height: 48), inputViewStyle: .default)
                // A solid surface, independent of the keyboard's translucent material.
                accessory.backgroundColor = .white
                accessory.isOpaque = true
                accessory.autoresizingMask = [.flexibleWidth]
                accessory.overrideUserInterfaceStyle = .light
                let scroll = UIScrollView()
                scroll.showsHorizontalScrollIndicator = false
                scroll.translatesAutoresizingMaskIntoConstraints = false
                accessory.addSubview(scroll)
                let stack = UIStackView()
                stack.axis = .horizontal
                stack.spacing = 8
                stack.translatesAutoresizingMaskIntoConstraints = false
                scroll.addSubview(stack)
                NSLayoutConstraint.activate([
                    scroll.leadingAnchor.constraint(equalTo: accessory.leadingAnchor, constant: 8),
                    scroll.trailingAnchor.constraint(equalTo: accessory.trailingAnchor, constant: -8),
                    scroll.topAnchor.constraint(equalTo: accessory.topAnchor, constant: 6),
                    scroll.bottomAnchor.constraint(equalTo: accessory.bottomAnchor, constant: -6),
                    stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
                    stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
                    stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
                    stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
                    stack.heightAnchor.constraint(equalTo: scroll.frameLayoutGuide.heightAnchor)
                ])
                for tag in matches {
                    var config = UIButton.Configuration.tinted()
                    config.title = tag.name
                    config.baseBackgroundColor = UIColor(tag.color)
                    config.baseForegroundColor = .label
                    config.cornerStyle = .capsule
                    let button = UIButton(configuration: config, primaryAction: UIAction { [weak self, weak view] _ in
                        guard let self, let view else { return }
                        self.choose(tag, in: view)
                    })
                    button.accessibilityLabel = String(localized: "Insertar etiqueta \(tag.name)")
                    stack.addArrangedSubview(button)
                }
                view.inputAccessoryView = accessory
            }
            if view.isFirstResponder { view.reloadInputViews() }
        }

        private func choose(_ tag: TaskTag, in view: UITextView) {
            guard let token = TagCompletion.active(in: view.text, selection: view.selectedRange) else { return }
            let prefix = view.attributedText.attributedSubstring(from: NSRange(location: 0, length: token.range.location))
            pendingCaret = Self.contents(prefix).text.utf16.count
            let updated = NSMutableAttributedString(attributedString: view.attributedText)
            updated.deleteCharacters(in: token.range)
            updating = true
            view.attributedText = updated
            view.selectedRange = NSRange(location: token.range.location, length: 0)
            updating = false
            parent.text = Self.contents(updated).text
            if !parent.tags.contains(where: { $0.id == tag.id }) { parent.tags.append(tag) }
            refreshSuggestions(view)
        }
        func textViewDidEndEditing(_ textView: UITextView) { parent.focused = false }
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            if text == "\n" && !parent.multiline { parent.onSubmit(); return false }
            return true
        }
    }
}

private final class TagAttachment: NSTextAttachment {
    var tagID = UUID()
}
private extension NSAttributedString.Key {
    static let tagSpacing = NSAttributedString.Key("DailymalistTagSpacing")
}
#else
struct InlineTaggedTextView: View {
    @Binding var text: String
    @Binding var tags: [TaskTag]
    @Binding var focused: Bool
    var completed: Bool
    var multiline: Bool
    var onSubmit: () -> Void
    var availableTags: [TaskTag] = []
    var focusRequest = 0
    @FocusState private var editing: Bool
    var body: some View {
        TextField("", text: $text, axis: .vertical)
            .focused($editing)
            .onChange(of: editing) { _, value in focused = value }
            .onSubmit(onSubmit)
    }
}
#endif
