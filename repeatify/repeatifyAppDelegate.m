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

- (void)handlePlaylistFolder:(SPPlaylistFolder *)folder indent:(NSInteger)indent;
- (void)handlePlaylist:(SPPlaylist *)list indent:(NSInteger)indent;

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
    
    _statusMenu = [[NSMenu alloc] initWithTitle:@"Status Menu"];
    [_statusMenu addItemWithTitle:@"Hello Spotify" action:@selector(helloSpotify:) keyEquivalent:@""];
    [_statusMenu addItem:[NSMenuItem separatorItem]];
    [_statusMenu addItemWithTitle:@"Quit" action:@selector(quitRepeatify) keyEquivalent:@""];

    
    NSStatusBar *statusBar = [NSStatusBar systemStatusBar];
    _statusItem = [[statusBar statusItemWithLength:NSSquareStatusItemLength] retain];
    [_statusItem setImage:[NSImage imageNamed:@"Icon"]];
    [_statusItem setMenu:_statusMenu];
    [_statusItem setHighlightMode:YES];
    [_statusItem setAction:@selector(helloSpotify:)];
    [_statusItem setTarget:self];
}

- (IBAction)helloSpotify:(id)sender {
    NSLog(@"%@", sender);
    NSLog(@"Hello Spotify!");
    NSLog(@"current user: %@", [[SPSession sharedSession] user].displayName);
    [_statusMenu removeAllItems];
    
    [_statusMenu addItem:[NSMenuItem separatorItem]];
    [_statusMenu addItemWithTitle:@"Quit" action:@selector(quitRepeatify) keyEquivalent:@""];
}

- (IBAction)showPlaylist:(id)sender {
    SPPlaylistContainer *container = [[SPSession sharedSession] userPlaylists];
    NSArray *playlists = container.playlists;
    for (id playlist in playlists) {
        if ([playlist isKindOfClass:[SPPlaylistFolder class]]) {
            [self handlePlaylistFolder:playlist indent:0];
        }
        else if ([playlist isKindOfClass:[SPPlaylist class]]) {
            [self handlePlaylist:playlist indent:0];
        }
    }
}

# pragma marks - menu actions

- (void)handlePlaylistFolder:(SPPlaylistFolder *)folder indent:(NSInteger)indent {
    NSMutableString *indentString = [NSMutableString string];
    for (int i = 0; i < indent; i++) {
        [indentString appendString:@"---"];
    }
    NSLog(@"%@ %@", indentString, folder.name);
    for (id playlist in folder.playlists) {
        if ([playlist isKindOfClass:[SPPlaylistFolder class]]) {
            [self handlePlaylistFolder:playlist indent:(indent + 1)];
        }
        else if ([playlist isKindOfClass:[SPPlaylist class]]) {
            [self handlePlaylist:playlist indent:(indent + 1)];
        }
    }
}

- (void)handlePlaylist:(SPPlaylist *)list indent:(NSInteger)indent {
    NSMutableString *indentString = [NSMutableString string];
    for (int i = 0; i < indent; i++) {
        [indentString appendString:@"---"];
    }
    NSLog(@"%@ %@", indentString, list.name);
    NSArray *tracks = list.tracks;
    for (SPTrack *track in tracks) {
        NSLog(@"%@--- %@\t[%@]", indentString, track.name, track.spotifyURL);
    }
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
}

-(void)session:(SPSession *)aSession recievedMessageForUser:(NSString *)aMessage; {
    NSLog(@"a message: %@", aMessage);
}

@end
