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

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.backgroundColor = .clear
        view.isScrollEnabled = false
        view.textContainerInset = .zero
        view.textContainer.lineFragmentPadding = 0
        view.delegate = context.coordinator
        view.accessibilityLabel = "Título de la tarea. Borra una etiqueta para quitarla de esta tarea."
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return view
    }

    func updateUIView(_ view: UITextView, context: Context) {
        context.coordinator.parent = self
        let signature = tags.map { "\($0.id)|\($0.name)|\($0.red)|\($0.green)|\($0.blue)" }.joined()
        let current = Coordinator.contents(view.attributedText)
        if current.text != text || current.ids != tags.map(\.id)
            || context.coordinator.signature != signature || context.coordinator.completed != completed {
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
            view.selectedRange = NSRange(location: min(selection.location, result.length), length: 0)
            context.coordinator.signature = signature
            context.coordinator.completed = completed
        }
        view.typingAttributes = titleAttributes
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
        }
        func textViewDidBeginEditing(_ textView: UITextView) { parent.focused = true }
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
    @FocusState private var editing: Bool
    var body: some View {
        TextField("", text: $text, axis: .vertical)
            .focused($editing)
            .onChange(of: editing) { _, value in focused = value }
            .onSubmit(onSubmit)
    }
}
#endif
