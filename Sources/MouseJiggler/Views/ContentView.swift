import SwiftUI

struct ContentView: View {
    @StateObject private var jiggler = JigglerController()
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "cursorarrow.motion.lines")
                    .font(.system(size: 60))
                    .foregroundColor(jiggler.isActive ? .green : .gray)
                    .opacity(jiggler.isActive ? 1.0 : 0.5)
                
                Text("Mouse Jiggler")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Moves cursor to random positions")
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Status Section
            VStack(alignment: .leading, spacing: 12) {
                StatusRow(
                    icon: "power.circle.fill",
                    title: "Status",
                    value: jiggler.isActive ? "Active" : "Inactive",
                    color: jiggler.isActive ? .green : .red
                )
                
                StatusRow(
                    icon: "clock.arrow.circlepath",
                    title: "Idle Time",
                    value: jiggler.formattedIdleTime,
                    color: .blue
                )
                
                StatusRow(
                    icon: "cursorarrow",
                    title: "Last Move",
                    value: jiggler.formattedLastJiggleTime,
                    color: .orange
                )
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Main Toggle Button
            Button(action: {
                jiggler.toggle()
            }) {
                HStack {
                    Image(systemName: jiggler.isActive ? "stop.fill" : "play.fill")
                    Text(jiggler.isActive ? "Stop" : "Start")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(jiggler.isActive ? Color.red : Color.green)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
            
            // Info Text
            Text("Starts moving cursor after 30 seconds of idle time")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 400, height: 400)
    }
}

struct StatusRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.secondary)
        }
    }
}

