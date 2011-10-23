//
//  SPPlaylist.h
//  CocoaLibSpotify
//
//  Created by Daniel Kennett on 2/14/11.
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

/** This class represents a list of tracks, be it a user's starred list, inbox, or a traditional "playlist". */

#import <Foundation/Foundation.h>
#import "CocoaLibSpotifyPlatformImports.h"

@class SPUser;
@class SPImage;
@class SPSession;
@protocol SPPlaylistDelegate;

@interface SPPlaylist : NSObject {
@private 
    sp_playlist *playlist;
    BOOL updating;
    BOOL loaded;
    BOOL collaborative;
    BOOL hasPendingChanges;
    __weak id <SPPlaylistDelegate> delegate;
    __weak SPSession *session;
    NSString *playlistDescription;
    NSString *name;
    SPImage *image;
    SPUser *owner;
	NSURL *spotifyURL;
	BOOL trackChangesAreFromLibSpotifyCallback;
	NSMutableArray *trackWrapper;
	NSArray *subscribers;
}

///----------------------------
/// @name Creating and Initializing Playlists
///----------------------------

/** Creates an SPPlaylist from the given opaque sp_playlist struct. 
 
 This convenience method creates an SPPlaylist object if one doesn't exist, or 
 returns a cached SPPlaylist if one already exists for the given struct.
 
 @param pl The sp_playlist struct to create an SPPlaylist for.
 @param aSession The SPSession the playlist should exist in.
 @return Returns the created SPPlaylist object. 
 */
+(SPPlaylist *)playlistWithPlaylistStruct:(sp_playlist *)pl inSession:(SPSession *)aSession;

/** Creates an SPPlaylist from the given Spotify playlist URL. 
 
 This convenience method creates an SPPlaylist object if one doesn't exist, or 
 returns a cached SPPlaylist if one already exists for the given URL.
 
 @warning *Important:* If you pass in an invalid playlist URL (i.e., any URL not
 starting `spotify:user:XXXX:playlist:`, this method will return `nil`.

 @param playlistURL The playlist URL to create an SPPlaylist for.
 @param aSession The SPSession the playlist should exist in.
 @return Returns the created SPPlaylist object. 
 */
+(SPPlaylist *)playlistWithPlaylistURL:(NSURL *)playlistURL inSession:(SPSession *)aSession;

/** Initializes an SPPlaylist from the given opaque sp_playlist struct. 
 
 @warning *Important:* For better performance and built-in caching, it is recommended
 you create SPPlaylist objects using +[SPPlaylist playlistWithPlaylistStruct:inSession:], 
 +[SPPlaylist playlistWithPlaylistURL:inSession:] or the instance methods on SPSession.
 
 @param pl The sp_playlist struct to create an SPPlaylist for.
 @param aSession The SPSession the playlist should exist in.
 @return Returns the created SPPlaylist object. 
 */
-(id)initWithPlaylistStruct:(sp_playlist *)pl inSession:(SPSession *)aSession;

///----------------------------
/// @name Properties
///----------------------------

/** Returns the playlist's delegate object. */
@property (readwrite, assign) __weak id <SPPlaylistDelegate> delegate;

/** Returns `YES` if the playlist has changes not yet recognised by the Spotify servers, otherwise `NO`. */
@property (readonly) BOOL hasPendingChanges;

/** Returns `YES` if the playlist is collaborative (can be edited by users other than the owner), otherwise `NO`. */
@property (readwrite, getter=isCollaborative) BOOL collaborative;

/** Returns `YES` if the playlist has finished loading and all data is available. */ 
@property (readonly, getter=isLoaded) BOOL loaded;

/** Returns `YES` if the playlist is marked for offline playback. */
@property (readwrite, getter=isMarkedForOfflinePlayback) BOOL markedForOfflinePlayback;

/** Returns `YES` if the playlist is being updated, otherwise `NO`. 
 
 Typically, you should delay UI updates while this property is set to `YES`.
 */ 
@property (readonly, getter=isUpdating) BOOL updating;

/** Returns the download progress of the playlist (between 0 and 1) is it is marked for offline sync. */
@property (readonly) float offlineDownloadProgress;

/** Returns the offline status of the playlist. Possible values:
 
 SP_PLAYLIST_OFFLINE_STATUS_NO 	
 Playlist is not offline enabled.
 
 SP_PLAYLIST_OFFLINE_STATUS_YES 	
 Playlist is synchronized to local storage.
 
 SP_PLAYLIST_OFFLINE_STATUS_DOWNLOADING 	
 This playlist is currently downloading. Only one playlist can be in this state any given time.
 
 SP_PLAYLIST_OFFLINE_STATUS_WAITING 	
 Playlist is queued for download.
 */
@property (readonly) sp_playlist_offline_status offlineStatus;

/** Returns the owner of the playlist, or `nil` if the playlist hasn't loaded yet. */
@property (readonly, retain) SPUser *owner;

/** Returns the opaque structure used by the C LibSpotify API. 
 
 @warning *Important:* This should only be used if you plan to directly use the 
 C LibSpotify API. The behaviour of CocoaLibSpotify is undefined if you use the C
 API directly on items that have CocoaLibSpotify objects associated with them. 
 */
@property (readonly) sp_playlist *playlist;

/** Returns the session object the playlist is loaded in. */
@property (readonly, assign) __weak SPSession *session;

/** Returns the Spotify URI of the playlist profile, for example: `spotify:user:sarnesjo:playlist:3p2c7mmML3fIUh5fcZ8Hcq` */
@property (readonly, copy) NSURL *spotifyURL;

/** Returns the subscribers to the playlist as an array of Spotify usernames. */
@property (readonly, retain) NSArray *subscribers;

///----------------------------
/// @name Metadata
///----------------------------

/** Returns the custom image for the playlist, or `nil` if the playlist hasn't loaded yet or it doesn't have a custom image. */
@property (readonly, retain) SPImage *image;

/** Returns the name of the playlist, or `nil` if the playlist hasn't loaded yet. */
@property (readwrite, copy) NSString *name;

/** Returns the custom description for the playlist, or `nil` if the playlist hasn't loaded yet or it doesn't have a custom description. */
@property (readonly, copy) NSString *playlistDescription;

///----------------------------
/// @name Working with Tracks
///----------------------------

/** Returns an array of SPTrack objects representing playlist's track order.
 
 This array is KVO compliant, and any changes made will be reflected in the user's account.
 
 @warning *Important:* If you need to move a track from one location in this list to another, please
 use `-moveTracksAtIndexes:toIndex:error:` for performance reasons.
 
 @see -moveTracksAtIndexes:toIndex:error:
 */
@property (readonly) NSMutableArray *tracks;

/** Move track(s) to another location in the list. 
 
 All indexes are given relative to the state of the track order before the move is executed. Therefore, you
 *don't* need to adjust the destination index to take into account tracks that will be moved from above it.
 
 @warning *Important:* This operation can fail, for example if you give invalid indexes. Please make sure 
 you check the result of this method.
 
 @param indexes The indexes of the tracks to move.
 @param newLocation The index the tracks should be moved to.
 @param error An NSError pointer to be filled if the operation fails.
 @return Returns `YES` if the operation succeeded, otherwise `NO`. 
 */
-(BOOL)moveTracksAtIndexes:(NSIndexSet *)indexes toIndex:(NSUInteger)newLocation error:(NSError **)error;

@end

/** Delegate callbacks from SPPlaylist to help with track reordering. */

@protocol SPPlaylistDelegate <NSObject>
@optional

/** Called when one or more tracks in the playlist updated their metadata. 
 
 @param aPlaylist The playlist in which tracks updated their metadata.
 */
-(void)tracksInPlaylistDidUpdateMetadata:(SPPlaylist *)aPlaylist;

///----------------------------
/// @name Track Removal
///----------------------------

/** Called before one or more tracks in the playlist will be removed from the playlist. 
 
 @param aPlaylist The playlist in which tracks will be removed.
 @param tracks The tracks that will be removed.
 @param outgoingIndexes The indexes of the tracks.
 */
-(void)playlist:(SPPlaylist *)aPlaylist willRemoveTracks:(NSArray *)tracks atIndexes:(NSIndexSet *)outgoingIndexes;

/** Called after one or more tracks in the playlist were removed from the playlist. 
 
 @warning *Important:* The index set passed to this method is not valid for the given tracks.
 
 @param aPlaylist The playlist in which tracks were removed.
 @param tracks The tracks that were be removed.
 @param theseIndexesArentValidAnymore The (now invalid) indexes of the tracks.
 */
-(void)playlist:(SPPlaylist *)aPlaylist didRemoveTracks:(NSArray *)tracks atIndexes:(NSIndexSet *)theseIndexesArentValidAnymore;

///----------------------------
/// @name Track Addition
///----------------------------

/** Called before one or more tracks are added to the playlist. 
 
 @warning *Important:* The index set passed to this method is not valid for the given tracks.
 
 @param aPlaylist The playlist to which tracks will be added.
 @param tracks The tracks that will be added.
 @param theseIndexesArentYetValid The (invalid, for now) destination indexes of the tracks.
 */
-(void)playlist:(SPPlaylist *)aPlaylist willAddTracks:(NSArray *)tracks atIndexes:(NSIndexSet *)theseIndexesArentYetValid;

/** Called after one or more tracks are added to the playlist. 
 
 @param aPlaylist The playlist in which tracks were added.
 @param tracks The tracks that were added.
 @param newIndexes The destination indexes of the tracks.
 */
-(void)playlist:(SPPlaylist *)aPlaylist didAddTracks:(NSArray *)tracks atIndexes:(NSIndexSet *)newIndexes;

///----------------------------
/// @name Track Reordering
///----------------------------

/** Called before one or more tracks are moved within the playlist. 
 
 @param aPlaylist The playlist in which tracks will be moved.
 @param tracks The tracks that will be moved.
 @param oldIndexes The current indexes of the tracks.
 @param newIndexes The (invalid, for now) indexes that the tracks will end up at.
 */
-(void)playlist:(SPPlaylist *)aPlaylist willMoveTracks:(NSArray *)tracks atIndexes:(NSIndexSet *)oldIndexes toIndexes:(NSIndexSet *)newIndexes;

/** Called after one or more tracks are moved within the playlist. 
 
 @param aPlaylist The playlist in which tracks will be moved.
 @param tracks The tracks that will be moved.
 @param oldIndexes The (invalid) old indexes of the tracks.
 @param newIndexes The now current indexes of the tracks.
 */
-(void)playlist:(SPPlaylist *)aPlaylist didMoveTracks:(NSArray *)tracks atIndexes:(NSIndexSet *)oldIndexes toIndexes:(NSIndexSet *)newIndexes;

@end