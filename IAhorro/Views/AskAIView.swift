import SwiftUI

struct AskAIView: View {
    @ObservedObject var viewModel: AskAIViewModel

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Haz preguntas sobre tus gastos")
                    .font(.headline)
                TextField("¿Qué necesitas saber?", text: $viewModel.query, axis: .vertical)
                    .textFieldStyle(.roundedBorder)

                Button {
                    Task { await viewModel.submitQuery() }
                } label: {
                    Label("Consultar", systemImage: "sparkles")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoading)

                if viewModel.isLoading {
                    ProgressView("Analizando con IA…")
                        .frame(maxWidth: .infinity, alignment: .center)
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                }

                if !viewModel.answer.isEmpty {
                    ScrollView {
                        Text(viewModel.answer)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    Spacer()
                }
            }
            .padding()
            .navigationTitle("Asistente IA")
        }
    }
}
