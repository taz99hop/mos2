import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = CameraViewModel()

    var body: some View {
        ZStack {
            CameraPreview(session: viewModel.manager.session)
                .ignoresSafeArea()
                .overlay(alignment: .top) {
                    topBar
                }
                .overlay(alignment: .bottom) {
                    bottomBar
                }
                .overlay(alignment: .center) {
                    if let message = viewModel.statusMessage {
                        Text(message)
                            .padding(10)
                            .background(.black.opacity(0.6))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .gesture(
                    MagnificationGesture()
                        .onChanged { scale in
                            viewModel.setZoom(scale)
                        }
                )
                .onTapGesture { location in
                    viewModel.focus(at: location)
                }
        }
        .task {
            await viewModel.initialize()
        }
    }

    private var topBar: some View {
        HStack {
            Button(action: viewModel.toggleFlash) {
                Image(systemName: viewModel.isFlashEnabled ? "bolt.fill" : "bolt.slash")
                    .font(.title2)
                    .foregroundStyle(.white)
            }

            Spacer()

            Text("4K")
                .font(.headline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.black.opacity(0.5))
                .clipShape(Capsule())
                .foregroundStyle(.white)

            Spacer()

            Button(action: viewModel.switchCamera) {
                Image(systemName: "arrow.triangle.2.circlepath.camera")
                    .font(.title2)
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    private var bottomBar: some View {
        HStack(spacing: 40) {
            Button(action: viewModel.toggleVideoMode) {
                VStack {
                    Image(systemName: viewModel.isVideoMode ? "video.fill" : "camera.fill")
                    Text(viewModel.isVideoMode ? "Video" : "Photo")
                        .font(.caption)
                }
                .foregroundStyle(.white)
            }

            Button(action: viewModel.capture) {
                Circle()
                    .stroke(.white, lineWidth: 4)
                    .frame(width: 78, height: 78)
                    .overlay {
                        Circle()
                            .fill(viewModel.isRecording ? .red : .white)
                            .frame(width: 62, height: 62)
                    }
            }

            VStack {
                Text(String(format: "%.1fx", viewModel.currentZoom))
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("Zoom")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .padding(.bottom, 28)
    }
}

#Preview {
    ContentView()
}
