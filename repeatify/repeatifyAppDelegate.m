//
//  repeatifyAppDelegate.m
//  repeatify
//
//  Created by Longyi Qi on 7/25/11.
//  Copyright 2011 Longyi Qi. All rights reserved.
//

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

- (void)handlePlaylistFolder:(SPPlaylistFolder *)folder menuItem:(NSMenuItem *)menuItem;
- (void)handlePlaylist:(SPPlaylist *)list menuItem:(NSMenuItem *)menuItem;
- (void)handleNowPlayingView:(NSMenu *)menu;

- (void)updateMenu;
- (void)clickTrackMenuItem:(id)sender;
- (void)updateAlbumCoverImage:(id)sender;

- (void)showLoginDialog;
- (void)didLoggedIn;
- (void)logoutUser;
- (void)showAboutPanel;
- (void)quitRepeatify;

@end

@implementation repeatifyAppDelegate

@synthesize nowPlayingView, nowPlayingAlbumCoverImageView, nowPlayingTrackNameLabel, nowPlayingArtistNameLabel, nowPlayingControllerButton;
@synthesize loginDialog, usernameField, passwordField, loginProgressIndicator, loginStatusField;

+(void)initialize {
    if([self class] != [repeatifyAppDelegate class]) return;
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
                                                             [SPMediaKeyTap defaultMediaKeyUserBundleIdentifiers], kMediaKeyUsingBundleIdentifiersDefaultsKey,
                                                             nil]];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self showLoginDialog];
    _loginStatus = RPLoginStatusNoUser;
    
    [[SPSession sharedSession] setDelegate:self];
    
    _playbackManager = [[RPPlaybackManager alloc] initWithPlaybackSession:[SPSession sharedSession]];
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

- (void)dealloc {
    [_statusMenu release];
    [_statusItem release];
    [_playbackManager release];
    [_mediaKeyTap release];
    
    [super dealloc];
}

# pragma marks - menu actions

- (void)updateMenu {
    [_statusMenu removeAllItems];
    
    [self handleNowPlayingView:_statusMenu];
    
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

- (void)handleNowPlayingView:(NSMenu *)menu {
    if (_playbackManager.currentTrack != nil) {
        NSMenuItem *nowPlayingMenuItem = [[NSMenuItem alloc] init];
        nowPlayingMenuItem.view = self.nowPlayingView;
        [menu addItem:nowPlayingMenuItem];
        [nowPlayingMenuItem release];
        
        [menu addItem:[NSMenuItem separatorItem]];
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
        
        if ([_playbackManager playTrack:track error:&error]) {
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
                [cover beginLoading];
                [self performSelector:@selector(updateAlbumCoverImage:) withObject:sender afterDelay:0.5];
            }
            self.nowPlayingControllerButton.image = [NSImage imageNamed:@"pause"];
        }
        else {
            NSLog(@"error description %@", [error localizedDescription]);
        }
    }
}

- (void)updateAlbumCoverImage:(id)sender {
    NSMenuItem *clickedMenuItem = (NSMenuItem *)sender;
    SPTrack *track = [clickedMenuItem representedObject];
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
                [self performSelector:@selector(updateAlbumCoverImage:) withObject:sender afterDelay:0.5];
                return;
            }
        }
    }
}

- (IBAction)togglePlayController:(id)sender {
    if (_playbackManager.isPlaying) {
        self.nowPlayingControllerButton.image = [NSImage imageNamed:@"play"];
        _playbackManager.isPlaying = NO;
    }
    else {
        self.nowPlayingControllerButton.image = [NSImage imageNamed:@"pause"];
        _playbackManager.isPlaying = YES;
    }
}

- (IBAction)closeLoginDialog:(id)sender {
    [self.loginDialog orderOut:nil];
}

- (IBAction)clickLoginButton:(id)sender {
    if ([self.usernameField.stringValue length] > 0 && [self.passwordField.stringValue length] > 0) {
        [[SPSession sharedSession] attemptLoginWithApplicationKey:[NSData dataWithBytes:&g_appkey length:g_appkey_size]
                                                        userAgent:@"com.longyiqi.repeatify"
                                                         userName:self.usernameField.stringValue
                                                         password:self.passwordField.stringValue
                                                            error:nil];
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

- (void)didLoggedIn {
    _loginStatus = RPLoginStatusLoggedIn;
    [self closeLoginDialog:nil];
}

- (void)showAboutPanel {
    [[NSApplication sharedApplication] orderFrontStandardAboutPanel:nil];
}

- (void)logoutUser {
    _loginStatus = RPLoginStatusNoUser;
    [_playbackManager playTrack:nil error:nil];
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
    _loginStatus = RPLoginStatusLoadingPlaylist;
    [self.loginStatusField setStringValue:@"Loading Playlists..."];
    [self performSelector:@selector(didLoggedIn) withObject:nil afterDelay:5.0];
}

-(void)session:(SPSession *)aSession didFailToLoginWithError:(NSError *)error {
    NSLog(@"failed in login");
    _loginStatus = RPLoginStatusNoUser;
    [self.loginStatusField setStringValue:@""];
    [[NSApplication sharedApplication] presentError:error];
    [self.loginProgressIndicator setHidden:YES];
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

#pragma mark - 
#pragma mark SPMediaKeyTap Methods
-(void)mediaKeyTap:(SPMediaKeyTap*)keyTap receivedMediaKeyEvent:(NSEvent*)event {
    NSAssert([event type] == NSSystemDefined && [event subtype] == SPSystemDefinedEventMediaKeys, @"Unexpected NSEvent in mediaKeyTap:receivedMediaKeyEvent:");
    // here be dragons...
    int keyCode = (([event data1] & 0xFFFF0000) >> 16);
    int keyFlags = ([event data1] & 0x0000FFFF);
    BOOL keyIsPressed = (((keyFlags & 0xFF00) >> 8)) == 0xA;
    int keyRepeat = (keyFlags & 0x1);
    
    if (keyIsPressed) {
        NSString *debugString = [NSString stringWithFormat:@"%@", keyRepeat?@", repeated.":@"."];
        switch (keyCode) {
            case NX_KEYTYPE_PLAY:
                debugString = [@"Play/pause pressed" stringByAppendingString:debugString];
                break;
                
            case NX_KEYTYPE_FAST:
                debugString = [@"Ffwd pressed" stringByAppendingString:debugString];
                break;
                
            case NX_KEYTYPE_REWIND:
                debugString = [@"Rewind pressed" stringByAppendingString:debugString];
                break;
            default:
                debugString = [NSString stringWithFormat:@"Key %d pressed%@", keyCode, debugString];
                break;
                // More cases defined in hidsystem/ev_keymap.h
        }
        NSLog(@"%@", debugString);
    }
}

@end
