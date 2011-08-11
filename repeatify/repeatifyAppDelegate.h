//
//  repeatifyAppDelegate.h
//  repeatify
//
//  Created by Longyi Qi on 7/25/11.
//  Copyright 2011 Longyi Qi. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RPPlaybackManager.h"
#import "SPMediaKeyTap.h"

typedef enum _RPLoginStatus {
    RPLoginStatusNoUser,
    RPLoginStatusLogging,
    RPLoginStatusLoadingPlaylist,
    RPLoginStatusLoggedIn
} RPLoginStatus;

@interface RPApplication : NSApplication
@end

@interface repeatifyAppDelegate : NSObject <NSApplicationDelegate, SPSessionDelegate, NSMenuDelegate> {
    NSStatusItem *_statusItem;
    NSMenu *_statusMenu;
    
    SPMediaKeyTap *_mediaKeyTap;
    SPToplist *_topList;
    RPPlaybackManager *_playbackManager;
    
    RPLoginStatus _loginStatus;
}

@property (nonatomic, retain) IBOutlet NSView *nowPlayingView;
@property (nonatomic, retain) IBOutlet NSImageView *nowPlayingAlbumCoverImageView;
@property (nonatomic, retain) IBOutlet NSTextField *nowPlayingTrackNameLabel;
@property (nonatomic, retain) IBOutlet NSTextField *nowPlayingArtistNameLabel;
@property (nonatomic, retain) IBOutlet NSButton *nowPlayingControllerButton;

@property (nonatomic, retain) IBOutlet NSWindow *loginDialog;
@property (nonatomic, retain) IBOutlet NSTextField *usernameField;
@property (nonatomic, retain) IBOutlet NSSecureTextField *passwordField;
@property (nonatomic, retain) IBOutlet NSProgressIndicator *loginProgressIndicator;
@property (nonatomic, retain) IBOutlet NSTextField *loginStatusField;

- (IBAction)togglePlayController:(id)sender;
- (IBAction)closeLoginDialog:(id)sender;
- (IBAction)clickLoginButton:(id)sender;

@end
