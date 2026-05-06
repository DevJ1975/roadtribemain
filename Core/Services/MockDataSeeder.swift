//
//  MockDataSeeder.swift
//  Road Tribe
//
//  Created by Jamil Jones on 4/6/26.
//

import Foundation
import SwiftData

/// Seeds the database with fun demo data for showcasing the app.
struct MockDataSeeder {

    // Fixed UUIDs so we can reference members across models
    static let kevinID = UUID(uuidString: "00000001-0000-0000-0000-000000000001")!
    static let bigMikeID = UUID(uuidString: "00000002-0000-0000-0000-000000000002")!
    static let whiskeyID = UUID(uuidString: "00000003-0000-0000-0000-000000000003")!
    static let turboID = UUID(uuidString: "00000004-0000-0000-0000-000000000004")!
    static let redID = UUID(uuidString: "00000005-0000-0000-0000-000000000005")!
    static let patchesID = UUID(uuidString: "00000006-0000-0000-0000-000000000006")!
    static let smokeyID = UUID(uuidString: "00000007-0000-0000-0000-000000000007")!

    static let allMemberIDs = [kevinID, bigMikeID, whiskeyID, turboID, redID, patchesID, smokeyID]

    // Fixed trip IDs for invite references
    static let route66TripID = UUID(uuidString: "30000001-0000-0000-0000-000000000001")!
    static let sturgisTripID = UUID(uuidString: "30000002-0000-0000-0000-000000000002")!
    static let dragonTripID = UUID(uuidString: "30000003-0000-0000-0000-000000000003")!

    // Fixed post IDs for like/comment references
    private static let post1ID = UUID(uuidString: "10000001-0000-0000-0000-000000000001")!
    private static let post2ID = UUID(uuidString: "10000002-0000-0000-0000-000000000002")!
    private static let post3ID = UUID(uuidString: "10000003-0000-0000-0000-000000000003")!
    private static let post4ID = UUID(uuidString: "10000004-0000-0000-0000-000000000004")!
    private static let post5ID = UUID(uuidString: "10000005-0000-0000-0000-000000000005")!
    private static let post6ID = UUID(uuidString: "10000006-0000-0000-0000-000000000006")!
    private static let post7ID = UUID(uuidString: "10000007-0000-0000-0000-000000000007")!
    private static let post8ID = UUID(uuidString: "10000008-0000-0000-0000-000000000008")!
    private static let post9ID = UUID(uuidString: "10000009-0000-0000-0000-000000000009")!
    private static let post10ID = UUID(uuidString: "1000000A-0000-0000-0000-00000000000A")!
    private static let post11ID = UUID(uuidString: "1000000B-0000-0000-0000-00000000000B")!
    private static let post12ID = UUID(uuidString: "1000000C-0000-0000-0000-00000000000C")!
    private static let post13ID = UUID(uuidString: "1000000D-0000-0000-0000-00000000000D")!
    private static let post14ID = UUID(uuidString: "1000000E-0000-0000-0000-00000000000E")!
    private static let post15ID = UUID(uuidString: "1000000F-0000-0000-0000-00000000000F")!
    private static let post16ID = UUID(uuidString: "10000010-0000-0000-0000-000000000010")!
    private static let post17ID = UUID(uuidString: "10000011-0000-0000-0000-000000000011")!
    private static let post18ID = UUID(uuidString: "10000012-0000-0000-0000-000000000012")!

    nonisolated static func seed(context: ModelContext) {
        // Seed core data if profiles don't exist yet
        let profileDescriptor = FetchDescriptor<UserProfile>()
        let profilesExist = (try? context.fetchCount(profileDescriptor)) ?? 0 > 0
        if !profilesExist {
            seedProfiles(context: context)
            seedTribes(context: context)
            seedTrips(context: context)
            seedJournalEntries(context: context)
            seedMotorcycle(context: context)
        }

        // Seed social data if posts don't exist yet
        let postDescriptor = FetchDescriptor<Post>()
        let postsExist = (try? context.fetchCount(postDescriptor)) ?? 0 > 0
        if !postsExist {
            seedPosts(context: context)
            seedFollows(context: context)
            let likeCounts = seedLikes(context: context)
            let commentCounts = seedComments(context: context)

            // Single fetch to apply both like and comment counts
            if let posts = try? context.fetch(postDescriptor) {
                for post in posts {
                    if let lc = likeCounts[post.id] { post.likeCount = lc }
                    if let cc = commentCounts[post.id] { post.commentCount = cc }
                }
            }

            seedConversations(context: context)
            seedRideEvents(context: context)
            seedActivityItems(context: context)
            seedTripInvites(context: context)
        }
    }

    // MARK: - Profiles

    private static func seedProfiles(context: ModelContext) {
        let kevin = UserProfile(
            id: kevinID,
            displayName: "Kevin \"The Governor\" Woodman",
            email: "governor@roadtribe.com",
            avatarImageName: "rider_kevin",
            bio: "Road Captain. BBQ connoisseur. Never missed a poker run. If the road is calling, I'm already on it.",
            tripIDs: [],
            tribeIDs: [],
            totalXP: 2_750   // Warrior
        )

        let bigMike = UserProfile(
            id: bigMikeID,
            displayName: "Big Mike Martinez",
            email: "bigmike@roadtribe.com",
            avatarImageName: "rider_bigmike",
            bio: "6'4\" of pure chrome energy. My Road Glide is louder than my voice, and that's saying something.",
            totalXP: 6_200   // Iron
        )

        let whiskey = UserProfile(
            id: whiskeyID,
            displayName: "Whiskey Williams",
            email: "whiskey@roadtribe.com",
            avatarImageName: "rider_whiskey",
            bio: "Named after my favorite trail beverage, not the drink. Ok, maybe the drink too.",
            totalXP: 1_150   // Rider
        )

        let turbo = UserProfile(
            id: turboID,
            displayName: "Turbo Thompson",
            email: "turbo@roadtribe.com",
            avatarImageName: "rider_turbo",
            bio: "If you can still see me in your mirrors, I'm not going fast enough.",
            totalXP: 8_500   // Iron (near Legend)
        )

        let red = UserProfile(
            id: redID,
            displayName: "Red Richardson",
            email: "red@roadtribe.com",
            avatarImageName: "rider_red",
            bio: "Beard game strong. Rides a Challenger and challenges everything. Except nap time.",
            totalXP: 420     // Recruit (near Rider)
        )

        let patches = UserProfile(
            id: patchesID,
            displayName: "Patches Patterson",
            email: "patches@roadtribe.com",
            avatarImageName: "rider_patches",
            bio: "More patches on my vest than miles on my odometer. Wait... no. I ride A LOT.",
            totalXP: 11_200  // Legend
        )

        let smokey = UserProfile(
            id: smokeyID,
            displayName: "Smokey Stevens",
            email: "smokey@roadtribe.com",
            avatarImageName: "rider_smokey",
            bio: "The one who brings the grill to every pit stop. Brisket at a gas station? You're welcome.",
            totalXP: 3_100   // Warrior
        )

        [kevin, bigMike, whiskey, turbo, red, patches, smokey].forEach {
            context.insert($0)
        }
    }

    // MARK: - Tribes

    private static func seedTribes(context: ModelContext) {
        let brotherhood = TribeGroup(
            name: "Iron Highway Brotherhood",
            groupDescription: "The Governor's riding crew. Seven riders, zero excuses, and an unhealthy obsession with BBQ pit stops.",
            iconName: "shield.fill",
            memberIDs: allMemberIDs
        )

        let weekenders = TribeGroup(
            name: "Sunday Thunder",
            groupDescription: "Weekend warriors. Brunch first, then burn rubber.",
            iconName: "sun.max.fill",
            memberIDs: [kevinID, turboID, redID, smokeyID]
        )

        [brotherhood, weekenders].forEach { context.insert($0) }
    }

    // MARK: - Trips

    private static func seedTrips(context: ModelContext) {
        let cal = Calendar.current

        // ACTIVE TRIP: Route 66 or Bust
        let route66 = Trip(
            id: route66TripID,
            title: "Route 66 or Bust",
            tripDescription: "The big one. LA to Amarillo, old school. The Governor leads the pack through desert heat, roadside diners, and questionable gas station bathrooms.",
            startDate: cal.date(byAdding: .day, value: -3, to: .now) ?? .now,
            endDate: cal.date(byAdding: .day, value: 4, to: .now),
            status: .active,
            coverImageName: "cover_route66",
            memberIDs: allMemberIDs
        )
        context.insert(route66)

        let rt66Waypoints: [(String, Double, Double, WaypointType, Int)] = [
            ("Santa Monica Pier - Start Line", 34.0094, -118.4973, .start, 0),
            ("Bagdad Cafe, Newberry Springs", 34.8247, -116.6754, .restaurant, 1),
            ("Roy's Motel, Amboy", 34.5588, -115.7457, .scenic, 2),
            ("Oatman Ghost Town", 35.0281, -114.3822, .attraction, 3),
            ("Seligman - Birthplace of Route 66", 35.3256, -112.8755, .stop, 4),
            ("Winslow, AZ - Standin' on the Corner", 35.0242, -110.6974, .scenic, 5),
            ("Petrified Forest National Park", 34.8100, -109.7892, .attraction, 6),
            ("Amarillo - The Big Texan", 35.2000, -101.8313, .destination, 7),
        ]
        for (name, lat, lon, type, order) in rt66Waypoints {
            let wp = Waypoint(name: name, latitude: lat, longitude: lon, waypointType: type, sortOrder: order)
            wp.trip = route66
            context.insert(wp)
        }

        // COMPLETED TRIP: Sturgis Run 2025
        let sturgis = Trip(
            id: sturgisTripID,
            title: "Sturgis or Bust 2025",
            tripDescription: "The annual pilgrimage. Big Mike almost bought a second bike. Turbo got a speeding ticket. Classic.",
            startDate: cal.date(byAdding: .month, value: -8, to: .now) ?? .now,
            endDate: cal.date(byAdding: .month, value: -7, to: .now),
            status: .completed,
            coverImageName: "cover_sturgis",
            memberIDs: [kevinID, bigMikeID, turboID, patchesID]
        )
        context.insert(sturgis)

        let sturgisWaypoints: [(String, Double, Double, WaypointType, Int)] = [
            ("Denver, CO - Rally Point", 39.7392, -104.9903, .start, 0),
            ("Buffalo, WY - Lunch Stop", 44.3483, -106.6989, .restaurant, 1),
            ("Sturgis Rally", 44.4097, -103.5091, .destination, 2),
        ]
        for (name, lat, lon, type, order) in sturgisWaypoints {
            let wp = Waypoint(name: name, latitude: lat, longitude: lon, waypointType: type, sortOrder: order)
            wp.trip = sturgis
            context.insert(wp)
        }

        // PLANNING TRIP: Tail of the Dragon
        let dragon = Trip(
            id: dragonTripID,
            title: "Tail of the Dragon Weekend",
            tripDescription: "318 curves in 11 miles. Turbo won't stop talking about it. Red dared everyone. The Governor approved.",
            startDate: cal.date(byAdding: .month, value: 2, to: .now) ?? .now,
            endDate: cal.date(byAdding: .day, value: 65, to: .now),
            status: .planning,
            coverImageName: "cover_dragon",
            memberIDs: [kevinID, turboID, redID, whiskeyID]
        )
        context.insert(dragon)

        let dragonWaypoints: [(String, Double, Double, WaypointType, Int)] = [
            ("Knoxville, TN - Start", 35.9606, -83.9207, .start, 0),
            ("Deals Gap - The Dragon", 35.4590, -83.9190, .scenic, 1),
            ("Fontana Dam", 35.4442, -83.8089, .attraction, 2),
            ("Asheville, NC - Finish Line BBQ", 35.5951, -82.5515, .destination, 3),
        ]
        for (name, lat, lon, type, order) in dragonWaypoints {
            let wp = Waypoint(name: name, latitude: lat, longitude: lon, waypointType: type, sortOrder: order)
            wp.trip = dragon
            context.insert(wp)
        }
    }

    // MARK: - Journal Entries

    private static func seedJournalEntries(context: ModelContext) {
        let cal = Calendar.current

        let entries: [(String, String, JournalMood, Date, String?, Double?, Double?)] = [
            (
                "Big Mike Lost His Sunglasses at 80mph",
                "We were cruising through the Mojave when Big Mike's $200 Oakleys flew right off his face. He tried to turn around on the highway. We said no. He's still mad about it. Legend has it they're still rolling through the desert.",
                .excited,
                cal.date(byAdding: .day, value: -2, to: .now) ?? .now,
                "Mojave Desert, CA",
                34.88, -116.73
            ),
            (
                "The Governor Found the BEST BBQ",
                "Pulled into this tiny shack off Route 66 in Seligman. Hand-painted sign. Smoke billowing. The Governor declared it 'the finest brisket west of Texas.' Smokey was offended. Arguments ensued. More BBQ was consumed. 10/10.",
                .happy,
                cal.date(byAdding: .day, value: -1, to: .now) ?? .now,
                "Seligman, AZ",
                35.32, -112.87
            ),
            (
                "Whiskey's Bike Wouldn't Start... Again",
                "Third time this trip. We all just stood there with our arms crossed. Whiskey kicked it twice, sweet-talked it once, and it fired up. That Scout Bobber runs on pure spite and good vibes. Turbo offered to push. Whiskey declined. Aggressively.",
                .frustrated,
                cal.date(byAdding: .hour, value: -18, to: .now) ?? .now,
                "Oatman, AZ",
                35.02, -114.38
            ),
            (
                "Sunset Over the Painted Desert",
                "Pulled off at a lookout near Winslow. Nobody said a word for ten minutes. Just seven riders, seven bikes, and the most insane sunset any of us had ever seen. Even Turbo slowed down for this one. Red took about 400 photos. Worth it.",
                .relaxed,
                cal.date(byAdding: .hour, value: -6, to: .now) ?? .now,
                "Winslow, AZ",
                35.02, -110.69
            ),
            (
                "Standin' on the Corner in Winslow, Arizona",
                "We did the thing. All seven of us lined up at the 'Standing on the Corner' statue. Patches sang the entire Eagles song. Out loud. In public. Tourists loved it. We pretended not to know him. Then Big Mike joined in. It was chaos.",
                .adventurous,
                cal.date(byAdding: .hour, value: -5, to: .now) ?? .now,
                "Winslow, AZ",
                35.02, -110.69
            ),
            (
                "Turbo Got a Speeding Ticket",
                "Turbo lasted exactly 47 minutes into Day 1 before getting pulled over. The officer looked at all seven of us and just shook his head. Turbo blamed 'the wind.' The wind was 0 mph. We have the WeatherKit data to prove it.",
                .tired,
                cal.date(byAdding: .day, value: -3, to: .now) ?? .now,
                "Barstow, CA",
                34.89, -117.02
            ),
        ]

        for (title, content, mood, date, location, lat, lon) in entries {
            let entry = JournalEntry(
                timestamp: date,
                title: title,
                content: content,
                latitude: lat,
                longitude: lon,
                locationName: location,
                mood: mood,
                weatherDescription: "Clear, 78°F"
            )
            context.insert(entry)
        }
    }

    // MARK: - Kevin's Motorcycle

    private static func seedMotorcycle(context: ModelContext) {
        let indian = Motorcycle(
            name: "The Blue Streak",
            make: "Indian",
            model: "Chieftain Dark Horse",
            year: 2021,
            currentMileage: 12_847,
            vin: "56KMSA009M3000421",
            fuelCapacityGallons: 5.5,
            averageMPG: 42.0,
            remindersEnabled: true
        )
        context.insert(indian)

        let cal = Calendar.current

        let records: [(ServiceType, Date, Int, Double?, String)] = [
            (.oilChange, cal.date(byAdding: .month, value: -14, to: .now)!, 1_200, 89.99, "Indian Motorcycle of Scottsdale"),
            (.service5k, cal.date(byAdding: .month, value: -10, to: .now)!, 5_050, 349.00, "Indian Motorcycle of Scottsdale"),
            (.chainCleanLube, cal.date(byAdding: .month, value: -8, to: .now)!, 6_400, 45.00, "DIY in the garage"),
            (.oilChange, cal.date(byAdding: .month, value: -7, to: .now)!, 7_200, 89.99, "Indian Motorcycle of Scottsdale"),
            (.tireReplacement, cal.date(byAdding: .month, value: -5, to: .now)!, 8_200, 420.00, "Cycle Gear Phoenix"),
            (.brakeInspection, cal.date(byAdding: .month, value: -4, to: .now)!, 9_100, 0.00, "DIY in the garage"),
            (.service10k, cal.date(byAdding: .month, value: -3, to: .now)!, 10_050, 549.00, "Indian Motorcycle of Scottsdale"),
            (.oilChange, cal.date(byAdding: .month, value: -1, to: .now)!, 12_100, 89.99, "Quick Lube Moto - Flagstaff"),
            (.airFilter, cal.date(byAdding: .day, value: -10, to: .now)!, 12_600, 35.00, "DIY in the garage"),
        ]

        for (type, date, mileage, cost, shop) in records {
            let record = MaintenanceRecord(
                serviceType: type,
                date: date,
                mileage: mileage,
                cost: cost,
                shop: shop,
                notes: "",
                isCompleted: true
            )
            record.motorcycle = indian
            context.insert(record)
        }
    }

    // MARK: - Social Posts

    private static func seedPosts(context: ModelContext) {
        let cal = Calendar.current
        let posts: [(UUID, UUID, String, PostType, Date, String?)] = [
            // Kevin's posts
            (post1ID, kevinID, "Route 66 is calling and we are ANSWERING. Seven riders, zero excuses. Let's ride, Brotherhood! 🏍️", .status, cal.date(byAdding: .day, value: -4, to: .now)!, "Los Angeles, CA"),
            (post2ID, kevinID, "Day 2 on Route 66. Found the best brisket west of Texas at a little shack in Seligman. Smokey is jealous. As he should be.", .status, cal.date(byAdding: .day, value: -2, to: .now)!, "Seligman, AZ"),
            (post3ID, kevinID, "Just hit 12,000 miles on the Dark Horse. She's running like a dream through the desert.", .milestone, cal.date(byAdding: .day, value: -1, to: .now)!, nil),

            // Big Mike's posts
            (post4ID, bigMikeID, "Lost my Oakleys doing 80 through the Mojave. If anyone finds a pair of sunglasses rolling through the desert, those are mine.", .status, cal.date(byAdding: .day, value: -2, to: .now)!, "Mojave Desert, CA"),
            (post5ID, bigMikeID, "My Road Glide just hit 30,000 miles. Still the loudest thing on the highway and I wouldn't have it any other way.", .milestone, cal.date(byAdding: .day, value: -10, to: .now)!, nil),

            // Whiskey's posts
            (post6ID, whiskeyID, "Scout Bobber started on the first try today. Nobody is more shocked than me. Maybe she heard me talking about trading her in.", .status, cal.date(byAdding: .day, value: -1, to: .now)!, "Oatman, AZ"),
            (post7ID, whiskeyID, "New handlebars installed. Only dropped one wrench on my foot this time. Progress.", .status, cal.date(byAdding: .day, value: -14, to: .now)!, nil),

            // Turbo's posts
            (post8ID, turboID, "Got clocked at 92 in a 65. Officer said 'nice bike though.' Still got the ticket. Worth it.", .status, cal.date(byAdding: .day, value: -3, to: .now)!, "Barstow, CA"),
            (post9ID, turboID, "Dragon preview ride is coming up. 318 curves. If you're not leaning, you're not trying.", .status, cal.date(byAdding: .day, value: -5, to: .now)!, nil),

            // Red's posts
            (post10ID, redID, "Sunset over the Painted Desert. No filter needed. This is why we ride.", .photo, cal.date(byAdding: .hour, value: -8, to: .now)!, "Winslow, AZ"),
            (post11ID, redID, "Challenger is handling these desert roads like a boss. Best decision I ever made.", .status, cal.date(byAdding: .day, value: -6, to: .now)!, nil),

            // Patches' posts
            (post12ID, patchesID, "Added patch #47 to the vest today. Running out of room. Might need a second vest.", .status, cal.date(byAdding: .day, value: -7, to: .now)!, nil),
            (post13ID, patchesID, "Performed the entire 'Take It Easy' at the Winslow statue. Tourists applauded. The guys pretended not to know me.", .status, cal.date(byAdding: .hour, value: -6, to: .now)!, "Winslow, AZ"),

            // Smokey's posts
            (post14ID, smokeyID, "Pulled out the portable grill at a gas station rest stop. Had brisket sliders ready in 20 minutes. The trucker next to us asked for seconds.", .status, cal.date(byAdding: .day, value: -1, to: .now)!, "Flagstaff, AZ"),
            (post15ID, smokeyID, "Planning a BBQ & Ride for next month. Bring your appetite and your A-game.", .rideShare, cal.date(byAdding: .day, value: -3, to: .now)!, "Phoenix, AZ"),

            // More Kevin posts
            (post16ID, kevinID, "Brotherhood rules: 1) Ride hard. 2) Eat harder. 3) Never leave a rider behind. 4) Turbo pays his own tickets.", .status, cal.date(byAdding: .day, value: -8, to: .now)!, nil),
            (post17ID, kevinID, "Sharing the Route 66 trip with the crew. This is what it's all about.", .rideShare, cal.date(byAdding: .day, value: -4, to: .now)!, nil),
            (post18ID, bigMikeID, "Thinking about adding a second bike to the garage. Road Glide for cruising, Sportster for weekend rips. Someone talk me out of it. Or don't.", .status, cal.date(byAdding: .day, value: -12, to: .now)!, nil),
        ]

        for (id, authorID, content, postType, date, location) in posts {
            let post = Post(
                id: id,
                authorID: authorID,
                content: content,
                locationName: location,
                postType: postType
            )
            post.createdAt = date
            context.insert(post)
        }
    }

    // MARK: - Follows

    private static func seedFollows(context: ModelContext) {
        // Kevin follows everyone
        let kevinFollows: [UUID] = [bigMikeID, whiskeyID, turboID, redID, patchesID, smokeyID]
        for targetID in kevinFollows {
            context.insert(Follow(followerID: kevinID, followingID: targetID))
        }

        // Everyone follows Kevin back
        for memberID in [bigMikeID, whiskeyID, turboID, redID, patchesID, smokeyID] {
            context.insert(Follow(followerID: memberID, followingID: kevinID))
        }

        // Additional follow relationships for a realistic social graph
        let additionalFollows: [(UUID, UUID)] = [
            (bigMikeID, turboID),
            (bigMikeID, smokeyID),
            (turboID, redID),
            (turboID, bigMikeID),
            (redID, turboID),
            (redID, whiskeyID),
            (whiskeyID, bigMikeID),
            (whiskeyID, patchesID),
            (patchesID, smokeyID),
            (patchesID, bigMikeID),
            (smokeyID, bigMikeID),
            (smokeyID, patchesID),
        ]
        for (follower, following) in additionalFollows {
            context.insert(Follow(followerID: follower, followingID: following))
        }
    }

    // MARK: - Likes

    @discardableResult
    private static func seedLikes(context: ModelContext) -> [UUID: Int] {
        let likeSets: [(UUID, [UUID])] = [
            (post1ID, [bigMikeID, turboID, redID, patchesID, smokeyID]),
            (post2ID, [smokeyID, bigMikeID, whiskeyID]),
            (post3ID, [bigMikeID, turboID, redID]),
            (post4ID, [kevinID, turboID, whiskeyID, patchesID]),
            (post5ID, [kevinID, smokeyID]),
            (post6ID, [kevinID, bigMikeID, turboID]),
            (post8ID, [kevinID, redID, whiskeyID]),
            (post9ID, [kevinID, redID]),
            (post10ID, [kevinID, bigMikeID, turboID, whiskeyID, patchesID]),
            (post12ID, [kevinID, bigMikeID, smokeyID]),
            (post13ID, [kevinID, bigMikeID, turboID, redID]),
            (post14ID, [kevinID, bigMikeID, patchesID, redID, turboID]),
            (post15ID, [kevinID, bigMikeID, redID]),
            (post16ID, [bigMikeID, turboID, redID, patchesID, smokeyID, whiskeyID]),
            (post18ID, [kevinID, turboID, smokeyID]),
        ]

        var counts: [UUID: Int] = [:]
        for (postID, likers) in likeSets {
            counts[postID] = likers.count
            for userID in likers {
                context.insert(Like(postID: postID, userID: userID))
            }
        }
        return counts
    }

    // MARK: - Comments

    @discardableResult
    private static func seedComments(context: ModelContext) -> [UUID: Int] {
        let cal = Calendar.current
        let comments: [(UUID, UUID, String, Date)] = [
            (post1ID, bigMikeID, "Let's goooo! Road Glide is fueled up and ready! 💪", cal.date(byAdding: .day, value: -4, to: .now)!),
            (post1ID, turboID, "First one to Amarillo buys dinner", cal.date(byAdding: .day, value: -4, to: .now)!),
            (post1ID, smokeyID, "I'm bringing the portable grill. Non-negotiable.", cal.date(byAdding: .day, value: -4, to: .now)!),
            (post2ID, smokeyID, "Better than MY brisket?? We need to talk, Governor.", cal.date(byAdding: .day, value: -2, to: .now)!),
            (post2ID, bigMikeID, "I had three plates. No regrets.", cal.date(byAdding: .day, value: -2, to: .now)!),
            (post4ID, kevinID, "We told you to get the strap! 😂", cal.date(byAdding: .day, value: -2, to: .now)!),
            (post4ID, turboID, "Saw them fly past me at 85. Beautiful arc.", cal.date(byAdding: .day, value: -2, to: .now)!),
            (post6ID, bigMikeID, "Don't jinx it, Whiskey...", cal.date(byAdding: .day, value: -1, to: .now)!),
            (post6ID, kevinID, "Third time this trip. We're keeping a tally.", cal.date(byAdding: .day, value: -1, to: .now)!),
            (post8ID, kevinID, "Adding this to the Brotherhood Rules. Turbo pays his own tickets.", cal.date(byAdding: .day, value: -3, to: .now)!),
            (post8ID, whiskeyID, "Should've told the cop you were testing the bike 😂", cal.date(byAdding: .day, value: -3, to: .now)!),
            (post10ID, kevinID, "Frame this one, Red. Incredible shot.", cal.date(byAdding: .hour, value: -7, to: .now)!),
            (post10ID, patchesID, "Even Turbo slowed down for this sunset", cal.date(byAdding: .hour, value: -7, to: .now)!),
            (post13ID, turboID, "I'm pretending I don't know you", cal.date(byAdding: .hour, value: -5, to: .now)!),
            (post13ID, bigMikeID, "I HELPED. Give me credit. 🎤", cal.date(byAdding: .hour, value: -5, to: .now)!),
            (post14ID, bigMikeID, "Smokey you absolute legend. Those sliders were perfect.", cal.date(byAdding: .day, value: -1, to: .now)!),
            (post14ID, kevinID, "This is why Smokey rides with us.", cal.date(byAdding: .day, value: -1, to: .now)!),
            (post18ID, kevinID, "Nobody talk him out of it. We need content for the feed.", cal.date(byAdding: .day, value: -12, to: .now)!),
        ]

        var counts: [UUID: Int] = [:]
        for (postID, authorID, content, date) in comments {
            let comment = Comment(postID: postID, authorID: authorID, content: content)
            comment.createdAt = date
            context.insert(comment)
            counts[postID, default: 0] += 1
        }
        return counts
    }

    // MARK: - Conversations

    private static func seedConversations(context: ModelContext) {
        let cal = Calendar.current

        // Kevin ↔ Big Mike: dealership talk
        let conv1 = Conversation(
            participantIDs: [kevinID, bigMikeID],
            lastMessageText: "Let me know when you want to go check it out",
            lastMessageDate: cal.date(byAdding: .hour, value: -2, to: .now)!,
            unreadCount: 1
        )
        context.insert(conv1)
        let conv1Messages: [(UUID, String, Date)] = [
            (bigMikeID, "Yo Governor, you see the new Road Glide Special at the dealership?", cal.date(byAdding: .hour, value: -5, to: .now)!),
            (kevinID, "The blue one? Yeah, it's a beast. Thinking about test riding it.", cal.date(byAdding: .hour, value: -4, to: .now)!),
            (bigMikeID, "I need a riding buddy. Don't let me walk in there alone or I'm buying it.", cal.date(byAdding: .hour, value: -3, to: .now)!),
            (kevinID, "Let me know when you want to go check it out", cal.date(byAdding: .hour, value: -2, to: .now)!),
        ]
        for (senderID, content, date) in conv1Messages {
            let msg = DirectMessage(senderID: senderID, content: content, timestamp: date, isRead: senderID != bigMikeID)
            msg.conversation = conv1
            context.insert(msg)
        }

        // Kevin ↔ Turbo: speeding ticket
        let conv2 = Conversation(
            participantIDs: [kevinID, turboID],
            lastMessageText: "The wind made me do it",
            lastMessageDate: cal.date(byAdding: .hour, value: -8, to: .now)!,
            unreadCount: 0
        )
        context.insert(conv2)
        let conv2Messages: [(UUID, String, Date)] = [
            (kevinID, "Turbo. 47 minutes. That's a new record.", cal.date(byAdding: .hour, value: -10, to: .now)!),
            (turboID, "The speed limit was unreasonable", cal.date(byAdding: .hour, value: -9, to: .now)!),
            (kevinID, "It was 65. You were doing 92.", cal.date(byAdding: .hour, value: -9, to: .now)!),
            (turboID, "The wind made me do it", cal.date(byAdding: .hour, value: -8, to: .now)!),
        ]
        for (senderID, content, date) in conv2Messages {
            let msg = DirectMessage(senderID: senderID, content: content, timestamp: date, isRead: true)
            msg.conversation = conv2
            context.insert(msg)
        }

        // Kevin ↔ Smokey: BBQ planning
        let conv3 = Conversation(
            participantIDs: [kevinID, smokeyID],
            lastMessageText: "I'll bring enough brisket for 20. Just in case.",
            lastMessageDate: cal.date(byAdding: .day, value: -1, to: .now)!,
            unreadCount: 1
        )
        context.insert(conv3)
        let conv3Messages: [(UUID, String, Date)] = [
            (smokeyID, "Governor, I'm planning that BBQ & Ride for next month. You in?", cal.date(byAdding: .day, value: -2, to: .now)!),
            (kevinID, "Always. What's the menu looking like?", cal.date(byAdding: .day, value: -2, to: .now)!),
            (smokeyID, "Brisket, ribs, pulled pork sliders. The holy trinity.", cal.date(byAdding: .day, value: -1, to: .now)!),
            (kevinID, "You had me at brisket. I'll rally the troops.", cal.date(byAdding: .day, value: -1, to: .now)!),
            (smokeyID, "I'll bring enough brisket for 20. Just in case.", cal.date(byAdding: .day, value: -1, to: .now)!),
        ]
        for (senderID, content, date) in conv3Messages {
            let msg = DirectMessage(senderID: senderID, content: content, timestamp: date, isRead: senderID != smokeyID)
            msg.conversation = conv3
            context.insert(msg)
        }

        // Kevin ↔ Whiskey: about the Scout
        let conv4 = Conversation(
            participantIDs: [kevinID, whiskeyID],
            lastMessageText: "She runs on spite and good vibes. Can't explain it.",
            lastMessageDate: cal.date(byAdding: .hour, value: -14, to: .now)!,
            unreadCount: 0
        )
        context.insert(conv4)
        let conv4Messages: [(UUID, String, Date)] = [
            (kevinID, "Whiskey, real talk. Do you need a new starter on that Scout?", cal.date(byAdding: .hour, value: -16, to: .now)!),
            (whiskeyID, "She started today! First try!", cal.date(byAdding: .hour, value: -15, to: .now)!),
            (kevinID, "That's what you said yesterday before we all stood around for 20 minutes.", cal.date(byAdding: .hour, value: -14, to: .now)!),
            (whiskeyID, "She runs on spite and good vibes. Can't explain it.", cal.date(byAdding: .hour, value: -14, to: .now)!),
        ]
        for (senderID, content, date) in conv4Messages {
            let msg = DirectMessage(senderID: senderID, content: content, timestamp: date, isRead: true)
            msg.conversation = conv4
            context.insert(msg)
        }
    }

    // MARK: - Ride Events

    private static func seedRideEvents(context: ModelContext) {
        let cal = Calendar.current

        // Upcoming: Saturday Morning Blast
        let saturdayBlast = RideEvent(
            title: "Saturday Morning Blast",
            eventDescription: "Quick 60-mile loop through the canyon roads. Meet at the gas station on Main, kick stands up at 8 AM sharp. Turbo, try not to get pulled over before we leave town.",
            organizerID: kevinID,
            startDate: cal.date(byAdding: .day, value: 5, to: .now)!,
            meetupLocationName: "Shell Station, Main St",
            meetupLatitude: 33.4484,
            meetupLongitude: -112.0740,
            estimatedDistanceMiles: 60,
            difficulty: .moderate,
            rsvpIDs: [kevinID, bigMikeID, turboID, redID]
        )
        context.insert(saturdayBlast)

        // Upcoming: Dragon Preview
        let dragonPreview = RideEvent(
            title: "Dragon Preview Ride",
            eventDescription: "Scouting the route before the full trip. 318 curves in 11 miles — let's see who can keep up. Bring your A-game and your knee pucks.",
            organizerID: turboID,
            startDate: cal.date(byAdding: .day, value: 14, to: .now)!,
            meetupLocationName: "Deals Gap Motorcycle Resort",
            meetupLatitude: 35.4590,
            meetupLongitude: -83.9190,
            estimatedDistanceMiles: 120,
            difficulty: .expert,
            rsvpIDs: [turboID, kevinID, redID]
        )
        context.insert(dragonPreview)

        // Upcoming: Smokey's BBQ & Ride
        let bbqRide = RideEvent(
            title: "Smokey's BBQ & Ride",
            eventDescription: "50-mile scenic ride through the desert, ending at Smokey's place for the best brisket you'll ever have. Bring your appetite. Seriously.",
            organizerID: smokeyID,
            startDate: cal.date(byAdding: .day, value: 21, to: .now)!,
            meetupLocationName: "Desert Ridge Parking Lot",
            meetupLatitude: 33.6803,
            meetupLongitude: -111.9261,
            estimatedDistanceMiles: 50,
            difficulty: .easy,
            rsvpIDs: [smokeyID, kevinID, bigMikeID, patchesID, whiskeyID]
        )
        context.insert(bbqRide)
    }

    // MARK: - Activity Items

    private static func seedActivityItems(context: ModelContext) {
        let cal = Calendar.current
        let items: [(UUID, ActivityType, UUID?, String, Bool, Date)] = [
            (bigMikeID, .like, post3ID, "Big Mike liked your milestone post", false, cal.date(byAdding: .hour, value: -1, to: .now)!),
            (turboID, .comment, post2ID, "Turbo commented on your post", false, cal.date(byAdding: .hour, value: -3, to: .now)!),
            (redID, .follow, nil, "Red Richardson started following you", false, cal.date(byAdding: .hour, value: -5, to: .now)!),
            (smokeyID, .like, post1ID, "Smokey liked your Route 66 post", true, cal.date(byAdding: .hour, value: -8, to: .now)!),
            (patchesID, .follow, nil, "Patches Patterson started following you", true, cal.date(byAdding: .hour, value: -12, to: .now)!),
            (whiskeyID, .comment, post1ID, "Whiskey commented: 'Scout is ready!'", true, cal.date(byAdding: .day, value: -1, to: .now)!),
            (bigMikeID, .rsvp, nil, "Big Mike RSVP'd to Saturday Morning Blast", true, cal.date(byAdding: .day, value: -1, to: .now)!),
            (turboID, .rsvp, nil, "Turbo RSVP'd to Saturday Morning Blast", true, cal.date(byAdding: .day, value: -1, to: .now)!),
            (smokeyID, .comment, post16ID, "Smokey commented on Brotherhood Rules", true, cal.date(byAdding: .day, value: -2, to: .now)!),
            (redID, .like, post1ID, "Red liked your Route 66 post", true, cal.date(byAdding: .day, value: -3, to: .now)!),
            (patchesID, .like, post16ID, "Patches liked Brotherhood Rules", true, cal.date(byAdding: .day, value: -4, to: .now)!),
            (bigMikeID, .follow, nil, "Big Mike started following you", true, cal.date(byAdding: .day, value: -7, to: .now)!),
        ]

        for (actorID, activityType, referenceID, message, isRead, date) in items {
            let item = ActivityItem(
                actorID: actorID,
                targetUserID: kevinID,
                activityType: activityType,
                referenceID: referenceID,
                message: message,
                isRead: isRead
            )
            item.createdAt = date
            context.insert(item)
        }
    }

    // MARK: - Trip Invites

    private static func seedTripInvites(context: ModelContext) {
        let cal = Calendar.current

        // Pending invites TO Kevin (from other riders inviting him to Dragon trip)
        let invite1 = TripInvite(
            id: UUID(uuidString: "20000001-0000-0000-0000-000000000001")!,
            tripID: dragonTripID,
            senderID: turboID,
            recipientID: kevinID,
            status: .pending
        )
        invite1.createdAt = cal.date(byAdding: .hour, value: -4, to: .now) ?? .now
        context.insert(invite1)

        // Smokey invites Kevin to a potential BBQ ride
        let invite2 = TripInvite(
            id: UUID(uuidString: "20000002-0000-0000-0000-000000000002")!,
            tripID: route66TripID,
            senderID: smokeyID,
            recipientID: kevinID,
            status: .pending
        )
        invite2.createdAt = cal.date(byAdding: .hour, value: -6, to: .now) ?? .now
        context.insert(invite2)

        // Accepted invites (Kevin accepted Big Mike's invite to Route 66)
        let invite3 = TripInvite(
            id: UUID(uuidString: "20000003-0000-0000-0000-000000000003")!,
            tripID: route66TripID,
            senderID: kevinID,
            recipientID: bigMikeID,
            status: .accepted
        )
        invite3.createdAt = cal.date(byAdding: .day, value: -5, to: .now) ?? .now
        context.insert(invite3)

        // Kevin invited Patches to Dragon — still pending
        let invite4 = TripInvite(
            id: UUID(uuidString: "20000004-0000-0000-0000-000000000004")!,
            tripID: dragonTripID,
            senderID: kevinID,
            recipientID: patchesID,
            status: .pending
        )
        invite4.createdAt = cal.date(byAdding: .day, value: -1, to: .now) ?? .now
        context.insert(invite4)

        // Add trip invite activity items for Kevin's pending invites
        let inviteActivity1 = ActivityItem(
            actorID: turboID,
            targetUserID: kevinID,
            activityType: .tripInvite,
            referenceID: dragonTripID,
            message: "Turbo invited you to Tail of the Dragon Weekend",
            isRead: false
        )
        inviteActivity1.createdAt = cal.date(byAdding: .hour, value: -4, to: .now) ?? .now
        context.insert(inviteActivity1)

        let inviteActivity2 = ActivityItem(
            actorID: smokeyID,
            targetUserID: kevinID,
            activityType: .tripInvite,
            referenceID: route66TripID,
            message: "Smokey invited you to Route 66 or Bust",
            isRead: false
        )
        inviteActivity2.createdAt = cal.date(byAdding: .hour, value: -6, to: .now) ?? .now
        context.insert(inviteActivity2)
    }
}
