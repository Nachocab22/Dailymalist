import XCTest
import SwiftUI
import UIKit
@testable import Dailymalist

@MainActor
final class InlineTagLayoutTests: XCTestCase {
    func testTagAndTitleShareLineAndWrapToLeftEdge() throws {
        let view = InlineTaggedTextView(
            text: .constant("Añadir funcionalidad de etiquetas y revisar los detalles de la aplicación"),
            tags: .constant([TaskTag(name: "Dailymalist", color: .blue)]),
            focused: .constant(false), completed: false, multiline: true, onSubmit: {})
            .frame(width: 280)
            .padding(20)
            .background(Color.white)
        let host = UIHostingController(rootView: view)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 240))
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.frame = window.bounds
        host.view.setNeedsLayout()
        host.view.layoutIfNeeded()
        func findText(_ view: UIView) -> UITextView? {
            if let text = view as? UITextView { return text }
            return view.subviews.compactMap { findText($0) }.first
        }
        let textView = try XCTUnwrap(findText(host.view))
        let layout = textView.layoutManager
        layout.ensureLayout(for: textView.textContainer)
        let first = layout.lineFragmentUsedRect(forGlyphAt: 0, effectiveRange: nil)
        let title = layout.boundingRect(forGlyphRange: NSRange(location: 2, length: 1), in: textView.textContainer)
        XCTAssertGreaterThan(title.minX, 40)
        XCTAssertLessThan(title.minY, first.maxY)
        var lines: [CGRect] = []
        layout.enumerateLineFragments(forGlyphRange: NSRange(location: 0, length: layout.numberOfGlyphs)) { _, used, _, _, _ in lines.append(used) }
        XCTAssertGreaterThan(lines.count, 1)
        XCTAssertEqual(lines[1].minX, 0, accuracy: 1)
        let image = UIGraphicsImageRenderer(bounds: host.view.bounds).image { _ in
            host.view.drawHierarchy(in: host.view.bounds, afterScreenUpdates: true)
        }
        let attachment = XCTAttachment(image: image)
        attachment.name = "Inline tags wrapping"
        attachment.lifetime = .keepAlways
        add(attachment)
        window.isHidden = true
    }
}
