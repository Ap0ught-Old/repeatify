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

- (void)quitRepeatify;
- (void)updateMenu;
- (void)clickTrackMenuItem:(id)sender;

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
    
    _statusMenu = [[NSMenu alloc] initWithTitle:@"Status Menu"];
    
    [_statusMenu addItemWithTitle:@"Loading Playlist..." action:nil keyEquivalent:@""];
    [_statusMenu addItem:[NSMenuItem separatorItem]];
    [_statusMenu addItemWithTitle:@"Update Playlist" action:@selector(updateMenu) keyEquivalent:@""];
    [_statusMenu addItemWithTitle:@"Quit" action:@selector(quitRepeatify) keyEquivalent:@""];
    
    NSStatusBar *statusBar = [NSStatusBar systemStatusBar];
    _statusItem = [[statusBar statusItemWithLength:NSSquareStatusItemLength] retain];
    [_statusItem setImage:[NSImage imageNamed:@"Icon"]];
    [_statusItem setMenu:_statusMenu];
    [_statusItem setHighlightMode:YES];
    [_statusItem setTarget:self];
}

- (void)dealloc {
    [_statusMenu release];
    [_statusItem release];
    
    [super dealloc];
}

# pragma marks - menu actions

- (void)updateMenu {
    [_statusMenu removeAllItems];
    
    SPPlaylistContainer *container = [[SPSession sharedSession] userPlaylists];
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
    
    [_statusMenu addItem:[NSMenuItem separatorItem]];
    [_statusMenu addItemWithTitle:@"Update Playlist" action:@selector(updateMenu) keyEquivalent:@""];
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
}

- (void)handlePlaylist:(SPPlaylist *)list menuItem:(NSMenuItem *)menuItem {
    [menuItem setTitle:list.name];
    NSMenu *innerMenu = [[NSMenu alloc] init];
    
    NSArray *tracks = list.tracks;
    for (SPTrack *track in tracks) {
        if (track != nil && track.name != nil && track.spotifyURL != nil) {
            NSMenuItem *innerMenuItem = [[NSMenuItem alloc] initWithTitle:track.name action:@selector(clickTrackMenuItem:) keyEquivalent:@""];
            [innerMenuItem setRepresentedObject:track];
            [innerMenu addItem:innerMenuItem];
            [innerMenuItem release];
        }
    }
    
    [menuItem setSubmenu:innerMenu];
}

- (void)clickTrackMenuItem:(id)sender {
    NSMenuItem *clickedMenuItem = (NSMenuItem *)sender;
    SPTrack *track = [clickedMenuItem representedObject];
    NSLog(@"%@", track.spotifyURL);
}

- (void)quitRepeatify {
    [[NSApplication sharedApplication] terminate:nil];
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
    [self updateMenu];
}

-(void)session:(SPSession *)aSession recievedMessageForUser:(NSString *)aMessage; {
    NSLog(@"a message: %@", aMessage);
}

@end
