import XCTest

final class LocalizationUITests: XCTestCase {
    @MainActor
    func testEnglishInterface() {
        verifyInterface(language: "en", tasks: "Tasks", tags: "#Tags", newTag: "New tag", done: "Done", habits: "Habits", active: "Active")
    }

    @MainActor
    func testSpanishInterface() {
        verifyInterface(language: "es", tasks: "Tareas", tags: "#Etiquetas", newTag: "Nueva etiqueta", done: "Hecho", habits: "Hábitos", active: "Activos")
    }

    @MainActor
    private func verifyInterface(language: String, tasks: String, tags: String, newTag: String, done: String, habits: String, active: String) {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(\(language))", "-AppleLocale", language == "en" ? "en_GB" : "es_ES"]
        app.launch()
        XCTAssertTrue(app.staticTexts[tasks].waitForExistence(timeout: 10))
        app.buttons[tags].tap()
        XCTAssertTrue(app.textFields[newTag].waitForExistence(timeout: 5))
        app.buttons[done].tap()
        app.buttons[habits].tap()
        XCTAssertTrue(app.staticTexts[active].waitForExistence(timeout: 5))
        app.terminate()
    }
}
