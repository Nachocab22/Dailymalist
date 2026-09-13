//
//  AgendaView.swift
//  Dailymalist
//
//  Created by Nachete on 25/06/2026.
//

import SwiftUI
import EventKitUI

struct AgendaView: View {
    
    @AppStorage("agenda.selectedCalendarIDs")
    private var savedCalendarIDs: Data = Data()
    
    @State private var store: EKEventStore = EKEventStore()
    var day: Date
    
    @State private var events : [EKEvent] = []
    @State private var calendars : [EKCalendar] = []
    @State private var calendarError : String?
    @State private var isCalendarChooseShown : Bool = false
    
    @State private var refreshTrigger = 0
    
    private var selectedCalendarIDs: Set<String> {
        get {
            (try? JSONDecoder().decode(
                Set<String>.self,
                from: savedCalendarIDs
            )) ?? []
        }
        nonmutating set {
            guard let data = try? JSONEncoder().encode(newValue) else {
                return
            }

            savedCalendarIDs = data
        }
    }
    
    var body: some View {
        VStack(alignment: .leading){
            HStack{
                Text("Agenda")
                    .font(Font.system(size: 30, weight: .bold))
                    .padding()
                Spacer()
                Button{
                    Task {
                       await openCalendarChooser()
                    }
                } label: {
                    Image(systemName: "calendar.badge.checkmark")
                }.buttonStyle(.glassProminent)
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 20))
            }
            if(selectedCalendarIDs.isEmpty){
                HStack{
                    Text("Selecciona los calendarios que mostrar")
                    Image(systemName: "arrow.turn.right.up")
                }
                .padding()
                .foregroundStyle(.gray)
                
            }
            else { EmptyView() }
            if calendarError != nil {
                Text(calendarError ?? "Selecciona los calendarios que mostrar")
                    .font(Font.system(size: 30, weight: .semibold))
                    .foregroundStyle(.red)
                    .padding()
            } else {
                events.isEmpty && !selectedCalendarIDs.isEmpty ? Text("No hay eventos programados").padding().foregroundStyle(.gray) : nil
                List {
                    let allDayEvents = events.filter { $0.isAllDay }

                    Section {
                        ForEach(allDayEvents, id: \.self) { event in
                            EventRow(event: event)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .listRowInsets(
                                    EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10)
                                )
                        }
                    }

                    Section {
                        if !allDayEvents.isEmpty {
                            Rectangle()
                                .opacity(0.2)
                                .frame(height: 2)
                                .cornerRadius(10)
                                .listRowBackground(Color.clear)
                        }

                        ForEach(
                            events
                                .filter { !$0.isAllDay }
                                .sorted { $0.startDate < $1.startDate },
                            id: \.self
                        ) { event in
                            EventRow(event: event)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .listRowInsets(
                                    EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10)
                                )
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .refreshable{
                    await MainActor.run {
                        refreshTrigger += 1
                        loadAgenda()
                    }
                }
            }
        }
        .task { loadAgenda() }
        .onChange(of: day){ retrieveEvents() }
        .sheet(isPresented: $isCalendarChooseShown, content: {
            NavigationStack{
                List(calendars, id: \.calendarIdentifier){ calendar in
                    Toggle(isOn: Binding(
                        get: {
                            selectedCalendarIDs.contains(calendar.calendarIdentifier)
                        },
                        set: { isSelected in
                            if isSelected {
                                selectedCalendarIDs.insert(calendar.calendarIdentifier)
                            } else {
                                selectedCalendarIDs.remove(calendar.calendarIdentifier)
                            }
                        }
                    )) {
                        HStack {
                            Circle()
                                .fill(Color(cgColor: calendar.cgColor))
                                .frame(width: 12, height: 12)

                            VStack(alignment: .leading) {
                                Text(calendar.title)

                                Text(calendar.source.title)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }.navigationTitle("Calendarios")
                    .toolbar {
                        Button("Hecho") {
                            retrieveEvents()
                            isCalendarChooseShown = false
                        }
                    }
            }
        })
    }
    
    @MainActor
    private func loadAgenda() {
        guard EKEventStore.authorizationStatus(for: .event) == .fullAccess else {
            calendars = []
            events = []
            return
        }

        calendars = store.calendars(for: .event)
        retrieveEvents()
    }
    
    @MainActor
    private func openCalendarChooser() async {
        
        do {
            guard try await store.requestFullAccessToEvents() else {
                calendarError = "No has permitido el acceso al calendario."
                return
            }

            calendars = store.calendars(for: .event)
            calendarError = nil
            isCalendarChooseShown = true
        } catch {
            calendarError = error.localizedDescription
        }
    }
    
    @MainActor
    private func retrieveEvents() {
            
        let selectedCalendars = calendars.filter {
            selectedCalendarIDs.contains($0.calendarIdentifier)
        }
        
        guard !selectedCalendars.isEmpty else {
            events = []
            calendarError = nil
            return
        }

        let start = Calendar.current.startOfDay(for: day)
        guard let end = Calendar.current.date(
            byAdding: .day,
            value: 1,
            to: start
        ) else { return }

        let predicate = store.predicateForEvents(
            withStart: start,
            end: end,
            calendars: selectedCalendars
        )

        events = store.events(matching: predicate)
            .sorted { $0.startDate < $1.startDate }

        calendarError = nil
        
    }
}
    
#Preview {
    AgendaView(day: .now)
}

struct EventRow: View {
    
    @Environment(\.colorScheme) private var colorScheme
    let event: EKEvent
    
    var body: some View {
        if(event.isAllDay){
            HStack(alignment: .top){
                VStack(alignment: .leading, spacing: 6){
                    Text(event.title ?? "Nuevo evento")
                        .font(Font.system(size: 18, weight: .bold))
                    event.location != nil ?
                    HStack{
                        Image(systemName: "location.circle")
                        event.location != nil ? Text(event.location ?? "Sin información") : Text("Sin ubicación").foregroundStyle(Color.gray)
                    } : nil
                }.frame(maxWidth: .greatestFiniteMagnitude, alignment: .leading)
                if(event.location == nil){
                    ZStack {
                        Circle()
                            .fill(Color(cgColor: event.calendar.cgColor))
                            .frame(width: 15)
                    }.frame(maxHeight: .infinity, alignment: .center)
                    
                } else {
                    Rectangle()
                        .fill(Color(cgColor: event.calendar.cgColor))
                        .frame(width: 8)
                        .cornerRadius(10)
                }
                
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 10).fill(
                    Color(hex: colorScheme == .dark ? 0x1C1C1E : 0xFFFFFF)
                )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(uiColor: .gray), lineWidth: 2)
            }
        } else {
            HStack(alignment: .top){
                VStack(alignment: .leading, spacing: 6){
                    HStack{
                        event.hasAlarms ? Image(systemName: "bell.fill").foregroundStyle(.yellow) : nil
                        Text(event.title ?? "Nuevo evento")
                            .font(Font.system(size: 18, weight: .bold))
                    }
                    event.location != nil ?
                    HStack{
                        Image(systemName: "location.circle")
                        event.location != nil ? Text(event.location ?? "Sin información") : Text("Sin ubicación").foregroundStyle(Color.gray)
                    } : nil
                    HStack{
                        Image(systemName: "clock")
                        Text("\(event.startDate.formatted(date: .omitted, time: .shortened)) - \(event.endDate.formatted(date: .omitted, time: .shortened))")
                    }
                }.frame(maxWidth: .greatestFiniteMagnitude, alignment: .leading)
                Rectangle()
                    .fill(Color(cgColor: event.calendar.cgColor))
                    .frame(width: 8)
                    .cornerRadius(10)
                
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 10).fill(
                    Color(hex: colorScheme == .dark ? 0x1C1C1E : 0xFFFFFF)
                )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(uiColor: .gray), lineWidth: 2)
            }
        }
    }
}
