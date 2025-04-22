import SwiftUI

struct PayRateInputView: View {
    @Binding var hourlyRate: Double
    @Binding var isPresented: Bool
    @Binding var accumulatedEarnings: Double
    @Binding var lastPayRateChangeTime: TimeInterval
    @Binding var elapsedTime: TimeInterval
    var currency: String
    @State private var rateString: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Set Hourly Pay Rate")
                .font(.headline)
            
            HStack {
                Text(currency)
                    .font(.title2)
                
                TextField("Hourly Rate", text: $rateString)
                    .font(.title2)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Text("/hour")
                    .font(.title2)
            }
            .padding()
            
            HStack(spacing: 20) {
                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(.bordered)
                
                Button("Save") {
                    if let rate = Double(rateString), rate > 0 {
                        // Calculate and store earnings with old rate before changing
                        let currentSessionEarnings = hourlyRate * (elapsedTime - lastPayRateChangeTime) / 3600
                        accumulatedEarnings += currentSessionEarnings
                        
                        // Update to new rate and reset the rate change time
                        hourlyRate = rate
                        lastPayRateChangeTime = elapsedTime
                    }
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 300)
        .onAppear {
            rateString = String(format: "%.2f", hourlyRate)
        }
    }
}

struct PayRateInputView_Previews: PreviewProvider {
    static var previews: some View {
        PayRateInputView(
            hourlyRate: .constant(40.0),
            isPresented: .constant(true),
            accumulatedEarnings: .constant(0.0),
            lastPayRateChangeTime: .constant(0.0),
            elapsedTime: .constant(0.0),
            currency: "$"
        )
    }
}
