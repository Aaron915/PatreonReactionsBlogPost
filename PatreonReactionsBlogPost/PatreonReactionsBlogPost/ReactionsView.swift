//
//  ReactionsView.swift
//  ReactionsSwiftUIBlogPost
//
//  Created by Aaron Williams on 1/26/25.


import SwiftUI

struct ReactionsView: View {

  private static let reactionSize = 44.0

  @State var date = Date()

  @StateObject private var reactionsManager = ReactionsManager()

  var body: some View {
    VStack {
      TimelineView(.animation) { timeline in
        Canvas { context, size in
          // keep track of reactions we've already resolved.
          var resolvedReactions = [String: GraphicsContext.ResolvedText]()

          var reactionsToRemove = Set<Int>()
          for (index, reaction) in reactionsManager.reactions.enumerated() {
            let timeDiff = timeline.date.timeIntervalSince(reaction.timestamp)
            guard timeDiff <= reaction.animationTime else {
              reactionsToRemove.insert(index)
              continue
            }

            let resolvedText: GraphicsContext.ResolvedText

            if let resolved = resolvedReactions[reaction.emoji] {
              resolvedText = resolved
            } else {
              let resolvedReaction = context.resolve(
                Text(
                  String(reaction.emoji)
                ).font(.system(size: Self.reactionSize)))
              resolvedReactions[reaction.emoji] = resolvedReaction
              resolvedText = resolvedReaction
            }

            let animationProgress = timeDiff / reaction.animationTime

            // Uses an exponential ease-out curve
            // https://easings.net/#easeOutExpo
            let verticalPosition = (1 - pow(1 - animationProgress, 2.3)) * reaction.verticalDistance
            // uses an exponential ease-in curve.
            // https://easings.net/#easeInExpo
            let horizontalPosition = pow(animationProgress, 1.5) * reaction.horizontalDistance
            let rotation = horizontalPosition * 60.0
            let opacity = 1 - pow(animationProgress, 11)


            let startingSize = 0.6
            let scaleFactor = startingSize + (pow(animationProgress, 2.7) * (1 - startingSize))
            let reactionPosition = CGPoint(
              x: (size.width - 42.0) + horizontalPosition * 42.0,
              y: size.height * (1 - verticalPosition)
            )

            var innerContext = context
            innerContext.opacity = opacity

            innerContext.translateBy(x: reactionPosition.x, y: reactionPosition.y)
            innerContext.scaleBy(x: scaleFactor, y: scaleFactor)
            innerContext.rotate(by: .degrees(rotation))
            innerContext.translateBy(x: -reactionPosition.x, y: -reactionPosition.y)

            innerContext.draw(resolvedText, at: reactionPosition, anchor: .center)
          }
          reactionsManager.reactions.remove(atOffsets: IndexSet(reactionsToRemove))
        }
      }
      .opacity(0.7)
      .background(Color.clear)
      ReactionButtons { emoji in
        reactionsManager.reactions.append(ReactionsManager.Reaction(emoji: emoji))
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding()
  }
}

@MainActor private final class ReactionsManager: ObservableObject {

  struct Reaction {
    //emoji to display
    let emoji: String
    // start time of the reaction
    let timestamp: Date
    // normalized vertical distance
    let verticalDistance: Double
    let animationTime: TimeInterval

    // normalized horizontal distance
    let horizontalDistance: Double

    init(emoji: String) {
      self.emoji = emoji
      self.timestamp = Date()
      self.verticalDistance = Double.random(in: 0.5...0.65)
      self.animationTime = Double.random(in: 1.4...1.8)
      self.horizontalDistance = Double.random(in: -1.0...1.0)
    }
  }

  var reactions: [Reaction] = []
}

#Preview {
  ReactionsView()
    .preferredColorScheme(.dark)
}

struct ReactionButtons: View {

  var onReactionTap: (String) -> Void

  private static let emojis = ["❤️", "🎉", "🔥"]

  var body: some View {
    VStack(spacing: 16.0) {
      HStack {
        Spacer()
        ForEach(Self.emojis, id: \.self) { emoji in
          Button(emoji) {
            onReactionTap(emoji)
          }
          .padding()
          .frame(minWidth: 75.0)
          .background(.thickMaterial, in: Capsule())
          Spacer()
        }
      }
      Button("🎆 Finale") {
        Task {
          for _ in 0..<100 {
            try await Task.sleep(for: .milliseconds(Int.random(in: 10...20)))
            onReactionTap("❤️")
          }
        }
      }
      .padding()
      .frame(minWidth: 150.0)
      .font(.headline)
      .foregroundStyle(.white)
      .background(.thickMaterial, in: Capsule())
    }
  }
}
