import SwiftUI

struct ContentView: View {
    @ObservedObject var pomodoroManager: PomodoroManager
    @State private var showingSettings = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Text(pomodoroManager.phaseTitle)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(phaseColor)
                
                Text(pomodoroManager.formattedTime)
                    .font(.system(size: 48, weight: .thin, design: .monospaced))
                    .foregroundColor(phaseColor)
            }
            .padding(.top, 20)
            
            // Progress Bar
            ProgressView(value: pomodoroManager.progress)
                .progressViewStyle(LinearProgressViewStyle(tint: phaseColor))
                .scaleEffect(x: 1, y: 2, anchor: .center)
                .padding(.horizontal, 20)
            
            // Session Info
            HStack {
                VStack(alignment: .leading) {
                    Text("Focus Sessions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(pomodoroManager.completedFocusSessions)")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Short Breaks")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(pomodoroManager.completedShortBreaks)")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
            }
            .padding(.horizontal, 20)
            
            // Control Buttons
            VStack(spacing: 10) {
                Button(action: {
                    pomodoroManager.toggleTimer()
                    // Notify app delegate to update timer state
                    NotificationCenter.default.post(name: NSNotification.Name("TimerStateChanged"), object: nil)
                }) {
                    HStack {
                        Image(systemName: pomodoroManager.isRunning ? "pause.fill" : "play.fill")
                        Text(pomodoroManager.isRunning ? "Pause" : "Start")
                    }
                    .frame(minWidth: 80)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                HStack(spacing: 15) {
                    Button(action: { 
                        pomodoroManager.resetTimer()
                        // Notify app delegate to update timer state
                        NotificationCenter.default.post(name: NSNotification.Name("TimerStateChanged"), object: nil)
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Reset")
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    
                    Button(action: { 
                        pomodoroManager.skipToNextPhase()
                        // Notify app delegate to update timer state
                        NotificationCenter.default.post(name: NSNotification.Name("TimerStateChanged"), object: nil)
                    }) {
                        HStack {
                            Image(systemName: "forward.fill")
                            Text("Skip")
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }
            .padding(.horizontal, 20)
            
            // Settings Button
            Button("Settings") {
                showingSettings = true
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .foregroundColor(.secondary)
            .padding(.top, 20)
        }
        .frame(width: 300, height: 410)
        .padding(.horizontal, 15)
        .sheet(isPresented: $showingSettings) {
            SettingsView(pomodoroManager: pomodoroManager)
        }
    }
    
    private var phaseColor: Color {
        switch pomodoroManager.currentPhase {
        case .focus:
            return .red
        case .shortBreak:
            return .green
        case .longBreak:
            return .blue
        }
    }
}

struct SettingsView: View {
    @ObservedObject var pomodoroManager: PomodoroManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 10)

            // Timer Durations Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Timer Durations")
                    .font(.headline)
                    .fontWeight(.bold)
                
                VStack(spacing: 10) {
                    HStack {
                        Text("Focus Duration")
                            .frame(width: 130, alignment: .leading)
                        Spacer()
                        Picker("Focus Time", selection: $pomodoroManager.focusDuration) {
                            ForEach([15, 20, 25, 30, 35, 40, 45, 50, 55, 60], id: \.self) { minutes in
                                Text("\(minutes) min").tag(minutes * 60)
                            }
                        }
                        .frame(width: 150)
                    }
                    
                    HStack {
                        Text("Short Break")
                            .frame(width: 130, alignment: .leading)
                        Spacer()
                        Picker("Short Break", selection: $pomodoroManager.shortBreakDuration) {
                            ForEach([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], id: \.self) { minutes in
                                Text("\(minutes) min").tag(minutes * 60)
                            }
                        }
                        .frame(width: 150)
                    }
                    
                    HStack {
                        Text("Long Break")
                            .frame(width: 130, alignment: .leading)
                        Spacer()
                        Picker("Long Break", selection: $pomodoroManager.longBreakDuration) {
                            ForEach([10, 15, 20, 25, 30], id: \.self) { minutes in
                                Text("\(minutes) min").tag(minutes * 60)
                            }
                        }
                        .frame(width: 150)
                    }
                }
            }

            Divider()

            // Session Settings Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Session Settings")
                    .font(.headline)
                    .fontWeight(.bold)
                
                HStack {
                    Text("Sessions before Long Break")
                        .frame(alignment: .leading)
                    Spacer()
                    Picker("Sessions", selection: $pomodoroManager.sessionsBeforeLongBreak) {
                        ForEach([2, 3, 4, 5, 6], id: \.self) { sessions in
                            Text("\(sessions)").tag(sessions)
                        }
                    }
                    .frame(width: 130)
                }
            }

            Divider()

            // Sound Settings Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Sound Settings")
                    .font(.headline)
                    .fontWeight(.bold)
                
                HStack {
                    Text("Completion Sound")
                        .frame(alignment: .leading)
                    Spacer()
                    Picker("Sound", selection: $pomodoroManager.selectedSound) {
                        ForEach(PomodoroManager.availableSounds, id: \.self) { sound in
                            Text(sound).tag(sound)
                        }
                    }
                    .frame(width: 150)
                }
                
                // Test sound button
                Button(action: {
                    pomodoroManager.showNotification()
                }) {
                    HStack {
                        Image(systemName: "speaker.wave.2")
                        Text("Test Sound")
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .padding(.top, 5)
            }

            Divider()

            // Keyboard Shortcuts Section (Informational)
            VStack(alignment: .leading, spacing: 5) {
                Text("Keyboard Shortcuts")
                    .font(.headline)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "keyboard")
                            .foregroundColor(.secondary)
                            .frame(width: 16)
                        Text("⌘⇧Space")
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.medium)
                        Text("Start/Pause Timer")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "keyboard")
                            .foregroundColor(.secondary)
                            .frame(width: 16)
                        Text("⌘⇧R")
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.medium)
                        Text("Reset Timer")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "keyboard")
                            .foregroundColor(.secondary)
                            .frame(width: 16)
                        Text("⌘⇧S")
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.medium)
                        Text("Skip to Next Phase")
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.leading, 4)
            }

            Divider()

            // Done Button
            HStack {
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 400, height: 520)
    }
}

#Preview {
    ContentView(pomodoroManager: PomodoroManager())
} 
