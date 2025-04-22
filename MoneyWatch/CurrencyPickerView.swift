import SwiftUI

struct CurrencyPickerView: View {
    @Binding var selectedCurrency: String
    @Binding var isPresented: Bool
    var currencies: [String]
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Select Currency")
                .font(.headline)
                .padding(.top, 10)
            
            List {
                ForEach(currencies, id: \.self) { currency in
                    Button(action: {
                        selectedCurrency = currency
                        isPresented = false
                    }) {
                        HStack {
                            Text(currency)
                                .font(.title3)
                            
                            Spacer()
                            
                            if selectedCurrency == currency {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .frame(width: 200, height: 300)
    }
}

struct CurrencyPickerView_Previews: PreviewProvider {
    static var previews: some View {
        CurrencyPickerView(
            selectedCurrency: .constant("$"),
            isPresented: .constant(true),
            currencies: ["$", "€", "£", "¥", "₹", "₽", "₩", "A$", "C$"]
        )
    }
}
