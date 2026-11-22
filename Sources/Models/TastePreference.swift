import Foundation

public struct TastePreference: Identifiable, Hashable {
    public let id: String
    public let label: String
    public let badge: String
    public let personalizedTitle: String
    public let rowIds: [String]
    
    public static let all: [TastePreference] = [
        TastePreference(
            id: "anime",
            label: "Anime & Manga Hits",
            badge: "⚔️ Anime",
            personalizedTitle: "Because you love Anime: ⚔️ Trending Anime Hits",
            rowIds: ["anime-hits", "anime-cartoons"]
        ),
        TastePreference(
            id: "action",
            label: "Action & Blockbusters",
            badge: "🍿 Action",
            personalizedTitle: "Because you love Action: 🍿 Blockbuster Explosive Thrillers",
            rowIds: ["action-thrillers", "top-1080p"]
        ),
        TastePreference(
            id: "tv-series",
            label: "Binge-Worthy TV Series",
            badge: "📺 TV Series",
            personalizedTitle: "Because you love TV Series: 📺 Binge-Worthy TV & Web Series",
            rowIds: ["tv-series", "top-10-tv"]
        ),
        TastePreference(
            id: "korean",
            label: "K-Drama Sensations",
            badge: "💖 K-Drama",
            personalizedTitle: "Because you love K-Drama: 💖 Hot K-Drama Sensations",
            rowIds: ["korean-tv"]
        ),
        TastePreference(
            id: "sci-fi",
            label: "Sci-Fi & Cyberpunk",
            badge: "🚀 Sci-Fi",
            personalizedTitle: "Because you love Sci-Fi: 🚀 Mind-Bending Sci-Fi & Cyberpunk",
            rowIds: ["sci-fi"]
        ),
        TastePreference(
            id: "horror-thriller",
            label: "Supernatural Horror",
            badge: "🩸 Horror",
            personalizedTitle: "Because you love Horror: 🩸 Supernatural Horror & Chilling Mysteries",
            rowIds: ["horror-thriller"]
        ),
        TastePreference(
            id: "crime-mystery",
            label: "Crime, Mafia & Heists",
            badge: "🔪 Crime & Heist",
            personalizedTitle: "Because you love Crime: 🔪 Dark Heists & Psychological Thrillers",
            rowIds: ["crime-mystery"]
        ),
        TastePreference(
            id: "romance-drama",
            label: "Romance & Heartfelt Drama",
            badge: "✨ Romance",
            personalizedTitle: "Because you love Romance: ✨ Romantic Comedies & Heartfelt Dramas",
            rowIds: ["romance-drama"]
        ),
        TastePreference(
            id: "fantasy-adventure",
            label: "High Fantasy & Epics",
            badge: "🐉 Fantasy",
            personalizedTitle: "Because you love Fantasy: 🐉 High Fantasy & Mythological Epics",
            rowIds: ["fantasy-adventure"]
        ),
        TastePreference(
            id: "comedy",
            label: "Comedy & Feel-Good",
            badge: "😂 Comedy",
            personalizedTitle: "Because you love Comedy: 😂 Feel-Good Comedies & Specials",
            rowIds: ["comedy"]
        ),
        TastePreference(
            id: "hollywood-1080p",
            label: "Hollywood 1080p Cinema",
            badge: "🎬 1080p Full HD",
            personalizedTitle: "Because you love Hollywood: 🌟 Top 1080p Full HD Blockbusters",
            rowIds: ["top-1080p", "latest-2026"]
        ),
        TastePreference(
            id: "hindi",
            label: "Bollywood & Hindi Cinema",
            badge: "🇮🇳 Bollywood",
            personalizedTitle: "Because you love Bollywood: 🇮🇳 Latest Bollywood & Hindi Cinema",
            rowIds: ["hindi-cinema"]
        ),
        TastePreference(
            id: "south-indian",
            label: "South Indian Mass Action",
            badge: "💥 Mass Action",
            personalizedTitle: "Because you love Mass Action: 💥 South Indian Mass Action & Entertainers",
            rowIds: ["south-indian"]
        ),
        TastePreference(
            id: "kolkata-bangla",
            label: "Kolkata Bangla Cinema",
            badge: "🎭 Kolkata Bangla",
            personalizedTitle: "Because you love Bangla Cinema: 🎭 Kolkata Bangla Cinema & Classics",
            rowIds: ["kolkata-bangla"]
        ),
        TastePreference(
            id: "imdb-classics",
            label: "IMDb Top Rated Classics",
            badge: "⭐ IMDb 8.5+",
            personalizedTitle: "Because you love Classics: ⭐ Critically Acclaimed IMDb Top-250",
            rowIds: ["imdb-top-250"]
        ),
        TastePreference(
            id: "animation",
            label: "Animated Family & Pixar",
            badge: "🎨 Animation",
            personalizedTitle: "Because you love Animation: 🎨 Animated Family Hits",
            rowIds: ["animation"]
        ),
        TastePreference(
            id: "documentary",
            label: "Documentaries & True Crime",
            badge: "🌍 Docu",
            personalizedTitle: "Because you love Documentaries: 🌍 Eye-Opening Documentaries",
            rowIds: ["documentaries"]
        ),
        TastePreference(
            id: "movies-3d",
            label: "3D & IMAX Experiences",
            badge: "👓 3D / IMAX",
            personalizedTitle: "Because you love 3D & IMAX: 👓 3D & IMAX High-Definition Experiences",
            rowIds: ["movies-3d"]
        )
    ]
}
