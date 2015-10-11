//
//  SongCell.swift
//  RunningMusic
//
//  Created by Cal on 10/10/15.
//  Copyright © 2015 Cal. All rights reserved.
//

import Foundation
import UIKit
import MediaPlayer

class SongCell : UICollectionViewCell {
    
    var controller: MusicViewController!
    var item: MPMediaItem!
    var indexPath: NSIndexPath!
    
    @IBOutlet weak var scaleView: UIView!
    @IBOutlet weak var itemAlbumArt: UIImageView!
    @IBOutlet weak var itemNameLabel: UILabel!
    @IBOutlet weak var itemArtistLabel: UILabel!
    @IBOutlet weak var playButton: UIImageView!
    var playhead: UIView?
    var playBar: UIView?
    var playheadTimer: NSTimer?
    
    func decorateForSong(item: MPMediaItem, atIndexPath indexPath: NSIndexPath, controller: MusicViewController) {
        self.item = item
        self.controller = controller
        self.indexPath = indexPath
        
        SongCell.decorateForSong(item, inNameLabel: itemNameLabel, artistLabel: itemArtistLabel, albumArt: itemAlbumArt)
        
        //set as player item
        if indexPath.item != 0 { return }
        
        RMPlayer.nowPlayingItem = item
        if playButton.image == UIImage(named: "button-pause") {
            RMPlayer.play()
        }
        
        //trash the old playhead
        for subview in self.itemAlbumArt.subviews {
            if subview.restorationIdentifier == "playhead" {
                subview.removeFromSuperview()
                break
            }
        }
        
        //create playhead
        let height = itemAlbumArt.frame.height * 0.075
        let frame = CGRect(origin: CGPointZero, size: CGSizeMake(3.0, height))
        playhead = UIView(frame: frame)
        playhead!.restorationIdentifier = "playhead"
        playhead!.backgroundColor = UIColor(hue: 0.0, saturation: 0.6, brightness: 1.0, alpha: 1.0)
        itemAlbumArt.addSubview(playhead!)
    }
    
    static func decorateForSong(item: MPMediaItem, inNameLabel nameLabel: UILabel, artistLabel: UILabel, albumArt: UIImageView) {
        let name = item.valueForProperty(MPMediaItemPropertyTitle) as? NSString ?? "Untitled Song"
        nameLabel.text = name as String
        
        let artist = item.valueForProperty(MPMediaItemPropertyArtist) as? NSString ?? ""
        artistLabel.text = artist as String
        
        let artwork = item.valueForProperty(MPMediaItemPropertyArtwork) as? MPMediaItemArtwork
        let artScale = UIScreen.mainScreen().scale
        let artSize = CGSizeMake(albumArt.frame.width * artScale, albumArt.frame.height * artScale)
        //TODO: add art-default as image asset
        let albumArtImage = artwork?.imageWithSize(artSize) ?? UIImage(named: "art-default")!
        albumArt.image = albumArtImage
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.playhead?.removeFromSuperview()
        self.playhead = nil
        self.playBar?.removeFromSuperview()
        self.playBar = nil
        self.playheadTimer?.invalidate()
        self.playheadTimer = nil
        self.transform = CGAffineTransformIdentity
        self.indexPath = nil
    }
    
    func startPlayheadTimers() {
        
        //add play bar to top of album art view
        itemAlbumArt.clipsToBounds = false
        self.clipsToBounds = false
        let frame = CGRect(origin: CGPointMake(0.0, -4.0), size: CGSizeMake(itemAlbumArt.frame.width, 4.0))
        self.playBar = UIView(frame: frame)
        playBar!.backgroundColor = UIColor(hue: 0.0, saturation: 0.6, brightness: 1.0, alpha: 1.0)
        itemAlbumArt.addSubview(playBar!)
        
        playheadTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "updatePlayhead", userInfo: nil, repeats: true)
    }
    
    func updatePlayhead() {
        //do nothing if the playhead is being dragged
        if controller.currentPanHandlerType == .Playhead { return }
        
        guard let playhead = playhead else { return }
        let currentTime = RMPlayer.currentPlaybackTime
        let durationNumber = item.valueForProperty(MPMediaItemPropertyPlaybackDuration) as? NSNumber
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
    
    override func applyLayoutAttributes(layoutAttributes: UICollectionViewLayoutAttributes) {
        super.applyLayoutAttributes(layoutAttributes)
        
        let index = layoutAttributes.indexPath.item
        if index == 0 && self.playhead == nil && controller?.unassignedSongs.count > 1 {
            if let song = controller?.unassignedSongs[1] {
                self.decorateForSong(song, atIndexPath: layoutAttributes.indexPath, controller: controller)
                //self.startPlayheadTimers()
            }
        }
        
        if let attributes = layoutAttributes as? SongCellAttributes {
            self.itemNameLabel.alpha = attributes.textAlpha
            self.itemArtistLabel.alpha = attributes.textAlpha
        }
    }
    
}

class SongCellAttributes : UICollectionViewLayoutAttributes {
    
    var textAlpha: CGFloat! = 0.0
    
    override func copyWithZone(zone: NSZone) -> AnyObject {
        let copy = super.copyWithZone(zone) as! SongCellAttributes
        copy.textAlpha = textAlpha
        return copy
    }
    
    override func isEqual(object: AnyObject?) -> Bool {
        if let attributes = object as? SongCellAttributes {
            if attributes.textAlpha == textAlpha {
                return super.isEqual(object)
            }
        }
        return false
    }
    
}
