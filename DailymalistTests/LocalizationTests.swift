import Foundation
import Testing
@testable import Dailymalist

struct LocalizationTests {
    @MainActor
    @Test func iconCatalogFollowsViewLocaleWithoutRestart() throws {
        let icon = try #require(HabitIconCatalog.icon(named: "figure.walk"))
        let spanish = Locale(identifier: "es")
        let english = Locale(identifier: "en")
        #expect(icon.localizedDisplayName(locale: spanish) == "Caminar")
        #expect(icon.localizedDisplayName(locale: english) == "Walk")
        #expect(icon.localizedDisplayName(locale: spanish) == "Caminar")
        #expect(HabitIconCategory.physicalActivity.displayName(locale: english) == "Physical activity")
        #expect(HabitIconCategory.physicalActivity.displayName(locale: spanish) == "Actividad física")
        #expect(icon.matches("Walk", locale: english))
        #expect(String(localized: LocalizedStringResource("weekday.wednesday", defaultValue: "X", locale: english)) == "W")
        #expect(String(localized: LocalizedStringResource("weekday.wednesday", defaultValue: "X", locale: spanish)) == "X")
    }

    @Test(arguments: ["es", "en"])
    func catalogAndPlurals(language: String) throws {
        let path = try #require(Bundle.main.path(forResource: language, ofType: "lproj"))
        let bundle = try #require(Bundle(path: path))
        let locale = Locale(identifier: language)
        #expect(bundle.localizedString(forKey: "Tareas", value: nil, table: nil) == (language == "es" ? "Tareas" : "Tasks"))
        for count in [0, 1, 2, 10] {
            let pending = String(localized: "\(count) pendientes", bundle: bundle, locale: locale)
            let completed = String(localized: "\(count) completadas", bundle: bundle, locale: locale)
            #expect(pending == (language == "en" ? "\(count) pending" : "\(count) \(count == 1 ? "pendiente" : "pendientes")"))
            #expect(completed == (language == "en" ? "\(count) completed" : "\(count) \(count == 1 ? "completada" : "completadas")"))
        }
        let permission = bundle.localizedString(forKey: "NSCalendarsFullAccessUsageDescription", value: nil, table: "InfoPlist")
        #expect(permission == (language == "es" ? "Mostrar los eventos de los calendarios que selecciones en tu agenda." : "Display events from the calendars you select in your agenda."))
        #expect(bundle.localizedString(forKey: "weekday.wednesday", value: nil, table: nil) == (language == "es" ? "X" : "W"))
    }
}
