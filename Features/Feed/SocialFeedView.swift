//
//  SocialFeedView.swift
//  Road Tribe
//
//  Feed tab — chronological list of posts from people you follow plus your own.
//

import SwiftUI
import SwiftData

struct SocialFeedView: View {
    @Environment(SocialService.self) private var social
    @Query(sort: \Post.createdAt, order: .reverse) private var posts: [Post]
    @Query private var profiles: [UserProfile]
    @Query private var likes: [Like]

    var body: some View {
        NavigationStack {
            Group {
                if posts.isEmpty {
                    ContentUnavailableView(
                        "Quiet Out There",
                        systemImage: "text.bubble",
                        description: Text("Your feed is empty. Follow other riders to see their posts.")
                    )
                } else {
                    feedList
                }
            }
            .navigationTitle("Feed")
        }
    }

    private var feedList: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.sm) {
                ForEach(posts) { post in
                    PostRow(
                        post: post,
                        author: social.profileFor(post.authorID, in: profiles),
                        isLiked: social.isLiked(postID: post.id, likes: likes)
                    )
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.bottom, DesignSystem.Spacing.xl)
        }
        .refreshable {
            try? await Task.sleep(for: .milliseconds(400))
        }
    }
}

private struct PostRow: View {
    let post: Post
    let author: UserProfile?
    let isLiked: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 0) {
                    Text(author?.displayName ?? "Unknown rider")
                        .font(.rtCaptionBold)
                    HStack(spacing: 4) {
                        Image(systemName: post.postType.iconName)
                        Text(Formatters.relative.localizedString(for: post.createdAt, relativeTo: .now))
                    }
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                }
                Spacer()
                if let location = post.locationName {
                    Label(location, systemImage: "mappin.circle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Text(post.content)
                .font(.rtBody)
                .fixedSize(horizontal: false, vertical: true)

            if !post.photoDataItems.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        ForEach(post.photoDataItems.indices, id: \.self) { i in
                            if let img = ImageCache.shared.image(from: post.photoDataItems[i]) {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 200, height: 140)
                                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small))
                            }
                        }
                    }
                }
            }

            HStack(spacing: DesignSystem.Spacing.md) {
                Label("\(post.likeCount)", systemImage: isLiked ? "heart.fill" : "heart")
                    .foregroundStyle(isLiked ? DesignSystem.Colors.danger : .secondary)
                Label("\(post.commentCount)", systemImage: "bubble.left")
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .font(.rtCaption)
        }
        .padding(DesignSystem.Spacing.sm)
        .background(Color.rtSurfaceFallback, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
    }
}
