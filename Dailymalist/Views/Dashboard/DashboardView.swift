//
//  DashboardView.swift
//  Dailymalist
//
//  Created by Nachete on 20/06/2026.
//

import SwiftUI

struct DashboardView: View {
    
    @State private var isPortrait: Bool = !UIDevice.current.orientation.isLandscape
    @Environment(\.colorScheme) private var colorScheme

    @State var selectedDay = Date.now
    @State var isCalendarShown: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            TitleSection(selectedDay: $selectedDay, isCalendarShown: $isCalendarShown)
            
            GeometryReader { geometry in
                if(!isPortrait){
                    
                    let spacing: CGFloat = 12
                    let horizontalPadding: CGFloat = 24
                    let availableWidth = max(
                        0,
                        geometry.size.width - horizontalPadding * 2 - spacing * 2
                    )

                    HStack(alignment: .top, spacing: spacing) {
                        AgendaView(day: selectedDay)
                            .frame(width: availableWidth * 0.35)

                        TaskView(day: selectedDay)
                            .frame(width: availableWidth * 0.35)

                        HabitView(isPortrait: isPortrait, day: selectedDay)
                            .frame(width: availableWidth * 0.30)
                    }
                    .padding(.horizontal, horizontalPadding)
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height,
                        alignment: .topLeading
                    )
                    
                } else {
                    VStack() {
                        HStack {
                            AgendaView(day: selectedDay)
                            TaskView(day: selectedDay)
                            
                        }
                        HabitView(isPortrait: isPortrait, day: selectedDay)
                    }
                }
            }.onReceive(
                NotificationCenter.default.publisher(
                    for: UIDevice.orientationDidChangeNotification
                )
            ){ _ in
                let orientation = UIDevice.current.orientation
                
                // Ignora estados transitorios como faceUp, faceDown o unknown.
                guard orientation.isPortrait || orientation.isLandscape else {
                    return
                }
                
                isPortrait = orientation.isPortrait
            }
        }.background(Color(hex: colorScheme == .dark ? 0x111214 : 0xF7F7F4))
    }
}


struct TitleSection: View {
        
    @Environment(\.colorScheme) private var colorScheme
    
    @Binding var selectedDay: Date
    @Binding var isCalendarShown: Bool
    
    @AppStorage("usesTwelveHourClock")
    private var usesTwelveHourClock = false
    
    private static let twelveHourFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    private static let twentyFourHourFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.dateFormat = "H:mm"
        return formatter
    }()
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading){

                HStack(spacing: 12){
                    Image(colorScheme == .dark ? "DailymalistLogoDark" : "DailymalistLogoLight")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 54, height: 54)
                    
                    Text("Dailymalist")
                        .font(.custom("Default", size: 50))
                        .bold()
                }
                
                HStack(alignment: .center){
                    Button(action: {isCalendarShown = true}, label: {
                        Text(selectedDay, format: .dateTime .day() .month(.wide) .year())
                            .font(.title)
                        Image(systemName: "chevron.down")
                    })
                    .buttonStyle(.borderless).foregroundStyle(.primary)
                    .popover(isPresented: $isCalendarShown) {
                        VStack {
                            DatePicker(
                                "Dia que mostrar",
                                selection: $selectedDay,
                                displayedComponents: .date
                            )
                            .datePickerStyle(.graphical)
                            HStack (alignment: .center){
                                Spacer()

                                Button("Hoy") {
                                    selectedDay = .now
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }.padding()
                        .frame(width: 330)
                        .presentationCompactAdaptation(.popover)
                    }
                }
            }
            Spacer()
            Button{
                withAnimation(.snappy(duration: 0.3)) {
                    usesTwelveHourClock.toggle()
                }
            } label: {
                TimelineView(.everyMinute) { context in
                    Text(formattedTime(context.date))
                    .contentTransition(.numericText())
                    .font(Font.system(size: 60))
                    .bold()
                    .monospacedDigit()
                }
                    .padding(.top, 15)
                    .padding(.trailing, 30)
            }.buttonStyle(.borderless)
                .foregroundStyle(.primary)
                .accessibilityLabel("Cambiar formato de hora")
            
        }.padding()
    }
    
    private func formattedTime(_ date: Date) -> String {
        let formatter = usesTwelveHourClock
            ? Self.twelveHourFormatter
            : Self.twentyFourHourFormatter

        return formatter.string(from: date)
    }
}

#Preview("Default") {
    DashboardView()
}

#Preview("Ingles") {
    DashboardView()
        .environment(\.locale, Locale(identifier: "en_GB"))
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
