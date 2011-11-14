//
//  repeatifyAppDelegate.m
//  repeatify
//
//  Created by Longyi Qi on 7/25/11.
//  Copyright 2011 Longyi Qi. All rights reserved.
//
/*
 Copyright (c) 2011, Longyi Qi
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 * Neither the name of author nor the names of its contributors may 
 be used to endorse or promote products derived from this software 
 without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
 LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE 
 GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
 HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
 LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT 
 OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "repeatifyAppDelegate.h"
#import "appkey.h"

@implementation RPApplication
- (void)sendEvent:(NSEvent *)theEvent
{
    // If event tap is not installed, handle events that reach the app instead
    BOOL shouldHandleMediaKeyEventLocally = ![SPMediaKeyTap usesGlobalMediaKeyTap];
    
    if(shouldHandleMediaKeyEventLocally && [theEvent type] == NSSystemDefined && [theEvent subtype] == SPSystemDefinedEventMediaKeys) {
        [(id)[self delegate] mediaKeyTap:nil receivedMediaKeyEvent:theEvent];
    }
    [super sendEvent:theEvent];
}
@end

@interface repeatifyAppDelegate()

- (void)switchToRepeatOneMode;
- (void)switchToRepeatAllMode;
- (void)switchToRepeatShuffleMode;

- (void)handlePlaylistFolder:(SPPlaylistFolder *)folder menuItem:(NSMenuItem *)menuItem;
- (void)handlePlaylist:(SPPlaylist *)list menuItem:(NSMenuItem *)menuItem;
- (void)handleTopList:(NSMenu *)menu;
- (void)handleInboxPlaylist:(NSMenu *)menu;
- (void)handleStarredPlaylist:(NSMenu *)menu;
- (void)handleNowPlayingView:(NSMenu *)menu;
- (void)handlePlaybackMenuItem:(NSMenu *)menu;

- (NSArray *)getTracksFromPlaylistItems:(NSArray *)playlistItems;
- (void)addTracks:(NSArray *)tracks toMenuItem:(NSMenuItem *)menuItem;

- (void)togglePlayNext:(id)sender;
- (void)togglePlayPrevious:(id)sender;

- (void)updateMenu;
- (void)clickTrackMenuItem:(id)sender;
- (void)updateAlbumCoverImage:(id)sender;
- (void)updateNowPlayingTrackInformation:(id)sender;
- (void)updateIsPlayingStatus:(id)sender;

- (void)showLoginDialog;
- (void)afterLoggedIn;
- (void)didLoggedIn;
- (void)logoutUser;

- (void)showAboutPanel;
- (void)quitRepeatify;

@end

@implementation repeatifyAppDelegate

@synthesize nowPlayingView, nowPlayingAlbumCoverImageView, nowPlayingTrackNameLabel, nowPlayingArtistNameLabel, nowPlayingControllerButton, volumeControlView, volumeControlSlider;
@synthesize loginDialog, usernameField, passwordField, loginProgressIndicator, loginStatusField, saveCredentialsButton;


#pragma mark -
#pragma mark Application Lifecycle

+(void)initialize {
    if([self class] != [repeatifyAppDelegate class]) return;
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
                                                             [SPMediaKeyTap defaultMediaKeyUserBundleIdentifiers], kMediaKeyUsingBundleIdentifiersDefaultsKey,
                                                             RPRepeatOne, "RPRepeatMode",
                                                             nil]];
}

-(void)applicationWillFinishLaunching:(NSNotification *)notification {
    [SPSession initializeSharedSessionWithApplicationKey:[NSData dataWithBytes:&g_appkey length:g_appkey_size] 
                                               userAgent:@"com.longyiqi.Repeatify"
                                                   error:nil];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    if ([[SPSession sharedSession] attemptLoginWithStoredCredentials:nil]) {
        [self afterLoggedIn];
    }
    else {
        [self showLoginDialog];
        _loginStatus = RPLoginStatusNoUser;
    }
    
    [[SPSession sharedSession] setDelegate:self];
    
    _playbackManager = [[RPPlaybackManager alloc] initWithPlaybackSession:[SPSession sharedSession]];    
    _topList = nil;
    _mediaKeyTap = [[SPMediaKeyTap alloc] initWithDelegate:self];
    if([SPMediaKeyTap usesGlobalMediaKeyTap]) {
        [_mediaKeyTap startWatchingMediaKeys];
    }  
    else {
        NSLog(@"Media key monitoring disabled");
    }
    
    NSStatusBar *statusBar = [NSStatusBar systemStatusBar];
    _statusItem = [[statusBar statusItemWithLength:NSSquareStatusItemLength] retain];
    NSImage *statusBarIcon = [NSImage imageNamed:@"app"];
    [statusBarIcon setSize:NSMakeSize(16, 16)];
    [_statusItem setImage:statusBarIcon];
    [_statusItem setHighlightMode:YES];
    [_statusItem setTarget:self];
    
    _statusMenu = [[NSMenu alloc] initWithTitle:@"Status Menu"];
    [_statusMenu setDelegate:self];
    
    [_statusItem setMenu:_statusMenu];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    if ([SPSession sharedSession].connectionState == SP_CONNECTION_STATE_LOGGED_OUT ||
        [SPSession sharedSession].connectionState == SP_CONNECTION_STATE_UNDEFINED) 
        return NSTerminateNow;
    
    [[SPSession sharedSession] logout];
    return NSTerminateLater;
}

- (void)dealloc {
    [_statusMenu release];
    [_statusItem release];
    [_playbackManager release];
    [_mediaKeyTap release];
    if (_topList != nil) {
        [_topList release];
        _topList = nil;
    }
    
    [super dealloc];
}


#pragma mark -
#pragma mark System Menu Items

- (void)showAboutPanel {
    [[NSApplication sharedApplication] orderFrontStandardAboutPanel:nil];
}


- (void)quitRepeatify {
    [NSApp terminate:self];
}


#pragma mark -
#pragma mark Playlist Menu Items

- (void)updateMenu {
    [_statusMenu removeAllItems];
    
    [self handleNowPlayingView:_statusMenu];
    [self handlePlaybackMenuItem:_statusMenu];
    
    SPUser *user = [[SPSession sharedSession] user];
    
    SPPlaylistContainer *container = [[SPSession sharedSession] userPlaylists];
    if (_loginStatus == RPLoginStatusLogging) {
        [_statusMenu addItemWithTitle:@"Logging In..." action:nil keyEquivalent:@""];
    }
    if (_loginStatus == RPLoginStatusLoadingPlaylist) {
        [_statusMenu addItemWithTitle:@"Loading Playlist..." action:nil keyEquivalent:@""];
    }
    if (_loginStatus == RPLoginStatusLoggedIn && container != nil) {
        NSArray *playlists = container.playlists;
        if ([playlists count] == 0) {
            [_statusMenu addItemWithTitle:@"No Playlist Found" action:nil keyEquivalent:@""];
        }
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
        [self handleStarredPlaylist:_statusMenu];
        [self handleInboxPlaylist:_statusMenu];
        [self handleTopList:_statusMenu];
    }
    
    if (_loginStatus != RPLoginStatusNoUser) {
        [_statusMenu addItem:[NSMenuItem separatorItem]];
    }
    
    if (user == nil) {
        [_statusMenu addItemWithTitle:@"Login" action:@selector(showLoginDialog) keyEquivalent:@""];
    }
    else {
        [_statusMenu addItemWithTitle:[NSString stringWithFormat:@"Log Out %@", user.displayName] action:@selector(logoutUser) keyEquivalent:@""];
    }
    [_statusMenu addItemWithTitle:@"About Repeatify" action:@selector(showAboutPanel) keyEquivalent:@""];
    [_statusMenu addItemWithTitle:@"Quit" action:@selector(quitRepeatify) keyEquivalent:@""];
}

- (void)handleStarredPlaylist:(NSMenu *)menu {
    NSMenuItem *starredPlaylistItem = [[NSMenuItem alloc] init];
    [self handlePlaylist:[[SPSession sharedSession] starredPlaylist] menuItem:starredPlaylistItem];
    [starredPlaylistItem setTitle:@"Starred"];
    [menu addItem:starredPlaylistItem];
    [starredPlaylistItem release];    
}

- (void)handleInboxPlaylist:(NSMenu *)menu {
    NSMenuItem *inboxPlaylistItem = [[NSMenuItem alloc] init];
    [self handlePlaylist:[[SPSession sharedSession] inboxPlaylist] menuItem:inboxPlaylistItem];
    [inboxPlaylistItem setTitle:@"Inbox"];
    [menu addItem:inboxPlaylistItem];
    [inboxPlaylistItem release];
}

- (void)handleTopList:(NSMenu *)menu {
    if (_topList.isLoaded) {
        [menu addItem:[NSMenuItem separatorItem]];
        
        NSMenuItem *innerMenuItem = [[NSMenuItem alloc] init];
        [innerMenuItem setTitle:@"What's Hot"];
        [self addTracks:_topList.tracks toMenuItem:innerMenuItem];
        [menu addItem:innerMenuItem];
        [innerMenuItem release];
    }
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
    [self addTracks:[self getTracksFromPlaylistItems:list.items] toMenuItem:menuItem];
}

- (NSArray *)getTracksFromPlaylistItems:(NSArray *)playlistItems {
    NSMutableArray *tracks = [[NSMutableArray alloc] init];
    for (id item in playlistItems) {
        SPTrack *track = nil;
        if ([item isKindOfClass:[SPPlaylistItem class]]) {
            SPPlaylistItem *playlistItem = (SPPlaylistItem *)item;
            if ([playlistItem.item isKindOfClass:[SPTrack class]]) {
                track = (SPTrack *)playlistItem.item;
            }
        }
        if ([item isKindOfClass:[SPTrack class]]) {
            track = (SPTrack *)item;
        }
        if (track != nil) {
            [tracks addObject:track];
        }
    }
    return [tracks autorelease];
}

- (void)addTracks:(NSArray *)tracks toMenuItem:(NSMenuItem *)menuItem {
    NSMenu *innerMenu = [[NSMenu alloc] init];
    for (SPTrack *track in tracks) {
        if (track != nil) {
            NSMenuItem *innerMenuItem;
            if (track.name == nil) {
                innerMenuItem = [[NSMenuItem alloc] initWithTitle:@"Loading Track..." action:nil keyEquivalent:@""];
            }
            else {
                if (track.availability == SP_TRACK_AVAILABILITY_AVAILABLE) {
                    innerMenuItem = [[NSMenuItem alloc] initWithTitle:track.name action:@selector(clickTrackMenuItem:) keyEquivalent:@""];
                    
                    if ([track isEqualTo:_playbackManager.currentTrack]) {
                        [innerMenuItem setState:NSOnState];
                    }
                    else {
                        [innerMenuItem setState:NSOffState];
                    }
                }
                else {
                    innerMenuItem = [[NSMenuItem alloc] initWithTitle:track.name action:nil keyEquivalent:@""];
                }
            }
            [innerMenuItem setRepresentedObject:[NSArray arrayWithObjects:track, tracks, nil]];
            [innerMenu addItem:innerMenuItem];
            [innerMenuItem release];
        }
    }
    [menuItem setSubmenu:innerMenu];
    [innerMenu release];
}

#pragma mark -
#pragma mark Playback

- (void)clickTrackMenuItem:(id)sender {
    NSMenuItem *clickedMenuItem = (NSMenuItem *)sender;
    
    [_playbackManager play:[[clickedMenuItem representedObject] objectAtIndex:0]];
    NSMutableArray *filteredPlaylist = [[NSMutableArray alloc] init];
    for (SPTrack *track in [[clickedMenuItem representedObject] objectAtIndex:1]) {
        if (track.availability == SP_TRACK_AVAILABILITY_AVAILABLE) {
            [filteredPlaylist addObject:track];
        }
    }
    [_playbackManager setPlaylist:filteredPlaylist];
    [filteredPlaylist release];
}

- (void)updateAlbumCoverImage:(id)sender {
    SPTrack *track = (SPTrack *)sender;
    if (track != nil) {
        if (track.isLoaded) {
            SPImage *cover = track.album.cover;
            if (cover.isLoaded) {
                NSImage *coverImage = cover.image;
                if (coverImage != nil) {
                    [self.nowPlayingAlbumCoverImageView setImage:coverImage];
                }
            }
            else {
                [self performSelector:@selector(updateAlbumCoverImage:) withObject:track afterDelay:0.5];
                return;
            }
        }
    }
}

- (void)updateNowPlayingTrackInformation:(id)sender {
    SPTrack *track = _playbackManager.currentTrack;
    [self.nowPlayingArtistNameLabel setStringValue:((SPArtist *)[track.artists objectAtIndex:0]).name];
    [self.nowPlayingTrackNameLabel setStringValue:track.name];
    SPImage *cover = track.album.cover;
    if (cover.isLoaded) {
        NSImage *coverImage = cover.image;
        if (coverImage != nil) {
            [self.nowPlayingAlbumCoverImageView setImage:coverImage];
        }
    }
    else {
        [self.nowPlayingAlbumCoverImageView setImage:[NSImage imageNamed:@"album-placeholder"]];
        [cover beginLoading];
        [self performSelector:@selector(updateAlbumCoverImage:) withObject:track afterDelay:0.5];
    }
    
    [self updateIsPlayingStatus:self];
}

- (void)updateIsPlayingStatus:(id)sender {
    if (_playbackManager.isPlaying) {
        self.nowPlayingControllerButton.image = [NSImage imageNamed:@"pause"];
    }
    else {
        self.nowPlayingControllerButton.image = [NSImage imageNamed:@"play"];
    }
}

- (void)handleNowPlayingView:(NSMenu *)menu {
    if (_playbackManager.currentTrack != nil) {
        [self updateNowPlayingTrackInformation:self];
        NSMenuItem *nowPlayingMenuItem = [[NSMenuItem alloc] init];
        nowPlayingMenuItem.view = self.nowPlayingView;
        [menu addItem:nowPlayingMenuItem];
        [nowPlayingMenuItem release];
        
        [menu addItem:[NSMenuItem separatorItem]];
    }
}

- (void)handlePlaybackMenuItem:(NSMenu *)menu {
    if (_playbackManager.currentTrack != nil) {
        NSMenuItem *playbackMenuItem = [[NSMenuItem alloc] initWithTitle:@"Playback" action:nil keyEquivalent:@""];
        NSMenu *playbackControlMenu = [[NSMenu alloc] init];
        
        NSMenuItem *playQueueMenuItem = [[NSMenuItem alloc] init];
        [playQueueMenuItem setTitle:@"Play Queue"];
        [self addTracks:[_playbackManager getCurrentPlayQueue] toMenuItem:playQueueMenuItem];
        [playbackControlMenu addItem:playQueueMenuItem];
        [playQueueMenuItem release];
        
        [playbackControlMenu addItemWithTitle:@"" action:nil keyEquivalent:@""];
        [playbackControlMenu addItemWithTitle:@"Play/Pause" action:@selector(togglePlayController:) keyEquivalent:@""];
        [playbackControlMenu addItem:[NSMenuItem separatorItem]];
        
        [playbackControlMenu addItemWithTitle:@"Next" action:@selector(togglePlayNext:) keyEquivalent:@""];
        [playbackControlMenu addItemWithTitle:@"Previous" action:@selector(togglePlayPrevious:) keyEquivalent:@""];
        [playbackControlMenu addItem:[NSMenuItem separatorItem]];
        
        NSMenuItem *repeatOneMenuItem = [[NSMenuItem alloc] initWithTitle:@"Repeat One" action:@selector(switchToRepeatOneMode) keyEquivalent:@""];
        NSMenuItem *repeatAllMenuItem = [[NSMenuItem alloc] initWithTitle:@"Repeat All" action:@selector(switchToRepeatAllMode) keyEquivalent:@""];
        NSMenuItem *repeatShuffleMenuItem = [[NSMenuItem alloc] initWithTitle:@"Repeat Shuffle" action:@selector(switchToRepeatShuffleMode) keyEquivalent:@""];
        
        switch ([_playbackManager getCurrentRepeatMode]) {
            case RPRepeatOne:
                [repeatOneMenuItem setState:NSOnState];
                break;
            case RPRepeatAll:
                [repeatAllMenuItem setState:NSOnState];
                break;
            case RPRepeatShuffle:
                [repeatShuffleMenuItem setState:NSOnState];
                break;
            default:
                break;
        }
        
        [playbackControlMenu addItem:repeatOneMenuItem];
        [playbackControlMenu addItem:repeatAllMenuItem];
        [playbackControlMenu addItem:repeatShuffleMenuItem];
        [repeatOneMenuItem release];
        [repeatAllMenuItem release];
        [repeatShuffleMenuItem release];
        [playbackControlMenu addItem:[NSMenuItem separatorItem]];
        
        NSMenuItem *volumeControlMenuItem = [[NSMenuItem alloc] init];
        volumeControlMenuItem.view = self.volumeControlView;
        [playbackControlMenu addItem:volumeControlMenuItem];
        [volumeControlMenuItem release];
        
        [playbackMenuItem setSubmenu:playbackControlMenu];
        [menu addItem:playbackMenuItem];
        
        [playbackControlMenu release];
        [playbackMenuItem release];
        
        [menu addItem:[NSMenuItem separatorItem]];
    }
}

- (IBAction)togglePlayController:(id)sender {
    if (_playbackManager.currentTrack != nil) {
        _playbackManager.isPlaying = !_playbackManager.isPlaying;
        [self updateIsPlayingStatus:self];
    }
}

- (void)togglePlayNext:(id)sender {
    [_playbackManager next];
    [self updateMenu];
}

- (void)togglePlayPrevious:(id)sender {
    [_playbackManager previous];
    [self updateMenu];
}

#pragma mark -
#pragma mark Playback Management

- (void)switchToRepeatOneMode {
    [_playbackManager toggleRepeatOneMode];
}

- (void)switchToRepeatAllMode {
    [_playbackManager toggleRepeatAllMode];
}

- (void)switchToRepeatShuffleMode {
    [_playbackManager toggleRepeatShuffleMode];
}


#pragma mark -
#pragma mark Volume Change Methods

- (IBAction)volumeChanged:(id)sender {
    NSSlider *volumeSlider = (NSSlider *)sender;
    _playbackManager.volume = volumeSlider.doubleValue;
}


#pragma mark -
#pragma mark NSMenuDelegate Methods

- (void)menuNeedsUpdate:(NSMenu *)menu {
    [self updateMenu];
}

#pragma mark -
#pragma mark Login/Logout methods

- (IBAction)closeLoginDialog:(id)sender {
    [self.loginDialog orderOut:nil];
}

- (IBAction)clickLoginButton:(id)sender {
    if ([self.usernameField.stringValue length] > 0 && [self.passwordField.stringValue length] > 0) {
        [[SPSession sharedSession] attemptLoginWithUserName:self.usernameField.stringValue
                                                   password:self.passwordField.stringValue
                                        rememberCredentials:self.saveCredentialsButton.state];
        [self.loginProgressIndicator setHidden:NO];
        [self.loginProgressIndicator startAnimation:self];
        _loginStatus = RPLoginStatusLogging;
        [self.loginStatusField setStringValue:@"Logging In..."];
    }
    else {
        NSBeep();
    }
}

- (void)showLoginDialog {
    _loginStatus = RPLoginStatusNoUser;
    self.usernameField.stringValue = @"";
    self.passwordField.stringValue = @"";
    [self.loginDialog center];
    [self.loginDialog orderFront:nil];
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    [self.loginProgressIndicator setHidden:YES];
    [self.loginStatusField setStringValue:@""];
}

- (void)afterLoggedIn {
    _topList = [[SPToplist alloc] initLocaleToplistWithLocale:nil inSession:[SPSession sharedSession]];
    _loginStatus = RPLoginStatusLoggedIn;
}

- (void)didLoggedIn {
    [self afterLoggedIn];
    [self closeLoginDialog:nil];
}

- (void)logoutUser {
    _loginStatus = RPLoginStatusNoUser;
    [_playbackManager playTrack:nil error:nil];
    [[SPSession sharedSession] forgetStoredCredentials];
    [[SPSession sharedSession] logout];
    [self showLoginDialog];
}

#pragma mark -
#pragma mark SPSessionDelegate Methods

-(void)sessionDidLoginSuccessfully:(SPSession *)aSession {
    _loginStatus = RPLoginStatusLoadingPlaylist;
    [self.loginStatusField setStringValue:@"Loading Playlists..."];
    [self performSelector:@selector(didLoggedIn) withObject:nil afterDelay:5.0];
}

-(void)session:(SPSession *)aSession didFailToLoginWithError:(NSError *)error {
    _loginStatus = RPLoginStatusNoUser;
    [self.loginStatusField setStringValue:@""];
    if (error.code == SP_ERROR_USER_BANNED) {
        [[NSApplication sharedApplication] presentError:[NSError spotifyErrorWithDescription:@"Please upgrade to Spotify Premium account"]];
    }
    else {
        [[NSApplication sharedApplication] presentError:error];
    }
    [self.passwordField becomeFirstResponder];
    
    [self.loginProgressIndicator setHidden:YES];
}

-(void)sessionDidLogOut:(SPSession *)aSession; {
    [[NSApplication sharedApplication] replyToApplicationShouldTerminate:YES];
}

-(void)session:(SPSession *)aSession didEncounterNetworkError:(NSError *)error {
    NSLog(@"did encounter network error: %@", [error localizedDescription]);
}

-(void)session:(SPSession *)aSession didLogMessage:(NSString *)aMessage {
    // NSLog(@"did log message: %@", aMessage);
}

-(void)sessionDidChangeMetadata:(SPSession *)aSession {
    // NSLog(@"did change metadata");
}

-(void)session:(SPSession *)aSession recievedMessageForUser:(NSString *)aMessage; {
    NSLog(@"a message: %@", aMessage);
}

#pragma mark - 
#pragma mark SPMediaKeyTap Methods
-(void)mediaKeyTap:(SPMediaKeyTap*)keyTap receivedMediaKeyEvent:(NSEvent*)event {
    NSAssert([event type] == NSSystemDefined && [event subtype] == SPSystemDefinedEventMediaKeys, @"Unexpected NSEvent in mediaKeyTap:receivedMediaKeyEvent:");
    int keyCode = (([event data1] & 0xFFFF0000) >> 16);
    int keyFlags = ([event data1] & 0x0000FFFF);
    BOOL keyIsPressed = (((keyFlags & 0xFF00) >> 8)) == 0xA;
    
    if (keyIsPressed) {
        switch (keyCode) {
            case NX_KEYTYPE_PLAY:
                [self togglePlayController:self];
                break;
            case NX_KEYTYPE_FAST:
                [self togglePlayNext:self];
                break;
            case NX_KEYTYPE_REWIND:
                [self togglePlayPrevious:self];
                break;
            default:
                break;
        }
    }
}

@end
