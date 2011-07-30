//
//  RPPlaybackManager.m
//  repeatify
//
//  Created by Longyi Qi on 7/30/11.
//  Copyright 2011 Longyi Qi. All rights reserved.
//

#import "RPPlaybackManager.h"

@implementation RPPlaybackManager

-(void)sessionDidEndPlaybackOnMainThread:(SPSession *)aSession {
    [self seekToTrackPosition:0.0];
}

@end
