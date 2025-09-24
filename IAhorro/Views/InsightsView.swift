import SwiftUI

struct InsightsView: View {
    @ObservedObject var viewModel: InsightsViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    totalsCard
                    categoriesSection
                    keywordsSection
                }
                .padding()
            }
            .navigationTitle("Insights")
        }
    }

    private var totalsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Gasto total")
                .font(.headline)
            Text(NSDecimalNumber(decimal: viewModel.totalSpent), formatter: NumberFormatter.currencyFormatter(code: Locale.current.currency?.identifier ?? "USD"))
                .font(.largeTitle).bold()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemGroupedBackground)))
    }

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Por categoría")
                .font(.headline)
            ForEach(viewModel.categorySummaries) { summary in
                HStack {
                    Label(summary.category.displayName, systemImage: summary.category.iconSystemName)
                    Spacer()
                    Text(NSDecimalNumber(decimal: summary.total), formatter: NumberFormatter.currencyFormatter(code: Locale.current.currency?.identifier ?? "USD"))
                }
                .padding(.vertical, 8)
                Divider()
            }
        }
    }

    private var keywordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Palabras clave destacadas")
                .font(.headline)
            if viewModel.keywords.isEmpty {
                Text("Aún no hay suficientes boletas analizadas.")
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 8)], spacing: 8) {
                    ForEach(viewModel.keywords, id: \.self) { keyword in
                        Text(keyword)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Color.green.opacity(0.15)))
                    }
                }
            }
        }
    }
}
