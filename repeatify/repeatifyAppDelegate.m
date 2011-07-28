//
//  repeatifyAppDelegate.m
//  repeatify
//
//  Created by Longyi Qi on 7/25/11.
//  Copyright 2011 Longyi Qi. All rights reserved.
//

#import "repeatifyAppDelegate.h"
#import "appkey.h"

@implementation repeatifyAppDelegate

@synthesize statusMenu = _statusMenu;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [[SPSession sharedSession] setDelegate:self];
    [[SPSession sharedSession] attemptLoginWithApplicationKey:[NSData dataWithBytes:&g_appkey length:g_appkey_size]
                                                    userAgent:@"com.longyiqi.repeatify"
                                                     userName:sp_username
                                                     password:sp_password
                                                        error:nil];
    
    NSStatusBar *statusBar = [NSStatusBar systemStatusBar];
    _statusItem = [[statusBar statusItemWithLength:NSSquareStatusItemLength] retain];
    [_statusItem setImage:[NSImage imageNamed:@"Icon"]];
    [_statusItem setMenu:_statusMenu];
}

- (IBAction)helloSpotify:(id)sender {
    NSLog(@"Hello Spotify!");
}


#pragma mark -
#pragma mark SPSessionDelegate Methods

-(void)sessionDidLoginSuccessfully:(SPSession *)aSession; {
    SPUser *currentUser = nil;
    
    NSLog(@"%@", currentUser.displayName);
}

-(void)session:(SPSession *)aSession didFailToLoginWithError:(NSError *)error; {
    
    // Invoked by SPSession after a failed login.
    NSLog(@"failed in login");
}

-(void)sessionDidLogOut:(SPSession *)aSession; {}
-(void)session:(SPSession *)aSession didEncounterNetworkError:(NSError *)error; {}
-(void)session:(SPSession *)aSession didLogMessage:(NSString *)aMessage; {}
-(void)sessionDidChangeMetadata:(SPSession *)aSession; {}

-(void)session:(SPSession *)aSession recievedMessageForUser:(NSString *)aMessage; {
    NSLog(@"a message: %@", aMessage);
}

@end
