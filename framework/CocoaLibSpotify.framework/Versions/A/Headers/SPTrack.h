//
//  SPTrack.h
//  CocoaLibSpotify
//
//  Created by Daniel Kennett on 2/19/11.
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

/** Represents a track on Spotify.
 
 SPTrack  is roughly analogous to the sp_track struct in the C LibSpotify API.
 */

#import <Foundation/Foundation.h>
#import "CocoaLibSpotifyPlatformImports.h"

@class SPAlbum;
@class SPSession;

@interface SPTrack : NSObject {
    @private
    sp_track *track;
    __weak SPSession *session;
    NSArray *artists;
    SPAlbum *album;
	NSURL *spotifyURL;
}


///----------------------------
/// @name Creating and Initializing Tracks
///----------------------------

/** Creates an SPTrack from the given opaque sp_track struct. 
 
 This convenience method creates an SPTrack object if one doesn't exist, or 
 returns a cached SPTrack if one already exists for the given struct.
 
 @param spTrack The sp_track struct to create an SPTrack for.
 @param aSession The SPSession the track should exist in.
 @return Returns the created SPTrack object. 
 */
+(SPTrack *)trackForTrackStruct:(sp_track *)spTrack inSession:(SPSession *)aSession;

/** Creates an SPTrack from the given Spotify track URL. 
 
 This convenience method creates an SPTrack object if one doesn't exist, or 
 returns a cached SPTrack if one already exists for the given URL.
 
 @warning *Important:* If you pass in an invalid track URL (i.e., any URL not
 starting `spotify:track:`, this method will return `nil`.
 
 @param trackURL The track URL to create an SPTrack for.
 @param aSession The SPSession the track should exist in.
 @return Returns the created SPTrack object, or `nil` if given an invalid track URL. 
 */
+(SPTrack *)trackForTrackURL:(NSURL *)trackURL inSession:(SPSession *)aSession;

/** Initializes a new SPTrack from the given opaque sp_track struct. 
 
@warning *Important:* For better performance and built-in caching, it is recommended
 you create SPTrack objects using +[SPTrack trackForTrackStruct:inSession:], 
 +[SPTrack trackForTrackURL:inSession:] or the instance methods on SPSession.
 
 @param tr The sp_track struct to create an SPTrack for.
 @param aSession The SPSession the track should exist in.
 @return Returns the created SPTrack object. 
 */
-(id)initWithTrackStruct:(sp_track *)tr inSession:(SPSession *)aSession;

///----------------------------
/// @name Properties
///----------------------------

/** Returns `YES` if the track is available for playback. */
@property (readonly) BOOL availableForPlayback;

/** Returns `YES` if the track has finished loading and all data is available. */ 
@property (readonly, getter=isLoaded) BOOL loaded;

/** Returns the Spotify URI of the track, for example: `spotify:track:6JEK0CvvjDjjMUBFoXShNZ` */
@property (readonly, copy) NSURL *spotifyURL;

/** Returns the opaque structure used by the C LibSpotify API. 
 
 @warning *Important:* This should only be used if you plan to directly use the 
 C LibSpotify API. The behaviour of CocoaLibSpotify is undefined if you use the C
 API directly on items that have CocoaLibSpotify objects associated with them. 
 */
@property (readonly) sp_track *track;

/** Returns `YES` if the track is in the logged-in user's starred list. */
@property (readwrite) BOOL starred;

///----------------------------
/// @name Metadata
///----------------------------

/** Returns the album of the track. If no metadata is available for the track yet, returns `nil`. */
@property (readonly, retain) SPAlbum *album;

/** Returns the artist(s) of the track. If no metadata is available for the track yet, returns `nil`. */
@property (readonly, retain) NSArray *artists;

/** Returns a string represention of the artist(s) of the track. If no metadata is available for the track yet, returns `nil`. 
 
 If the track has one artist, returns that artist's name. Otherwise, returns all artist names in alphabetical order, each 
 separated with a comma (,).
 */
@property (readonly, copy) NSString *consolidatedArtists;

/** Returns the disc index of the track. 
 
 Possible values are [1, total number of discs on album]. Returns
 valid data only for tracks appearing in a browse artist or browse album 
 result (otherwise returns 0). 
 
 @see SPAlbumBrowse
 @see SPArtistBrowse
 */
@property (readonly) NSUInteger discNumber;

/** Returns the duration of the track. If no metadata is available for the track yet, returns 0. */
@property (readonly) NSTimeInterval duration;

/** Returns the name of the track.  If no metadata is available for the track yet, returns an empty string. */
@property (readonly) NSString *name;

/** Returns the popularity of the track in range 0 to 100. If no metadata is available for the track yet, returns 0.*/
@property (readonly) NSUInteger popularity;

/** Returns the track position on a disc.
 
 Starts at 1 (relative the corresponding disc). Returns valid data
 only for tracks appearing in a browse artist or browse album result 
 (otherwise returns 0). 
 
 @see SPAlbumBrowse
 @see SPArtistBrowse
 */
@property (readonly) NSUInteger trackNumber;

@end
