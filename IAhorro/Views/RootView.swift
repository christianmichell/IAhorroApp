import SwiftUI

struct RootView: View {
    @EnvironmentObject private var receiptStore: ReceiptStore
    @StateObject private var listViewModel: ReceiptListViewModel
    @StateObject private var insightsViewModel: InsightsViewModel
    @StateObject private var askAIViewModel: AskAIViewModel
    init(answerService: ReceiptAnswering, processingService: ReceiptProcessingServiceProtocol, receiptStore: ReceiptStore) {
        _listViewModel = StateObject(wrappedValue: ReceiptListViewModel(receiptStore: receiptStore))
        _insightsViewModel = StateObject(wrappedValue: InsightsViewModel(receiptPublisher: receiptStore.$receipts))
        _askAIViewModel = StateObject(wrappedValue: AskAIViewModel(receiptStore: receiptStore, answerService: answerService))
        self.processingService = processingService
        self.receiptStore = receiptStore
    }
    private let processingService: ReceiptProcessingServiceProtocol
    private let receiptStore: ReceiptStore

    var body: some View {
        TabView {
            NavigationStack {
                ReceiptListView(viewModel: listViewModel, processingService: processingService, receiptStore: receiptStore)
                    .navigationTitle("Boletas")
            }
            .tabItem {
                Label("Boletas", systemImage: "doc.richtext")
            }

            InsightsView(viewModel: insightsViewModel)
                .tabItem {
                    Label("Insights", systemImage: "chart.pie.fill")
                }

            AskAIView(viewModel: askAIViewModel)
                .tabItem {
                    Label("IA", systemImage: "sparkles")
                }
        }
    }
}
