//
//  SPPlaybackManager.m
//  Guess The Intro
//
//  Created by Daniel Kennett on 06/05/2011.
/*
 Copyright (c) 2011, Spotify AB
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 * Neither the name of Spotify AB nor the names of its contributors may 
 be used to endorse or promote products derived from this software 
 without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL SPOTIFY AB BE LIABLE FOR ANY DIRECT, INDIRECT,
 INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT 
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
 OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "SPPlaybackManager.h"

@interface SPPlaybackManager ()

@property (nonatomic, readwrite, retain) SPCircularBuffer *audioBuffer;
@property (nonatomic, readwrite, retain) CoCAAudioUnit *audioUnit;

@property (nonatomic, readwrite, retain) SPTrack *currentTrack;
@property (nonatomic, readwrite, retain) SPSession *playbackSession;

@property (readwrite) NSTimeInterval trackPosition;

@end

static NSString * const kSPPlaybackManagerKVOContext = @"kSPPlaybackManagerKVOContext"; 
static NSUInteger const kMaximumBytesInBuffer = 44100 * 2 * 2 * 0.5; // 0.5 Second @ 44.1kHz, 16bit per channel, stereo

@implementation SPPlaybackManager

-(id)initWithPlaybackSession:(SPSession *)aSession {
    
    if ((self = [super init])) {
        self.playbackSession = aSession;
		self.playbackSession.playbackDelegate = self;
		
		self.volume = 1.0;
		
		self.audioBuffer = [[[SPCircularBuffer alloc] initWithMaximumLength:kMaximumBytesInBuffer] autorelease];
		self.audioUnit = [CoCAAudioUnit defaultOutputUnit];
		[self.audioUnit setRenderDelegate:self];
		[self.audioUnit setup];
		
		[self addObserver:self
			   forKeyPath:@"playbackSession.isPlaying"
				  options:0
				  context:kSPPlaybackManagerKVOContext];
    }
    return self;
}

@synthesize audioBuffer;
@synthesize audioUnit;
@synthesize playbackSession;
@synthesize trackPosition;
@synthesize volume;
@synthesize delegate;

@synthesize currentTrack;

-(BOOL)playTrack:(SPTrack *)trackToPlay error:(NSError **)error {
	
	[self.playbackSession setPlaying:NO];
	[self.playbackSession unloadPlayback];
	[self.audioUnit stop];
	self.audioUnit = nil;
	
	[self.audioBuffer clear];
		
	self.currentTrack = trackToPlay;
	self.trackPosition = 0.0;
	BOOL result = [self.playbackSession playTrack:self.currentTrack error:error];
	if (result)
		self.playbackSession.playing = YES;
	return result;
}

-(void)seekToTrackPosition:(NSTimeInterval)newPosition {
	if (newPosition <= self.currentTrack.duration) {
		[self.playbackSession seekPlaybackToOffset:newPosition];
		self.trackPosition = newPosition;
	}	
}

+(NSSet *)keyPathsForValuesAffectingIsPlaying {
	return [NSSet setWithObject:@"playbackSession.isPlaying"];
}

-(BOOL)isPlaying {
	return self.playbackSession.isPlaying;
}

-(void)setIsPlaying:(BOOL)isPlaying {
	self.playbackSession.playing = isPlaying;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
	if ([keyPath isEqualToString:@"playbackSession.isPlaying"] && context == kSPPlaybackManagerKVOContext) {
        if (self.playbackSession.isPlaying) {
			[self.audioUnit start];
		} else {
			[self.audioUnit stop];
		}
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

#pragma mark -
#pragma mark Playback Callbacks

-(void)sessionDidLosePlayToken:(SPSession *)aSession {

	// This delegate is called when playback stops because the Spotify account is being used for playback elsewhere.
	// In practice, playback is only paused and you can call [SPSession -setIsPlaying:YES] to start playback again and 
	// pause the other client.

}

-(void)sessionDidEndPlayback:(SPSession *)aSession {
	
	// This delegate is called when playback stops naturally, at the end of a track.
	
	// Not routing this through to the main thread causes odd locks and crashes.
	[self performSelectorOnMainThread:@selector(sessionDidEndPlaybackOnMainThread:)
						   withObject:aSession
						waitUntilDone:NO];
}

-(void)sessionDidEndPlaybackOnMainThread:(SPSession *)aSession {
	
	self.currentTrack = nil;
	
}

#pragma mark -
#pragma mark Audio Processing

-(NSInteger)session:(SPSession *)aSession shouldDeliverAudioFrames:(const void *)audioFrames ofCount:(NSInteger)frameCount format:(const sp_audioformat *)audioFormat {
	
	if (frameCount == 0) {
		
		// If this happens (frameCount of 0), the user has seeked the track somewhere (or similar). 
		// Clear audio buffers and wait for more data.
		
		[self.audioBuffer clear];
		return 0;
	}
	
	if (self.audioBuffer.length == 0)
		[(NSObject *)self.delegate performSelectorOnMainThread:@selector(playbackManagerWillStartPlayingAudio:)
													withObject:self
												 waitUntilDone:YES];
	
	NSUInteger frameByteSize = sizeof(sint16) * audioFormat->channels;
	NSUInteger dataLength = frameCount * frameByteSize;
	
	if ((self.audioBuffer.maximumLength - self.audioBuffer.length) < dataLength) {
		// Only allow whole deliveries in, since libSpotify wants us to consume whole frames, whereas
		// the buffer works in bytes, meaning we could consume a fraction of a frame.
		return 0;
	}
	
	[self.audioBuffer attemptAppendData:audioFrames ofLength:dataLength];
	
	if (self.audioUnit == nil) {
		self.audioUnit = [CoCAAudioUnit defaultOutputUnit];
		[self.audioUnit setRenderDelegate:self];
		[self.audioUnit setup];
		[self.audioUnit start];
    }
	
	return frameCount;
}

static UInt32 framesSinceLastUpdate = 0;

-(OSStatus)audioUnit:(CoCAAudioUnit*)audioUnit
     renderWithFlags:(AudioUnitRenderActionFlags*)ioActionFlags
                  at:(const AudioTimeStamp*)inTimeStamp
               onBus:(UInt32)inBusNumber
          frameCount:(UInt32)inNumberFrames
           audioData:(AudioBufferList *)ioData {
	
    // Core Audio generally expects audio data to be in native-endian 32-bit floating-point linear PCM format.
	
	AudioBuffer *leftBuffer = &(ioData->mBuffers[0]);
	AudioBuffer *rightBuffer = &(ioData->mBuffers[1]);
	
	NSUInteger bytesRequired = inNumberFrames * 2 * 2; // 16bit per channel, stereo
	void *frameBuffer = NULL;
	
	@synchronized(audioBuffer) {
		NSUInteger availableData = [audioBuffer length];
		if (availableData >= bytesRequired) {
			[audioBuffer readDataOfLength:bytesRequired intoBuffer:&frameBuffer];
			// We've done a length check just above, so hopefully we don't have to care about  how much was read.
		} else {
			leftBuffer->mDataByteSize = 0;
			rightBuffer->mDataByteSize = 0;
			*ioActionFlags |= kAudioUnitRenderAction_OutputIsSilence;
			return noErr;
		}
	}
	
	float *leftChannelBuffer = leftBuffer->mData;
	float *rightChannelBuffer = rightBuffer->mData;
	
	sint16 *frames = frameBuffer;
	double effectiveVolume = self.volume;
	
	for (NSUInteger currentFrame = 0; currentFrame < inNumberFrames; currentFrame++) {
		
		// Convert the frames from 16-bit signed integers to floating point, then apply the volume.
		leftChannelBuffer[currentFrame] = (frames[currentFrame * 2]/(float)INT16_MAX) * effectiveVolume;
		rightChannelBuffer[currentFrame] = (frames[(currentFrame * 2) + 1]/(float)INT16_MAX) * effectiveVolume;
	}
	
	if (frameBuffer != NULL) 
		free(frameBuffer);
	frames = NULL;
	
	framesSinceLastUpdate += inNumberFrames;
	
	if (framesSinceLastUpdate >= 8820) {
		// Update 5 times per second.
		
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		NSTimeInterval newTrackPosition = self.trackPosition + (double)framesSinceLastUpdate/44100.0;
		
		SEL setTrackPositionSelector = @selector(setTrackPosition:);
		NSMethodSignature *aSignature = [[self class] instanceMethodSignatureForSelector:setTrackPositionSelector];
		NSInvocation *anInvocation = [NSInvocation invocationWithMethodSignature:aSignature];
		[anInvocation setSelector:setTrackPositionSelector];
		[anInvocation setTarget:self];
		[anInvocation setArgument:&newTrackPosition atIndex:2];
		
		[anInvocation performSelectorOnMainThread:@selector(invoke)
									   withObject:nil
									waitUntilDone:NO];
		[pool drain];
		
		framesSinceLastUpdate = 0;
	}
    
    return noErr;
}


- (void)dealloc {
	
	[self removeObserver:self forKeyPath:@"playbackSession.isPlaying"];
	
	self.playbackSession.playbackDelegate = nil;
	self.playbackSession = nil;
	
	[self.audioUnit stop];
	self.audioUnit = nil;
	self.audioBuffer = nil;
	
	self.currentTrack = nil;
	
    [super dealloc];
}

@end
