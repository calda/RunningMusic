//
//  MusicViewController.swift
//  RunningMusic
//
//  Created by Cal on 10/10/15.
//  Copyright © 2015 Cal. All rights reserved.
//

import Foundation
import UIKit
import MediaPlayer

class MusicViewController : UIViewController {
    
    var unassignedSongs: [MPMediaItem] = []
    
    var currentItem: MPMediaItem?
    var player: MPMusicPlayerController = MPMusicPlayerController.systemMusicPlayer()
    var playhead: UIView?
    
    @IBOutlet weak var currentItemView: UIView!
    @IBOutlet weak var itemAlbumArt: UIImageView!
    @IBOutlet weak var itemNameLabel: UILabel!
    @IBOutlet weak var itemArtistLabel: UILabel!
    
    override func viewDidLoad() {
        unassignedSongs = getAllUnassignedSongs()
    }
    
    override func viewWillAppear(animated: Bool) {
        self.view.layoutIfNeeded()
        updateForNextUnassignedItem()
    }
    
    //MARK - Updating UI
    
    func updateForNextUnassignedItem() {
        currentItem = unassignedSongs.first
        guard let item = currentItem else { noSongsRemaining(); return }
        
        let name = item.valueForProperty(MPMediaItemPropertyTitle) as? NSString ?? "Untitled Song"
        itemNameLabel.text = name as String
        
        let artist = item.valueForProperty(MPMediaItemPropertyArtist) as? NSString ?? ""
        itemArtistLabel.text = artist as String
        
        let artwork = item.valueForProperty(MPMediaItemPropertyArtwork) as? MPMediaItemArtwork
        let artScale = UIScreen.mainScreen().scale * 1.2
        let artSize = CGSizeMake(itemAlbumArt.frame.width * artScale, itemAlbumArt.frame.height * artScale)
        //TODO: add art-default as image asset
        let albumArt = artwork?.imageWithSize(artSize) ?? UIImage(named: "art-default")!
        itemAlbumArt.image = albumArt
        
        player.nowPlayingItem = item
        player.play()
    }
    
    func noSongsRemaining() {
        
    }
    
    //MARK: - User Interaction
    
    @IBAction func assignmentButtonPressed(sender: UIButton) {
        guard let currentItem = currentItem else { return }
        let playlistName = sender.restorationIdentifier ?? ""
        guard let playlist = Playlist.forString(playlistName) else { return }
        playlist.addSong(currentItem)
        if let index = unassignedSongs.indexOf(currentItem) {
            unassignedSongs.removeAtIndex(index)
        }
        
        
        updateForNextUnassignedItem()
    }
    
    
    //MARK: - Managing MPMediaItems
    
    func getAllUnassignedSongs() -> [MPMediaItem] {
        let query = MPMediaQuery.songsQuery().items ?? []
        
        var unassigned: [MPMediaItem] = []
        for item in query {
            if Playlist.forSong(item) == nil {
                unassigned.append(item)
            }
        }
        
        return unassigned.shuffled()
    }
    
    func getSongForID(id: UInt64) -> MPMediaItem? {
        let query = MPMediaQuery.songsQuery().items ?? []
        for item in query {
            if item.persistentID == id { return item }
        }
        return nil
    }
    
}