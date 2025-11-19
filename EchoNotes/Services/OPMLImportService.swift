//
//  OPMLImportService.swift
//  EchoNotes
//
//  OPML (Outline Processor Markup Language) parser for podcast subscriptions
//

import Foundation

// MARK: - OPML Models

struct OPMLFeed {
    let title: String
    let feedURL: String
    let description: String?
}

// MARK: - OPML Import Service

class OPMLImportService: NSObject, XMLParserDelegate {
    private var feeds: [OPMLFeed] = []
    private var currentElement = ""
    private var currentTitle = ""
    private var currentFeedURL = ""
    private var currentDescription = ""

    func parsePOML(from fileURL: URL) async throws -> [OPMLFeed] {
        feeds = []

        guard let parser = XMLParser(contentsOf: fileURL) else {
            throw OPMLError.invalidFile
        }

        parser.delegate = self

        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let success = parser.parse()
                if success {
                    continuation.resume(returning: self.feeds)
                } else {
                    continuation.resume(returning: [])
                }
            }
        }
    }

    func parseOPML(from data: Data) async throws -> [OPMLFeed] {
        feeds = []

        let parser = XMLParser(data: data)
        parser.delegate = self

        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let success = parser.parse()
                if success {
                    continuation.resume(returning: self.feeds)
                } else {
                    continuation.resume(returning: [])
                }
            }
        }
    }

    // MARK: - XMLParserDelegate

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName

        if elementName == "outline" {
            // Check if this is a podcast feed (has xmlUrl attribute)
            if let xmlUrl = attributeDict["xmlUrl"], !xmlUrl.isEmpty {
                currentFeedURL = xmlUrl
                currentTitle = attributeDict["title"] ?? attributeDict["text"] ?? "Unknown Podcast"
                currentDescription = attributeDict["description"] ?? ""

                // Add to feeds array
                let feed = OPMLFeed(
                    title: currentTitle,
                    feedURL: currentFeedURL,
                    description: currentDescription.isEmpty ? nil : currentDescription
                )
                feeds.append(feed)
            }
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        // Not needed for OPML parsing as all data is in attributes
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        // Reset current values
        if elementName == "outline" {
            currentFeedURL = ""
            currentTitle = ""
            currentDescription = ""
        }
    }
}

// MARK: - OPML Error

enum OPMLError: LocalizedError {
    case invalidFile
    case parsingFailed
    case noFeedsFound

    var errorDescription: String? {
        switch self {
        case .invalidFile:
            return "Invalid OPML file"
        case .parsingFailed:
            return "Failed to parse OPML file"
        case .noFeedsFound:
            return "No podcast feeds found in OPML file"
        }
    }
}
