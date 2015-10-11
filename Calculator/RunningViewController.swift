//
//  MainViewController.swift
//  RunningMusic
//
//  Created by Cal on 10/10/15.
//  Copyright © 2015 Cal. All rights reserved.
//

import Foundation
import UIKit
import CoreMotion
import MediaPlayer

var RMCurrentActivityState = ActivityState.Running
enum ActivityState {
    case Walking, Running
    
    var playlist: Playlist {
        if self == .Walking { return Playlist.Walking }
        return Playlist.Running
    }
    
    var color: UIColor {
        if self == .Walking { return UIColor(red: 63/256, green: 81/256, blue: 181/256, alpha: 0.5) }
        else { return UIColor(red: 244/256, green: 67/256, blue: 54/256, alpha: 0.5) }
    }
    
    var image: UIImage {
        let name = self == .Walking ? "walk" : "run"
        return UIImage(named: "icon-\(name)")!
    }
}

class RunningViewController : UIViewController {
    
    var motion: CMMotionActivityManager = CMMotionActivityManager()
    
    @IBOutlet weak var itemAlbumArt: UIImageView!
    @IBOutlet weak var itemNameLabel: UILabel!
    @IBOutlet weak var itemArtistLabel: UILabel!
    @IBOutlet weak var activityImage: UIImageView!
    @IBOutlet weak var backgroundView: UIView!
    
    var songsInPlaylist = [MPMediaItem]()
    
    override func viewDidLoad() {
        startAccelerometerPolling()
    }
    
    override func viewWillAppear(animated: Bool) {
        self.view.layoutIfNeeded()
        self.transitionToActivityState(.Running)
    }
    
    func startAccelerometerPolling() {
        
        motion.startActivityUpdatesToQueue(NSOperationQueue(), withHandler: { activity in
            guard let activity = activity else { return }
            self.updateForMotionActivity(activity)
        })
        
        
    }
    
    func updateForMotionActivity(activity: CMMotionActivity) {
        
        var activityState: ActivityState = .Walking
        
        if activity.running { activityState = .Running }
        else { activityState = .Walking }
        
        if RMCurrentActivityState != activityState {
            sync{ self.transitionToActivityState(activityState) }
        }
    }
    
    func transitionToActivityState(activityState: ActivityState) {
        RMCurrentActivityState = activityState
        print(activityState)
        let playlist = activityState.playlist
        self.songsInPlaylist = playlist.songs.shuffled()
        self.backgroundView.backgroundColor = activityState.color
        self.activityImage.image = activityState.image
        
        if let song = songsInPlaylist.first {
            
            if let nowPlaying = RMPlayer.nowPlayingItem {
                if !songsInPlaylist.contains(RMPlayer.nowPlayingItem!) {
                    SongCell.decorateForSong(song, inNameLabel: itemNameLabel, artistLabel: itemArtistLabel, albumArt: itemAlbumArt)
                    RMPlayer.nowPlayingItem = song
                }
                else {
                    SongCell.decorateForSong(nowPlaying, inNameLabel: itemNameLabel, artistLabel: itemArtistLabel, albumArt: itemAlbumArt)
                    RMPlayer.nowPlayingItem = song
                }
            }
            else {
                SongCell.decorateForSong(song, inNameLabel: itemNameLabel, artistLabel: itemArtistLabel, albumArt: itemAlbumArt)
                RMPlayer.nowPlayingItem = song
            }
            
            RMPlayer.play()
        }
        
    }
    
    
}