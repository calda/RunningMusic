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

let RMPlayer = MPMusicPlayerController.systemMusicPlayer()

class MusicViewController : UIViewController, UICollectionViewDataSource {
    
    var unassignedSongs: [MPMediaItem] = []
    var currentItem: MPMediaItem?
    
    @IBOutlet weak var collectionView: UICollectionView!
    var layout: TimeMachineLayout {
        return collectionView.collectionViewLayout as! TimeMachineLayout
    }
    var currentItemView: SongCell? {
        return collectionView.cellForItemAtIndexPath(NSIndexPath(forItem: 0, inSection: 0)) as? SongCell
    }
    var itemRestingPosition: CGPoint!
    
    @IBOutlet var playlistButtons: [UIButton]!
    
    
    override func viewDidLoad() {
        collectionView.clipsToBounds = false
        unassignedSongs = getAllUnassignedSongs()
    }
    
    override func viewWillAppear(animated: Bool) {
        self.view.layoutIfNeeded()
        collectionView.reloadData()
        
        let topSolid = UIView(frame: CGRectMake(0, 0, self.view.frame.width, self.view.frame.height * 0.1))
        topSolid.backgroundColor = UIColor.whiteColor()
        self.view.addSubview(topSolid)
        
        //add gradient
        for _ in 0...6 {
            let scale = UIScreen.mainScreen().scale
            let gradientView = UIView(frame: CGRectMake(0, self.view.frame.height * 0.1, self.view.frame.width * scale, self.view.frame.height * 0.2 * scale))
            gradientView.backgroundColor = UIColor.clearColor()
            let layer = CAGradientLayer()
            layer.bounds = gradientView.frame
            layer.colors = [UIColor.whiteColor().CGColor, UIColor(white: 1.0, alpha: 0.0).CGColor]
            layer.opacity = 1.0
            gradientView.layer.addSublayer(layer)
            self.view.addSubview(gradientView)
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        guard let currentItemView = currentItemView else { self.noSongsRemaining(); return }
        self.layout.transitioningToNewCurrent = false
        self.itemRestingPosition = currentItemView.frame.origin
        
        currentItemView.startPlayheadTimers()
        updateForNextUnassignedItem()
    }
    
    //MARK - Updating UI
    
    func updateForNextUnassignedItem() {
        
        currentItem = unassignedSongs.first
        if currentItem == nil {
            noSongsRemaining()
            return
        }
        
        collectionView.reloadData()
    }
    
    func noSongsRemaining() {
        
    }
    
        
    //MARK: - Collection View Data Source
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = min(10, unassignedSongs.count)
        return count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("song", forIndexPath: indexPath) as! SongCell
        cell.decorateForSong(unassignedSongs[indexPath.item], atIndexPath: indexPath, controller: self)
        return cell
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
        guard let currentItemView = currentItemView else { return }
        let itemOrigin = currentItemView.frame.origin
        let itemSize = currentItemView.frame.size
        
        //detect playhead dragging
        let playheadRect = CGRect(x: itemOrigin.x - 30.0, y: itemOrigin.y - 20.0, width: itemSize.width + 40.0, height: itemSize.height * 0.25)
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
        guard let currentItemView = currentItemView else { return }
        guard let playhead = currentItemView.playhead else { return }
        
        //update playhead position
        let location = sender.locationInView(currentItemView.itemAlbumArt)
        let availableWidth = currentItemView.itemAlbumArt.frame.width - playhead.frame.width
        let positionOnBar = min(max(location.x, 0), availableWidth)
        playhead.frame.origin = CGPointMake(positionOnBar, 0.0)
        
        //update playback time
        let percentage = Double(positionOnBar / currentItemView.itemAlbumArt.frame.width)
        let durationNumber = currentItem?.valueForProperty(MPMediaItemPropertyPlaybackDuration) as? NSNumber
        guard let duration = durationNumber?.doubleValue else { return }
        let newTime = duration * percentage
        
        //do nothing if the new time is within 5 seconds of the current time
        if newTime - 5 < currentExpectedPlaybackTime && newTime + 5 > currentExpectedPlaybackTime {
            return
        }
        
        currentExpectedPlaybackTime = newTime
        RMPlayer.currentPlaybackTime = newTime
    }
    
    var dragTouchOffset: CGPoint?
    
    func itemDragPanHandler(sender: UIPanGestureRecognizer) {
        guard let currentItemView = currentItemView else { return }
        
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
        let (closestButton, closestDistance) = buttonClosestToCurrentItem()
        
        let itemRestingCenter = CGPointMake(itemRestingPosition.x + (currentItemView.frame.width / 2), itemRestingPosition.y + (currentItemView.frame.height / 2))
        let buttonCenter = CGPointMake(CGRectGetMidX(closestButton.frame), CGRectGetMidY(closestButton.frame))
        
        let restingDistance = itemRestingCenter.distanceTo(buttonCenter)
        let percentage = closestDistance / restingDistance
        animatePlaylistButton(closestButton, atDistancePercentage: percentage)
    }
    
    func buttonClosestToCurrentItem() -> (button: UIButton, distance: CGFloat) {
        guard let currentItemView = currentItemView else { return (playlistButtons[0], 0.0) }
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
        
        return (closestButton, closestDistance)
    }
    
    func processFinishedItemDrag(sender: UIPanGestureRecognizer) {
        guard let currentItemView = currentItemView else { return }
        
        defer {
            //save data
            let (closestButton, distance) = buttonClosestToCurrentItem()
            if let playlist = Playlist.forString(closestButton.restorationIdentifier ?? "") where distance > 50.0 {
                processAssignmentToPlaylist(playlist)
            }
        }
        
        if unassignedSongs.count == 1 {
            noSongsRemaining()
            return
        }
        
        layout.transitioningToNewCurrent = true
        self.collectionView.performBatchUpdates({
            self.collectionView.deleteItemsAtIndexPaths([NSIndexPath(forItem: 0, inSection: 0)])
            self.collectionView.insertItemsAtIndexPaths([NSIndexPath(forItem: self.collectionView.numberOfItemsInSection(0) - 1, inSection: 0)])
        }, completion: { _ in
            print("Reloading")
            print(self.layout.currentDragPercentage)
            self.layout.transitioningToNewCurrent = false
            //self.layout.currentDragPercentage = 0.0
            //self.collectionView.reloadData()
            //print(self.layout.currentDragPercentage)
        })
    
        
        //animate
        let velocityVector = sender.velocityInView(self.view)
        let velocity = -pow((pow(velocityVector.x, 2) + pow(velocityVector.y, 2)), 0.2)
        
        UIView.animateWithDuration(0.6, delay: 0.0, usingSpringWithDamping: 0.75, initialSpringVelocity: velocity, options: [.AllowUserInteraction] , animations: {
            guard let currentItemView = self.currentItemView else { return }
            currentItemView.frame.origin = self.itemRestingPosition
        }, completion: nil)
        
        animatePlaylistButton(nil, atDistancePercentage: 1.0)
        
        
    }
    
    func animatePlaylistButton(button: UIButton?, atDistancePercentage percent: CGFloat) {
        guard let currentItemView = currentItemView else { return }
        
        let buttonScale = max(1.0, 2.5 - (pow(percent, 5) * 1.5))
        
        let itemDistance = itemRestingPosition.distanceTo(currentItemView.frame.origin)
        let maxDistance = self.view.frame.width
        let itemPercentage = 1 - (itemDistance / maxDistance)
        let itemScale = itemPercentage
        //let itemScale = pow(2, 0.75 * itemPercentage) - 0.75
        if button != nil {
            layout.currentDragPercentage = itemPercentage
            layout.invalidateLayout()
        }
        
        UIView.animateWithDuration(0.4, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: [], animations: {
            
            button?.transform = CGAffineTransformMakeScale(buttonScale, buttonScale)
            
            for other in self.playlistButtons {
                if other == button { continue }
                other.transform = CGAffineTransformMakeScale(1.0, 1.0)
            }
            
            //self.currentItemView.alpha = itemScale
            guard let currentItemView = self.currentItemView else { return }
            currentItemView.scaleView.transform = CGAffineTransformMakeScale(itemScale, itemScale)
            
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
        guard let currentItemView = currentItemView else { return }
        
        if RMPlayer.playbackState == .Playing {
            RMPlayer.pause()
            currentItemView.playButton.image = UIImage(named: "button-play")
        }
        else if RMPlayer.playbackState == .Paused {
            RMPlayer.play()
            currentItemView.playButton.image = UIImage(named: "button-pause")
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