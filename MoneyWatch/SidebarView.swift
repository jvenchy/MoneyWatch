import SwiftUI

struct SidebarView: View {
    @Binding var payouts: [PayoutRecord]
    @State private var selectedPayoutID: UUID?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Total section at the top
            VStack(alignment: .leading, spacing: 8) {
                Text("Total Earnings")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text(formatTotalAmount())
                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                    .foregroundColor(.green)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(NSColor.textBackgroundColor))
            
            // Divider between total and history
            Divider()
            
            if payouts.isEmpty {
                VStack {
                    Spacer()
                    Text("No payouts yet")
                        .font(.callout)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Scrollable list of payouts
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        // Add some top padding to prevent the first item from being cut off
                        Spacer().frame(height: 8)
                        
                        ForEach(payouts) { payout in
                            HStack(alignment: .center) {
                                VStack(alignment: .leading, spacing: 4) {
                                    // Always display as USD
                                    Text("+USD$\(String(format: "%.2f", payout.amount))")
                                        .font(.headline)
                                        .foregroundColor(.green)
                                    
                                    Text(payout.formattedDate)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    deletePayoutRecord(id: payout.id)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red.opacity(0.7))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal)
                        }
                        
                        // Add some bottom padding for better scrolling experience
                        Spacer().frame(height: 8)
                    }
                }
            }
        }
        .frame(width: 250)
    }
    
    private func formatTotalAmount() -> String {
        let total = payouts.reduce(0) { $0 + $1.amount }
        // Always use USD for the total
        return "USD$\(String(format: "%.2f", total))"
    }
    
    private func deletePayoutRecord(id: UUID) {
        withAnimation {
            payouts.removeAll(where: { $0.id == id })
        }
    }
}

struct SidebarView_Previews: PreviewProvider {
    static var samplePayouts: [PayoutRecord] = [
        PayoutRecord(amount: 122.50, timestamp: Date()),
        PayoutRecord(amount: 75.25, timestamp: Date().addingTimeInterval(-3600)),
        PayoutRecord(amount: 42.30, timestamp: Date().addingTimeInterval(-7200))
    ]
    
    static var previews: some View {
        SidebarView(payouts: .constant(samplePayouts))
            .previewLayout(.fixed(width: 250, height: 400))
    }
}
