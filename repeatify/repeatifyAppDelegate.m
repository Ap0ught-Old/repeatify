//
//  repeatifyAppDelegate.m
//  repeatify
//
//  Created by Longyi Qi on 7/25/11.
//  Copyright 2011 Longyi Qi. All rights reserved.
//

#import "repeatifyAppDelegate.h"
#import "appkey.h"

@interface repeatifyAppDelegate()

- (void)handlePlaylistFolder:(SPPlaylistFolder *)folder menuItem:(NSMenuItem *)menuItem;
- (void)handlePlaylist:(SPPlaylist *)list menuItem:(NSMenuItem *)menuItem;

- (void)updateMenu;
- (void)clickTrackMenuItem:(id)sender;

- (void)showLoginDialog;
- (void)logoutUser;
- (void)quitRepeatify;

@end

@implementation repeatifyAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [[SPSession sharedSession] setDelegate:self];
    [[SPSession sharedSession] attemptLoginWithApplicationKey:[NSData dataWithBytes:&g_appkey length:g_appkey_size]
                                                    userAgent:@"com.longyiqi.repeatify"
                                                     userName:sp_username
                                                     password:sp_password
                                                        error:nil];
    
    _playbackManager = [[RPPlaybackManager alloc] initWithPlaybackSession:[SPSession sharedSession]];
    
    NSStatusBar *statusBar = [NSStatusBar systemStatusBar];
    _statusItem = [[statusBar statusItemWithLength:NSSquareStatusItemLength] retain];
    [_statusItem setImage:[NSImage imageNamed:@"Icon"]];
    [_statusItem setHighlightMode:YES];
    [_statusItem setTarget:self];
    
    _statusMenu = [[NSMenu alloc] initWithTitle:@"Status Menu"];
    [_statusMenu setDelegate:self];
    
    [_statusItem setMenu:_statusMenu];
}

- (void)dealloc {
    [_statusMenu release];
    [_statusItem release];
    [_playbackManager release];
    
    [super dealloc];
}

# pragma marks - menu actions

- (void)updateMenu {
    [_statusMenu removeAllItems];
    SPUser *user = [[SPSession sharedSession] user];
    
    SPPlaylistContainer *container = [[SPSession sharedSession] userPlaylists];
    if (container == nil) {
        if (user == nil) {
            [_statusMenu addItemWithTitle:@"No Login or Unsupport User Type" action:nil keyEquivalent:@""];
        }
        else {
            [_statusMenu addItemWithTitle:@"Loading Playlist..." action:nil keyEquivalent:@""];
        }
    }
    else {
        NSArray *playlists = container.playlists;
        for (id playlist in playlists) {
            NSMenuItem *innerMenuItem = [[NSMenuItem alloc] init];
            
            if ([playlist isKindOfClass:[SPPlaylistFolder class]]) {
                [self handlePlaylistFolder:playlist menuItem:innerMenuItem];
            }
            else if ([playlist isKindOfClass:[SPPlaylist class]]) {
                [self handlePlaylist:playlist menuItem:innerMenuItem];
            }
            
            [_statusMenu addItem:innerMenuItem];
            [innerMenuItem release];
        }
    }
    
    [_statusMenu addItem:[NSMenuItem separatorItem]];
    
    if (user == nil) {
        [_statusMenu addItemWithTitle:@"Login" action:@selector(showLoginDialog) keyEquivalent:@""];
    }
    else {
        [_statusMenu addItemWithTitle:[NSString stringWithFormat:@"Log Out %@", user.displayName] action:@selector(logoutUser) keyEquivalent:@""];
    }
    [_statusMenu addItemWithTitle:@"About Repeatify" action:nil keyEquivalent:@""];
    [_statusMenu addItemWithTitle:@"Quit" action:@selector(quitRepeatify) keyEquivalent:@""];
}

- (void)handlePlaylistFolder:(SPPlaylistFolder *)folder menuItem:(NSMenuItem *)menuItem {
    [menuItem setTitle:folder.name];
    NSMenu *innerMenu = [[NSMenu alloc] init];

    for (id playlist in folder.playlists) {
        NSMenuItem *innerMenuItem = [[NSMenuItem alloc] init];
        
        if ([playlist isKindOfClass:[SPPlaylistFolder class]]) {
            [self handlePlaylistFolder:playlist menuItem:innerMenuItem];
        }
        else if ([playlist isKindOfClass:[SPPlaylist class]]) {
            [self handlePlaylist:playlist menuItem:innerMenuItem];
        }
        
        [innerMenu addItem:innerMenuItem];
        [innerMenuItem release];
    }
    
    [menuItem setSubmenu:innerMenu];
    [innerMenu release];
}

- (void)handlePlaylist:(SPPlaylist *)list menuItem:(NSMenuItem *)menuItem {
    [menuItem setTitle:list.name];
    NSMenu *innerMenu = [[NSMenu alloc] init];
    
    NSArray *tracks = list.tracks;
    for (SPTrack *track in tracks) {
        if (track != nil) {
            NSMenuItem *innerMenuItem;
            if (track.name == nil) {
                innerMenuItem = [[NSMenuItem alloc] initWithTitle:@"Loading Track..." action:nil keyEquivalent:@""];
            }
            else {
                innerMenuItem = [[NSMenuItem alloc] initWithTitle:track.name action:@selector(clickTrackMenuItem:) keyEquivalent:@""];
            }
            [innerMenuItem setRepresentedObject:track];
            [innerMenu addItem:innerMenuItem];
            [innerMenuItem release];
        }
    }
    
    [menuItem setSubmenu:innerMenu];
    [innerMenu release];
}

- (void)clickTrackMenuItem:(id)sender {
    NSMenuItem *clickedMenuItem = (NSMenuItem *)sender;
    SPTrack *track = [clickedMenuItem representedObject];
    
    if (track != nil) {
        if (!track.isLoaded) {
            [self performSelector:@selector(clickTrackMenuItem:) withObject:sender afterDelay:0.5];
            return;
        }
        
        NSError *error = nil;
        
        if (![_playbackManager playTrack:track error:&error]) {
            //[self.window presentError:error];
            NSLog(@"error description %@", [error localizedDescription]);
        }
    }
}

- (void)showLoginDialog {
    NSLog(@"show login dialog");
}

- (void)logoutUser {
    [[SPSession sharedSession] logout];
    [self showLoginDialog];
}

- (void)quitRepeatify {
    [[NSApplication sharedApplication] terminate:nil];
}

#pragma mark -
#pragma mark NSMenuDelegate Methods

- (void)menuNeedsUpdate:(NSMenu *)menu {
    [self updateMenu];
}

#pragma mark -
#pragma mark SPSessionDelegate Methods

-(void)sessionDidLoginSuccessfully:(SPSession *)aSession {
    NSLog(@"login successfully");
}

-(void)session:(SPSession *)aSession didFailToLoginWithError:(NSError *)error {
    NSLog(@"failed in login");
}

-(void)sessionDidLogOut:(SPSession *)aSession {
    NSLog(@"did log out");
}

-(void)session:(SPSession *)aSession didEncounterNetworkError:(NSError *)error {
    NSLog(@"did encounter network error: %@", [error localizedDescription]);
}

-(void)session:(SPSession *)aSession didLogMessage:(NSString *)aMessage {
    NSLog(@"did log message: %@", aMessage);
}

-(void)sessionDidChangeMetadata:(SPSession *)aSession {
    NSLog(@"did change metadata");
}

-(void)session:(SPSession *)aSession recievedMessageForUser:(NSString *)aMessage; {
    NSLog(@"a message: %@", aMessage);
}

@end
