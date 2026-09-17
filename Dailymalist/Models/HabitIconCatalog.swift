//
//  HabitIconCatalog.swift
//  Dailymalist
//

import Foundation

enum HabitIconCategory: String, CaseIterable, Identifiable {
    case physicalActivity = "Actividad física"
    case nutrition = "Alimentación"
    case wellbeing = "Bienestar"
    case learning = "Aprendizaje"
    case home = "Hogar"
    case other = "Otros"

    var id: Self { self }
}

struct HabitIcon: Identifiable, Hashable {
    let symbolName: String
    let displayName: String
    let category: HabitIconCategory
    let keywords: [String]

    var id: String { symbolName }

    func matches(_ query: String) -> Bool {
        let normalizedQuery = query.normalizedForHabitIconSearch
        guard !normalizedQuery.isEmpty else { return true }

        let searchableText = ([displayName, symbolName] + keywords)
            .joined(separator: " ")
            .normalizedForHabitIconSearch

        return searchableText.contains(normalizedQuery)
    }
}

enum HabitIconCatalog {
    static let icons: [HabitIcon] = [
        HabitIcon(symbolName: "figure.walk", displayName: "Caminar", category: .physicalActivity, keywords: ["paseo", "pasos", "andar"]),
        HabitIcon(symbolName: "figure.run", displayName: "Correr", category: .physicalActivity, keywords: ["running", "cardio", "carrera"]),
        HabitIcon(symbolName: "figure.strengthtraining.traditional", displayName: "Fuerza", category: .physicalActivity, keywords: ["pesas", "gimnasio", "entrenamiento"]),
        HabitIcon(symbolName: "figure.yoga", displayName: "Yoga", category: .physicalActivity, keywords: ["estirar", "flexibilidad", "postura"]),
        HabitIcon(symbolName: "figure.pool.swim", displayName: "Nadar", category: .physicalActivity, keywords: ["piscina", "natación", "agua"]),
        HabitIcon(symbolName: "bicycle", displayName: "Bicicleta", category: .physicalActivity, keywords: ["ciclismo", "bici", "pedalear"]),
        HabitIcon(symbolName: "dumbbell.fill", displayName: "Entrenamiento", category: .physicalActivity, keywords: ["ejercicio", "pesas", "fitness"]),
        HabitIcon(symbolName: "figure.boxing", displayName: "Boxeo", category: .physicalActivity, keywords: ["cardio", "boxeo", "ejercicio"]),
        HabitIcon(symbolName: "figure.cooldown", displayName: "Estirar", category: .physicalActivity, keywords: ["movilidad", "calentamiento", "recuperación"]),
        HabitIcon(symbolName: "figure.walk.treadmill", displayName: "Caminar en cinta", category: .physicalActivity, keywords: ["pasos", "andar", "cinta"]),
        HabitIcon(symbolName: "figure.run.treadmill", displayName: "Correr en cinta", category: .physicalActivity, keywords: ["cardio", "correr", "cinta"]),

        HabitIcon(symbolName: "fork.knife", displayName: "Comer saludable", category: .nutrition, keywords: ["comida", "dieta", "alimentación"]),
        HabitIcon(symbolName: "drop.fill", displayName: "Beber agua", category: .nutrition, keywords: ["hidratar", "hidratación", "agua"]),
        HabitIcon(symbolName: "carrot.fill", displayName: "Verduras", category: .nutrition, keywords: ["vegetales", "hortalizas", "saludable"]),
        HabitIcon(symbolName: "apple.logo", displayName: "Fruta", category: .nutrition, keywords: ["manzana", "fruta", "saludable"]),
        HabitIcon(symbolName: "cup.and.saucer.fill", displayName: "Bebida", category: .nutrition, keywords: ["café", "té", "infusión"]),
        HabitIcon(symbolName: "takeoutbag.and.cup.and.straw.fill", displayName: "Preparar comida", category: .nutrition, keywords: ["cocinar", "menú", "táper"]),

        HabitIcon(symbolName: "heart.fill", displayName: "Cuidarme", category: .wellbeing, keywords: ["salud", "autocuidado", "corazón"]),
        HabitIcon(symbolName: "brain.head.profile", displayName: "Meditar", category: .wellbeing, keywords: ["mente", "mindfulness", "respirar"]),
        HabitIcon(symbolName: "bed.double.fill", displayName: "Dormir", category: .wellbeing, keywords: ["sueño", "descanso", "cama"]),
        HabitIcon(symbolName: "lungs.fill", displayName: "Respirar", category: .wellbeing, keywords: ["respiración", "calma", "aire"]),
        HabitIcon(symbolName: "sun.max.fill", displayName: "Tomar el sol", category: .wellbeing, keywords: ["exterior", "luz", "vitamina"]),
        HabitIcon(symbolName: "face.smiling.fill", displayName: "Ánimo", category: .wellbeing, keywords: ["sonreír", "felicidad", "humor"]),
        HabitIcon(symbolName: "cross.case.fill", displayName: "Salud", category: .wellbeing, keywords: ["medicina", "tratamiento", "cuidarse"]),

        HabitIcon(symbolName: "book.fill", displayName: "Leer", category: .learning, keywords: ["lectura", "libro", "estudiar"]),
        HabitIcon(symbolName: "graduationcap.fill", displayName: "Estudiar", category: .learning, keywords: ["curso", "aprender", "clase"]),
        HabitIcon(symbolName: "character.book.closed.fill", displayName: "Idioma", category: .learning, keywords: ["lengua", "vocabulario", "aprender"]),
        HabitIcon(symbolName: "pencil.and.scribble", displayName: "Escribir", category: .learning, keywords: ["diario", "notas", "redactar"]),
        HabitIcon(symbolName: "paintbrush.pointed.fill", displayName: "Crear", category: .learning, keywords: ["arte", "pintar", "dibujo"]),
        HabitIcon(symbolName: "apple.terminal", displayName: "Programar", category: .learning, keywords: ["programar", "desarrollo", "informatica"]),
        HabitIcon(symbolName: "music.note", displayName: "Música", category: .learning, keywords: ["instrumento", "practicar", "canción"]),
        HabitIcon(symbolName: "lightbulb.fill", displayName: "Aprender", category: .learning, keywords: ["idea", "conocimiento", "repasar"]),

        HabitIcon(symbolName: "house.fill", displayName: "Casa", category: .home, keywords: ["hogar", "vivienda", "familia"]),
        HabitIcon(symbolName: "sparkles", displayName: "Limpiar", category: .home, keywords: ["limpieza", "ordenar", "casa"]),
        HabitIcon(symbolName: "washer.fill", displayName: "Lavar ropa", category: .home, keywords: ["lavadora", "colada", "ropa"]),
        HabitIcon(symbolName: "trash.fill", displayName: "Sacar la basura", category: .home, keywords: ["reciclar", "residuos", "limpiar"]),
        HabitIcon(symbolName: "leaf.fill", displayName: "Cuidar plantas", category: .home, keywords: ["regar", "jardín", "naturaleza"]),
        HabitIcon(symbolName: "pawprint.fill", displayName: "Cuidar mascota", category: .home, keywords: ["perro", "gato", "animal"]),

        HabitIcon(symbolName: "checkmark.circle.fill", displayName: "Objetivo", category: .other, keywords: ["meta", "completar", "logro"]),
        HabitIcon(symbolName: "star.fill", displayName: "Favorito", category: .other, keywords: ["estrella", "importante", "destacado"]),
        HabitIcon(symbolName: "calendar", displayName: "Planificar", category: .other, keywords: ["agenda", "fecha", "organizar"]),
        HabitIcon(symbolName: "clock.fill", displayName: "Puntualidad", category: .other, keywords: ["hora", "tiempo", "alarma"]),
        HabitIcon(symbolName: "phone.fill", displayName: "Llamar", category: .other, keywords: ["teléfono", "contactar", "comunicar"]),
        HabitIcon(symbolName: "person.2.fill", displayName: "Socializar", category: .other, keywords: ["amistad", "familia", "personas"]),
        HabitIcon(symbolName: "briefcase.fill", displayName: "Trabajo", category: .other, keywords: ["oficina", "profesión", "tarea"])
    ]

    static func icon(named symbolName: String) -> HabitIcon? {
        icons.first { $0.symbolName == symbolName }
    }
}

private extension String {
    var normalizedForHabitIconSearch: String {
        folding(
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: Locale(identifier: "es_ES")
        )
        .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
