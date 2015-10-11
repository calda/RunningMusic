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
    @IBOutlet weak var playButton: UIImageView!
    var playhead: UIView?
    
    @IBOutlet weak var currentItemView: UIView!
    var itemRestingPosition: CGPoint!
    @IBOutlet weak var itemAlbumArt: UIImageView!
    @IBOutlet weak var itemNameLabel: UILabel!
    @IBOutlet weak var itemArtistLabel: UILabel!
    
    @IBOutlet var playlistButtons: [UIButton]!
    
    override func viewDidLoad() {
        unassignedSongs = getAllUnassignedSongs()
    }
    
    override func viewWillAppear(animated: Bool) {
        self.view.layoutIfNeeded()
        self.itemRestingPosition = currentItemView.frame.origin
        
        startPlayheadTimers()
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
        let artScale = UIScreen.mainScreen().scale
        let artSize = CGSizeMake(itemAlbumArt.frame.width * artScale, itemAlbumArt.frame.height * artScale)
        //TODO: add art-default as image asset
        let albumArt = artwork?.imageWithSize(artSize) ?? UIImage(named: "art-default")!
        itemAlbumArt.image = albumArt
        
        //set as player item
        player.nowPlayingItem = item
        if playButton.image == UIImage(named: "button-pause") {
            player.play()
        }
        
        //create playhead
        if let oldPlayhead = playhead {
            oldPlayhead.removeFromSuperview()
        }
        
        let height = itemAlbumArt.frame.height * 0.075
        let frame = CGRect(origin: CGPointZero, size: CGSizeMake(3.0, height))
        playhead = UIView(frame: frame)
        guard let playhead = playhead else { return }
        playhead.backgroundColor = UIColor(hue: 0.0, saturation: 0.6, brightness: 1.0, alpha: 1.0)
        itemAlbumArt.addSubview(playhead)
    }
    
    func noSongsRemaining() {
        
    }
    
    func startPlayheadTimers() {
        
        //add play bar to top of album art view
        itemAlbumArt.clipsToBounds = false
        currentItemView.clipsToBounds = false
        let frame = CGRect(origin: CGPointMake(0.0, -4.0), size: CGSizeMake(itemAlbumArt.frame.width, 4.0))
        let playBar = UIView(frame: frame)
        playBar.backgroundColor = UIColor(hue: 0.0, saturation: 0.6, brightness: 1.0, alpha: 1.0)
        itemAlbumArt.addSubview(playBar)
        
        NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "updatePlayhead", userInfo: nil, repeats: true)
    }
    
    func updatePlayhead() {
        //do nothing if the playhead is being dragged
        if currentPanHandlerType == .Playhead { return }

        guard let playhead = playhead else { return }
        let currentTime = player.currentPlaybackTime
        let durationNumber = currentItem?.valueForProperty(MPMediaItemPropertyPlaybackDuration) as? NSNumber
        guard let duration = durationNumber?.doubleValue else { return }
        let percentage = currentTime / duration
        
        let availableWidth = itemAlbumArt.frame.width - playhead.frame.width
        var x = availableWidth * CGFloat(percentage)
        x = min(x, itemAlbumArt.frame.width)
        
        let difference = abs(playhead.frame.origin.x - x)
        if difference > 5.0 && difference < 30.0 {
            UIView.animateWithDuration(0.4, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: [], animations: {
                playhead.frame.origin = CGPointMake(x, 0.0)
            }, completion: nil)
        }
        else if difference < 5.0 {
            playhead.frame.origin = CGPointMake(x, 0.0)
        }
    }
    
    //MARK: - User Interaction
    
    var currentPanHandler: ((UIPanGestureRecognizer) -> ())?
    var currentPanHandlerType: PanHandlerType?
    enum PanHandlerType {
        case Playhead, Tinder
    }
    
    @IBAction func screenPanned(sender: UIPanGestureRecognizer) {
        
        //use the existing handler if one exists
        if let currentPanHandler = currentPanHandler {
            currentPanHandler(sender)
            if sender.state == .Ended {
                self.currentPanHandler = nil
                self.currentPanHandlerType = nil
            }
            return
        }
        
        //only start a new pan handler on Began
        if sender.state != .Began { return }
        
        let touch = sender.locationInView(self.view)
        let itemOrigin = currentItemView.frame.origin
        let itemSize = currentItemView.frame.size
        
        //detect playhead dragging
        let playheadRect = CGRect(x: itemOrigin.x - 20.0, y: itemOrigin.y - 10.0, width: itemSize.width + 20.0, height: itemSize.height * 0.15)
        if CGRectContainsPoint(playheadRect, touch) {
            currentPanHandler = playheadPanHandler
            currentPanHandlerType = .Playhead
            playheadPanHandler(sender)
            return
        }
        
        //detect tinder dragging
        let itemRect = currentItemView.frame
        if CGRectContainsPoint(itemRect, touch) {
            currentPanHandler = itemDragPanHandler
            currentPanHandlerType = .Tinder
            itemDragPanHandler(sender)
            return
        }
    }
    
    var currentExpectedPlaybackTime: Double = 0.0
    
    func playheadPanHandler(sender: UIPanGestureRecognizer) {
        guard let playhead = playhead else { return }
        
        //update playhead position
        let location = sender.locationInView(itemAlbumArt)
        let availableWidth = itemAlbumArt.frame.width - playhead.frame.width
        let positionOnBar = min(max(location.x, 0), availableWidth)
        playhead.frame.origin = CGPointMake(positionOnBar, 0.0)
        
        //update playback time
        let percentage = Double(positionOnBar / itemAlbumArt.frame.width)
        let durationNumber = currentItem?.valueForProperty(MPMediaItemPropertyPlaybackDuration) as? NSNumber
        guard let duration = durationNumber?.doubleValue else { return }
        let newTime = duration * percentage
        
        //do nothing if the new time is within 5 seconds of the current time
        if newTime - 5 < currentExpectedPlaybackTime && newTime + 5 > currentExpectedPlaybackTime {
            return
        }
        
        currentExpectedPlaybackTime = newTime
        player.currentPlaybackTime = newTime
    }
    
    var dragTouchOffset: CGPoint?
    
    func itemDragPanHandler(sender: UIPanGestureRecognizer) {
        if sender.state == .Ended {
            processFinishedItemDrag(sender)
            dragTouchOffset = nil
            return
        }
        
        let touch = sender.locationInView(self.view)
        if dragTouchOffset == nil {
            dragTouchOffset = CGPointMake(touch.x - itemRestingPosition.x, touch.y - itemRestingPosition.y)
        }
        guard let dragTouchOffset = dragTouchOffset else { return }
        let dragPosition = CGPointMake(touch.x - dragTouchOffset.x, touch.y - dragTouchOffset.y)
        currentItemView.frame.origin = dragPosition
        
        //animate button scaling
        let itemCenter = CGPointMake(CGRectGetMidX(currentItemView.frame), CGRectGetMidY(currentItemView.frame))
        var closestButton: UIButton! = nil
        var closestDistance = CGFloat.max
        
        for button in playlistButtons {
            let buttonCenter = CGPointMake(CGRectGetMidX(button.frame), CGRectGetMidY(button.frame))
            let distance = itemCenter.distanceTo(buttonCenter)
            if distance < closestDistance {
                closestButton = button
                closestDistance = distance
            }
        }
        
        let itemRestingCenter = CGPointMake(itemRestingPosition.x + (currentItemView.frame.width / 2), itemRestingPosition.y + (currentItemView.frame.height / 2))
        let buttonCenter = CGPointMake(CGRectGetMidX(closestButton.frame), CGRectGetMidY(closestButton.frame))
        
        let restingDistance = itemRestingCenter.distanceTo(buttonCenter)
        let percentage = closestDistance / restingDistance
        animatePlaylistButton(closestButton, atDistancePercentage: percentage)
    }
    
    func processFinishedItemDrag(sender: UIPanGestureRecognizer) {
        let velocityVector = sender.velocityInView(self.view)
        let velocity = -pow((pow(velocityVector.x, 2) + pow(velocityVector.y, 2)), 0.2)
        
        UIView.animateWithDuration(0.6, delay: 0.0, usingSpringWithDamping: 0.75, initialSpringVelocity: velocity, options: [.AllowUserInteraction] , animations: {
                self.currentItemView.frame.origin = self.itemRestingPosition
        }, completion: nil)
        
        animatePlaylistButton(nil, atDistancePercentage: 1.0)
    }
    
    func animatePlaylistButton(button: UIButton?, atDistancePercentage percent: CGFloat) {
        
        let buttonScale = 2.5 - (pow(percent, 5) * 1.5)
        let itemScale = pow(2, 0.5 * percent) - 0.5
        
        UIView.animateWithDuration(0.4, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: [], animations: {
            
            button?.transform = CGAffineTransformMakeScale(buttonScale, buttonScale)
            
            for other in self.playlistButtons {
                if other == button { continue }
                other.transform = CGAffineTransformMakeScale(1.0, 1.0)
            }
            
            self.currentItemView.alpha = itemScale
            
        }, completion: nil)
    }
    
    @IBAction func assignmentButtonPressed(sender: UIButton) {
        let playlistName = sender.restorationIdentifier ?? ""
        guard let playlist = Playlist.forString(playlistName) else { return }
        processAssignmentToPlaylist(playlist)
    }
    
    func processAssignmentToPlaylist(playlist: Playlist) {
        guard let currentItem = currentItem else { return }
        playlist.addSong(currentItem)
        if let index = unassignedSongs.indexOf(currentItem) {
            unassignedSongs.removeAtIndex(index)
        }
        
        updateForNextUnassignedItem()
    }
    
    @IBAction func togglePlayback(sender: UITapGestureRecognizer) {
        if player.playbackState == .Playing {
            player.pause()
            playButton.image = UIImage(named: "button-play")
        }
        else if player.playbackState == .Paused {
            player.play()
            playButton.image = UIImage(named: "button-pause")
        }
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