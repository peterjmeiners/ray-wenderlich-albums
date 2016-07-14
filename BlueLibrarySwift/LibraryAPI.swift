//
//  LibraryAPI.swift
//  BlueLibrarySwift
//
//  Created by Peter Meiners on 7/14/16.
//  Copyright © 2016 Raywenderlich. All rights reserved.
//

import UIKit

class LibraryAPI: NSObject {
    
    private let persistencyManager: PersistencyManager
    private let httpClient: HTTPClient
    private let isOnline: Bool
    
    class var sharedInstance: LibraryAPI {
        
        struct Singleton {
            static let instance = LibraryAPI()
        }
        return Singleton.instance
    }
    
    override init() {
        persistencyManager = PersistencyManager()
        httpClient = HTTPClient()
        isOnline = false
        super.init()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LibraryAPI.downloadImage(_:)), name: "BLDownloadImageNotification", object: nil)
    }
    
    func getAlbums() -> [Album] {
        return self.persistencyManager.getAlbums()
    }
    
    func addAlbum(album: Album, index: Int) {
        persistencyManager.addAlbum(album, index: index)
        if isOnline {
            httpClient.postRequest("/api/addAlbum", body: album.description)
        }
    }
    
    func deleteAlbumAtIndex(index: Int) {
        persistencyManager.deleteAlbumAtIndex(index)
        if isOnline {
            httpClient.postRequest("/api/deleteAlbum", body: "\(index)")
        }
    }
    
    func downloadImage(notification: NSNotification) {
        let userInfo = notification.userInfo as! [String: AnyObject]
        let imageView = userInfo["imageView"] as! UIImageView?
        let coverUrl = userInfo["coverUrl"] as! String
        
        if let imageViewUnwrapped = imageView {
            imageViewUnwrapped.image = persistencyManager.getImage(coverUrl)
            if imageViewUnwrapped.image == nil {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                    () -> Void in
                    let downloadedImage = self.httpClient.downloadImage(coverUrl)
                    dispatch_sync(dispatch_get_main_queue(), { () -> Void in
                        imageViewUnwrapped.image = downloadedImage
                        self.persistencyManager.saveImage(downloadedImage, filename: coverUrl)
                    })
                })
            }
        }
    }
    
    func saveAlbums() {
        persistencyManager.saveAlbums()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

}
