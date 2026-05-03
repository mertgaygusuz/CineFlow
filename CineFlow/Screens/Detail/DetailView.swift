import SwiftUI
import Kingfisher

struct DetailView: View {
    @StateObject private var viewModel: DetailViewModel
    @Environment(\.dismiss) private var dismiss

    init(movieId: Int, movie: Movie? = nil) {
        _viewModel = StateObject(wrappedValue: DetailViewModel(movieId: movieId, movie: movie))
    }

    var body: some View {
        ZStack {
            Color.darkBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    backdrop
                    VStack(alignment: .leading, spacing: 24) {
                        info
                        if viewModel.trailer != nil { trailerSection }
                        if !viewModel.cast.isEmpty  { castSection }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 32)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            if viewModel.isLoading {
                Color.black.opacity(0.4).ignoresSafeArea()
                ProgressView().tint(.white).scaleEffect(1.4)
            }
        }
        .navigationTitle(viewModel.detail?.title ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { viewModel.toggleFavorite() } label: {
                    Image(systemName: viewModel.isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(.primaryRed)
                }
            }
        }
        .task { await viewModel.loadAll() }
        .alert("common.error".localized,
               isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
               ),
               presenting: viewModel.errorMessage) { _ in
            Button("common.ok".localized) { dismiss() }
        } message: { msg in
            Text(msg)
        }
    }

    // MARK: - Backdrop
    private var backdrop: some View {
        GeometryReader { geo in
            KFImage(viewModel.detail?.backdropURL ?? viewModel.detail?.posterURL)
                .resizable()
                .scaledToFill()
                .frame(width: geo.size.width, height: geo.size.width * 9 / 16)
                .clipped()
                .background(Color.cardBackground)
        }
        .aspectRatio(16/9, contentMode: .fit)
    }

    // MARK: - Info
    private var info: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                if let url = viewModel.imdbURL {
                    Link(destination: url) {
                        Text("IMDb")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color(red: 245/255, green: 197/255, blue: 24/255))
                            .cornerRadius(4)
                    }
                }
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: 14))
                if let detail = viewModel.detail {
                    Text(String(format: "%.1f/10", detail.voteAverage))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    Text("•").foregroundColor(.subtitleGray).font(.system(size: 14))
                    Text(detail.releaseDate?.formattedDate ?? "")
                        .font(.system(size: 14))
                        .foregroundColor(.subtitleGray)
                }
                Spacer()
            }

            if let detail = viewModel.detail {
                Text(detail.title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                Text(detail.overview)
                    .font(.system(size: 14))
                    .foregroundColor(.subtitleGray)
            }
        }
    }

    // MARK: - Trailer
    private var trailerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("detail.trailer".localized)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)

            if let trailer = viewModel.trailer, let url = trailer.youtubeURL {
                Link(destination: url) {
                    ZStack {
                        KFImage(trailer.thumbnailURL)
                            .resizable()
                            .scaledToFill()
                        Color.black.opacity(0.45)
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                            .overlay(
                                Image(systemName: "play.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 24))
                            )
                    }
                    .aspectRatio(16/9, contentMode: .fit)
                    .background(Color.cardBackground)
                    .cornerRadius(10)
                    .clipped()
                }
            }
        }
    }

    // MARK: - Cast
    private var castSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("detail.cast".localized)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.cast, id: \.id) { member in
                        CastView(member: member)
                    }
                }
            }
        }
    }
}

private struct CastView: View {
    let member: CastMember

    var body: some View {
        VStack(spacing: 6) {
            KFImage(member.profileURL)
                .placeholder {
                    Image(systemName: "person.fill")
                        .foregroundColor(.subtitleGray)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.cardBackground)
                }
                .resizable()
                .scaledToFill()
                .frame(width: 90, height: 90)
                .clipShape(Circle())

            Text(member.name)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
            Text(member.character)
                .font(.system(size: 11))
                .foregroundColor(.subtitleGray)
                .lineLimit(1)
        }
        .frame(width: 90)
    }
}

// MARK: - SwiftUI Color helpers
private extension Color {
    static let primaryRed     = Color(red: 229/255, green: 9/255,   blue: 20/255)
    static let darkBackground = Color(red: 18/255,  green: 18/255,  blue: 18/255)
    static let cardBackground = Color(red: 30/255,  green: 30/255,  blue: 30/255)
    static let subtitleGray   = Color(red: 150/255, green: 150/255, blue: 150/255)
}
