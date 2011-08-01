//
//  repeatifyAppDelegate.h
//  repeatify
//
//  Created by Longyi Qi on 7/25/11.
//  Copyright 2011 Longyi Qi. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RPPlaybackManager.h"

@interface repeatifyAppDelegate : NSObject <NSApplicationDelegate, SPSessionDelegate, NSMenuDelegate> {
    NSStatusItem *_statusItem;
    NSMenu *_statusMenu;
    
    RPPlaybackManager *_playbackManager;
}

@property (nonatomic, retain) IBOutlet NSView *nowPlayingView;
@property (nonatomic, retain) IBOutlet NSImageView *nowPlayingAlbumCoverImageView;
@property (nonatomic, retain) IBOutlet NSTextField *nowPlayingTrackNameLabel;
@property (nonatomic, retain) IBOutlet NSTextField *nowPlayingArtistNameLabel;
@property (nonatomic, retain) IBOutlet NSButton *nowPlayingControllerButton;

@property (assign) IBOutlet NSWindow *loginDialog;
@property (assign) IBOutlet NSTextField *usernameField;
@property (assign) IBOutlet NSSecureTextField *passwordField;


- (IBAction)togglePlayController:(id)sender;
- (IBAction)closeLoginDialog:(id)sender;
- (IBAction)clickLoginButton:(id)sender;

@end
