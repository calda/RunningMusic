//
//  PlaylistData.swift
//  RunningMusic
//
//  Created by Cal on 10/10/15.
//  Copyright © 2015 Cal. All rights reserved.
//

import Foundation
import MediaPlayer

enum Playlist : StringLiteralType {
    case Running, Walking, Both, Neither
    
    var dataKey: String {
        return "playlist-\(self)".lowercaseString
    }
    
    var songs: [MPMediaItem] {
        let data = NSUserDefaults.standardUserDefaults()
        guard let itemsInPlaylist = data.stringArrayForKey(dataKey) else { return [] }
        if itemsInPlaylist.count == 0 { return [] }
        
        let query = MPMediaQuery.songsQuery().items ?? []
        var songsInPlaylist: [MPMediaItem] = []
        
        for item in query {
            let id = "\(item.persistentID)"
            if itemsInPlaylist.contains(id) {
                songsInPlaylist.append(item)
            }
        }
        
        return songsInPlaylist
    }
    
    func addSong(song: MPMediaItem) {
        if self == .Both {
            Playlist.Running.addSong(song)
            Playlist.Walking.addSong(song)
        }
        
        let data = NSUserDefaults.standardUserDefaults()
        var playlistArray = data.stringArrayForKey(dataKey) ?? []
        let id = "\(song.persistentID)"
        playlistArray.append(id)
        data.setValue(playlistArray, forKey: dataKey)
        data.setValue("\(self)", forKey: id)
    }
    
    func removeSong(song: MPMediaItem) {
        removeID("\(song.persistentID)")
    }
    
    func removeID(id: String) {
        let data = NSUserDefaults.standardUserDefaults()
        var playlistArray = data.stringArrayForKey(dataKey) ?? []
        guard let index = playlistArray.indexOf(id) else { return }
        playlistArray.removeAtIndex(index)
        data.setValue(playlistArray, forKey: dataKey)
        data.setValue(nil, forKey: id)
    }
    
    static func forSong(song: MPMediaItem) -> Playlist? {
        let id = "\(song.persistentID)"
        let data = NSUserDefaults.standardUserDefaults()
        guard let playlistName = data.valueForKey(id) as? String else { return nil }
        return Playlist.forString(playlistName)
    }
    
    static func forString(string: String) -> Playlist? {
        switch(string.lowercaseString) {
            case "running": return .Running
            case "walking": return .Walking
            case "both": return .Both
            case "neither": return .Neither
            default: return nil
        }
    }
    
    var description: String {
        return "\(self)"
    }
    
}

extension MPMediaItem {
    
    override public var description: String {
        return self.title ?? "Unnamed song"
    }
    
}