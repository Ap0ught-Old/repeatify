//
//  repeatifyAppDelegate.h
//  repeatify
//
//  Created by Longyi Qi on 7/25/11.
//  Copyright 2011 Longyi Qi. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RPPlaybackManager.h"

@interface repeatifyAppDelegate : NSObject <NSApplicationDelegate, SPSessionDelegate> {
    NSStatusItem *_statusItem;
    
    RPPlaybackManager *_playbackManager;
}

@end
