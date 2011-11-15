//
//  RPPlaybackManager.m
//  repeatify
//
//  Created by Longyi Qi on 7/30/11.
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

#import "RPPlaybackManager.h"
#import "RPArrayUtil.h"

@interface SPPlaybackManager()

-(void)applyVolumeToAudioUnit:(double)vol;

@end

@interface RPPlaybackManager()

@property (nonatomic, retain) NSArray *currentPlaylist;
@property (nonatomic, retain) NSArray *playQueue;

- (void)setCurrentRepeatifyMode:(RPRepeatMode)targetMode;

@end

@implementation RPPlaybackManager

@synthesize currentPlaylist, playQueue;

-(void)sessionDidEndPlaybackOnMainThread:(SPSession *)aSession {
    switch ([self getCurrentRepeatMode]) {
        case RPRepeatOne:
            [self seekToTrackPosition:0.0];
            break;
        case RPRepeatAll:
        case RPRepeatShuffle:
            [self next];
        default:
            break;
    }
}

#pragma mark -
#pragma mark Playback Management

- (RPRepeatMode)getCurrentRepeatMode {
    return (RPRepeatMode)[[NSUserDefaults standardUserDefaults] integerForKey:@"RPRepeatMode"];
}

- (void)setCurrentRepeatifyMode:(RPRepeatMode)targetMode {
    [[NSUserDefaults standardUserDefaults] setInteger:targetMode forKey:@"RPRepeatMode"];
}

- (NSArray *)getCurrentPlayQueue {
    return self.playQueue;
}

#pragma mark -
#pragma mark Play Control

- (void)play:(SPTrack *)track {
    if (track != nil) {
        if (!track.isLoaded) {
            [self performSelector:@selector(play:) withObject:track afterDelay:0.5];
            return;
        }
        
        NSError *error = nil;
        if (![self playTrack:track error:&error]) {
            NSLog(@"error description %@", [error localizedDescription]);
            return;
        }
        
        if ([self getCurrentRepeatMode] != RPRepeatOne && [[NSUserDefaults standardUserDefaults] boolForKey:@"RPGrowlNotification"]) {
            [GrowlApplicationBridge notifyWithTitle:((SPArtist *)[track.artists objectAtIndex:0]).name
                                        description:track.name
                                   notificationName:@"PlayTrack"
                                           iconData:nil
                                           priority:0
                                           isSticky:NO
                                       clickContext:[NSDate date]];
        }
        
        SPImage *cover = track.album.cover;
        if (!cover.isLoaded) {
            [cover beginLoading];
        }
    }
}

- (void)next {
    NSInteger index = [self.playQueue indexOfObject:self.currentTrack];
    NSInteger nextIndex = (index + 1) % [self.playQueue count];
    [self play:[self.playQueue objectAtIndex:nextIndex]];
}

- (void)previous {
    if (self.trackPosition < 5.0) {
        NSInteger index = [self.playQueue indexOfObject:self.currentTrack];
        NSInteger previousIndex = index - 1;
        if (previousIndex == -1) {
            previousIndex = [self.playQueue count] - 1;
        }
        [self play:[self.playQueue objectAtIndex:previousIndex]];
    }
    else {
        [self seekToTrackPosition:0.0];
    }
}

#pragma mark -
#pragma mark Play Queue Control

- (void)setPlaylist:(NSArray *)newPlaylist {
    if (![newPlaylist isEqualToArray:self.playQueue]) {
        self.currentPlaylist = newPlaylist;
    }
    switch ([self getCurrentRepeatMode]) {
        case RPRepeatOne:
            [self toggleRepeatOneMode];
            break;
        case RPRepeatAll:
            [self toggleRepeatAllMode];
            break;
        case RPRepeatShuffle:
            if (![newPlaylist isEqualToArray:self.playQueue]) {
                [self toggleRepeatShuffleMode];
            }
            break;
        default:
            break;
    }
}

- (void)toggleRepeatOneMode {
    [self setCurrentRepeatifyMode:RPRepeatOne];
    self.playQueue = self.currentPlaylist;
}

- (void)toggleRepeatAllMode {
    [self setCurrentRepeatifyMode:RPRepeatAll];
    self.playQueue = self.currentPlaylist;
}

- (void)toggleRepeatShuffleMode {
    [self setCurrentRepeatifyMode:RPRepeatShuffle];
    
    NSMutableArray *mutablePlaylist = [[RPArrayUtil shuffle:self.currentPlaylist] mutableCopy];
    [mutablePlaylist removeObject:self.currentTrack];
    [mutablePlaylist insertObject:self.currentTrack atIndex:0];
    self.playQueue = mutablePlaylist;
    [mutablePlaylist release];
}

- (void)setVolume:(double)volume {
    [super setVolume:volume];
    [super applyVolumeToAudioUnit:volume];
}

@end
