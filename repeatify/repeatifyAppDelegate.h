//
//  repeatifyAppDelegate.h
//  repeatify
//
//  Created by Longyi Qi on 7/25/11.
//  Copyright 2011 Longyi Qi. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface repeatifyAppDelegate : NSObject <NSApplicationDelegate, SPSessionDelegate> {
    NSStatusItem *_statusItem;
}

@property (strong) IBOutlet NSMenu *statusMenu;

- (IBAction)helloSpotify:(id)sender;

@end
