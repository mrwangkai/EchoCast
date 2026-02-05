//
//  PodcastGenre.swift
//  EchoNotes
//
//  Podcast genre definitions with icons
//

import Foundation

enum PodcastGenre: String, Identifiable, CaseIterable {
    case all = "0"
    case comedy = "1303"
    case news = "1489"
    case trueCrime = "1488"
    case sports = "1545"
    case business = "1321"
    case education = "1304"
    case arts = "1301"
    case health = "1512"
    case tvFilm = "1309"
    case music = "1310"
    case technology = "1318"
    case science = "1478"
    case society = "1485"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all: return "All"
        case .comedy: return "Comedy"
        case .news: return "News"
        case .trueCrime: return "True Crime"
        case .sports: return "Sports"
        case .business: return "Business"
        case .education: return "Education"
        case .arts: return "Arts"
        case .health: return "Health"
        case .tvFilm: return "TV & Film"
        case .music: return "Music"
        case .technology: return "Technology"
        case .science: return "Science"
        case .society: return "Society"
        }
    }

    var iconName: String {
        switch self {
        case .all: return "star.fill"
        case .comedy: return "face.smiling"
        case .news: return "newspaper.fill"
        case .trueCrime: return "magnifyingglass"
        case .sports: return "sportscourt.fill"
        case .business: return "briefcase.fill"
        case .education: return "graduationcap.fill"
        case .arts: return "paintpalette.fill"
        case .health: return "heart.fill"
        case .tvFilm: return "tv.fill"
        case .music: return "music.note"
        case .technology: return "desktopcomputer"
        case .science: return "lightbulb.fill"
        case .society: return "person.3.fill"
        }
    }

    static var mainGenres: [PodcastGenre] {
        [.all, .comedy, .news, .trueCrime, .sports, .business, .education, .technology]
    }
}
