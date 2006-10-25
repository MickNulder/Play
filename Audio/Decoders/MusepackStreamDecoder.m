/*
 *  $Id$
 *
 *  Copyright (C) 2006 Stephen F. Booth <me@sbooth.org>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#import "MusepackStreamDecoder.h"

@implementation MusepackStreamDecoder

- (NSString *)		sourceFormatDescription			{ return [NSString stringWithFormat:@"%@, %u channels, %u Hz", NSLocalizedStringFromTable(@"Musepack", @"General", @""), [self pcmFormat].mChannelsPerFrame, (unsigned)[self pcmFormat].mSampleRate]; }

- (SInt64) seekToFrame:(SInt64)frame
{
	mpc_bool_t					result;
	
	result						= mpc_decoder_seek_sample(&_decoder, frame);
	
	if(YES != result) {
		return -1;
	}
	
	[[self pcmBuffer] reset]; 
	[self setCurrentFrame:frame];	
	
	return frame;	
}

- (BOOL) readProperties:(NSError **)error
{
	NSMutableDictionary				*propertiesDictionary;
	NSString						*path;
	FILE							*file;
	mpc_reader_file					reader_file;
	mpc_decoder						decoder;
	mpc_streaminfo					streaminfo;
	int								result;
	mpc_int32_t						intResult;
	mpc_bool_t						boolResult;
	
	path			= [[self valueForKey:@"url"] path];
	file			= fopen([path fileSystemRepresentation], "r");

	if(NULL == file) {
		if(nil != error) {
			NSMutableDictionary		*errorDictionary	= [NSMutableDictionary dictionary];
			
			[errorDictionary setObject:[NSString stringWithFormat:@"Unable to open the file \"%@\".", [path lastPathComponent]] forKey:NSLocalizedDescriptionKey];
			[errorDictionary setObject:@"Unable to open" forKey:NSLocalizedFailureReasonErrorKey];
			[errorDictionary setObject:@"The file may have been moved or you may not have read permission." forKey:NSLocalizedRecoverySuggestionErrorKey];						
			
			*error					= [NSError errorWithDomain:AudioStreamDecoderErrorDomain 
														  code:AudioStreamDecoderInputOutputError 
													  userInfo:errorDictionary];
		}
		
		return NO;
	}
		
	mpc_reader_setup_file_reader(&reader_file, file);
	
	// Get input file information
	mpc_streaminfo_init(&streaminfo);
	intResult		= mpc_streaminfo_read(&streaminfo, &reader_file.reader);

	if(ERROR_CODE_OK != intResult) {
		if(nil != error) {
			NSMutableDictionary		*errorDictionary	= [NSMutableDictionary dictionary];
			
			[errorDictionary setObject:[NSString stringWithFormat:@"The file \"%@\" is not a valid Musepack file.", [path lastPathComponent]] forKey:NSLocalizedDescriptionKey];
			[errorDictionary setObject:@"Not a Musepack file" forKey:NSLocalizedFailureReasonErrorKey];
			[errorDictionary setObject:@"The file's extension may not match the file's type." forKey:NSLocalizedRecoverySuggestionErrorKey];						
			
			*error					= [NSError errorWithDomain:AudioStreamDecoderErrorDomain 
														  code:AudioStreamDecoderFileFormatNotRecognizedError 
													  userInfo:errorDictionary];
		}

		result			= fclose(file);
		NSAssert1(EOF != result, @"Unable to close the input file (%s).", strerror(errno));	
		
		return NO;
	}
	
	// Set up the decoder
	mpc_decoder_setup(&decoder, &reader_file.reader);
	boolResult		= mpc_decoder_initialize(&decoder, &streaminfo);
	NSAssert(YES == boolResult, NSLocalizedStringFromTable(@"Unable to intialize the Musepack decoder.", @"Exceptions", @""));
	
	propertiesDictionary			= [NSMutableDictionary dictionary];
	
	[propertiesDictionary setValue:[NSString stringWithFormat:@"Musepack, %u channels, %u Hz", streaminfo.channels, streaminfo.sample_freq] forKey:@"formatName"];
	[propertiesDictionary setValue:[NSNumber numberWithLongLong:mpc_streaminfo_get_length_samples(&streaminfo)] forKey:@"totalFrames"];
//	[propertiesDictionary setValue:[NSNumber numberWithLong:bitrate] forKey:@"averageBitrate"];
//	[propertiesDictionary setValue:[NSNumber numberWithUnsignedInt:16] forKey:@"bitsPerChannel"];
	[propertiesDictionary setValue:[NSNumber numberWithUnsignedInt:streaminfo.channels] forKey:@"channelsPerFrame"];
	[propertiesDictionary setValue:[NSNumber numberWithUnsignedInt:streaminfo.sample_freq] forKey:@"sampleRate"];				
	
	[self setValue:propertiesDictionary forKey:@"properties"];
	
	result							= fclose(file);	
	NSAssert1(EOF != result, @"Unable to close the input file (%s).", strerror(errno));	
	
	return YES;
}

- (void) setupDecoder
{
	mpc_streaminfo					streaminfo;
	mpc_int32_t						intResult;
	mpc_bool_t						boolResult;
	
	_file							= fopen([[[self valueForKey:@"url"] path] fileSystemRepresentation], "r");
	NSAssert1(NULL != _file, @"Unable to open the input file (%s).", strerror(errno));	
	
	mpc_reader_setup_file_reader(&_reader_file, _file);
	
	// Get input file information
	mpc_streaminfo_init(&streaminfo);
	intResult						= mpc_streaminfo_read(&streaminfo, &_reader_file.reader);
	NSAssert(ERROR_CODE_OK == intResult, NSLocalizedStringFromTable(@"The file does not appear to be a valid Musepack file.", @"Exceptions", @""));
	
	// Set up the decoder
	mpc_decoder_setup(&_decoder, &_reader_file.reader);
	boolResult						= mpc_decoder_initialize(&_decoder, &streaminfo);
	NSAssert(YES == boolResult, NSLocalizedStringFromTable(@"Unable to intialize the Musepack decoder.", @"Exceptions", @""));
	
	[self setTotalFrames:mpc_streaminfo_get_length_samples(&streaminfo)];

	// Setup input format descriptor
	_pcmFormat.mFormatID			= kAudioFormatLinearPCM;
	_pcmFormat.mFormatFlags			= kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsBigEndian | kAudioFormatFlagIsPacked;
	
	_pcmFormat.mSampleRate			= streaminfo.sample_freq;
	_pcmFormat.mChannelsPerFrame	= streaminfo.channels;
	_pcmFormat.mBitsPerChannel		= 16;
	
	_pcmFormat.mBytesPerPacket		= (_pcmFormat.mBitsPerChannel / 8) * _pcmFormat.mChannelsPerFrame;
	_pcmFormat.mFramesPerPacket		= 1;
	_pcmFormat.mBytesPerFrame		= _pcmFormat.mBytesPerPacket * _pcmFormat.mFramesPerPacket;
}

- (void) cleanupDecoder
{
	int								result;
	
	result							= fclose(_file);
	_file							= NULL;
	
	NSAssert1(EOF != result, @"Unable to close the input file (%s).", strerror(errno));	
}

- (void) fillPCMBuffer
{
	CircularBuffer					*buffer			= [self pcmBuffer];
	unsigned						spaceRequired	= MPC_FRAME_LENGTH * [self pcmFormat].mChannelsPerFrame * ([self pcmFormat].mBitsPerChannel / 8);
	
	if(spaceRequired <= [buffer freeSpaceAvailable]) {
		MPC_SAMPLE_FORMAT		mpcBuffer			[MPC_DECODER_BUFFER_LENGTH];
		mpc_uint32_t			framesRead			= 0;
		unsigned				sample				= 0;
		
		// Decode the data
		framesRead		= mpc_decoder_decode(&_decoder, mpcBuffer, 0, 0);
		NSAssert((mpc_uint32_t)-1 != framesRead, NSLocalizedStringFromTable(@"Musepack decoding error.", @"Exceptions", @""));
		
#ifdef MPC_FIXED_POINT
#error "Fixed point not yet supported"
#else
		int32_t					audioSample			= 0;
		int8_t					*alias8				= NULL;
		int16_t					*alias16			= NULL;
		int32_t					*alias32			= NULL;
        int32_t					clipMin				= -1 << ([self pcmFormat].mBitsPerChannel - 1);
		int32_t					clipMax				= (1 << ([self pcmFormat].mBitsPerChannel - 1)) - 1;
		
		switch([self pcmFormat].mBitsPerChannel) {
			
			case 8:
				
				// No need for byte swapping
				alias8 = [buffer exposeBufferForWriting];
				for(sample = 0; sample < framesRead * [self pcmFormat].mChannelsPerFrame; ++sample) {
					audioSample		= mpcBuffer[sample] * (1 << 7);
					audioSample		= (audioSample < clipMin ? clipMin : (audioSample > clipMax ? clipMax : audioSample));
					*alias8++		= (int8_t)audioSample;
				}
					
				[buffer wroteBytes:framesRead * [self pcmFormat].mChannelsPerFrame * sizeof(int8_t)];
				
				break;
				
			case 16:
				
				// Convert to big endian byte order 
				alias16 = [buffer exposeBufferForWriting];
				for(sample = 0; sample < framesRead * [self pcmFormat].mChannelsPerFrame; ++sample) {
					audioSample		= mpcBuffer[sample] * (1 << 15);
					audioSample		= (audioSample < clipMin ? clipMin : (audioSample > clipMax ? clipMax : audioSample));
					*alias16++		= (int16_t)OSSwapHostToBigInt16(audioSample);
				}
					
				[buffer wroteBytes:framesRead * [self pcmFormat].mChannelsPerFrame * sizeof(int16_t)];
				
				break;
				
			case 24:
				
				// Convert to big endian byte order 
				alias8 = [buffer exposeBufferForWriting];
				for(sample = 0; sample < framesRead * [self pcmFormat].mChannelsPerFrame; ++sample) {
					audioSample		= mpcBuffer[sample] * (1 << 23);
					audioSample		= (audioSample < clipMin ? clipMin : (audioSample > clipMax ? clipMax : audioSample));
					audioSample		= OSSwapHostToBigInt32(audioSample);
					*alias8++		= (int8_t)(audioSample >> 16);
					*alias8++		= (int8_t)(audioSample >> 8);
					*alias8++		= (int8_t)audioSample;
				}
					
				[buffer wroteBytes:framesRead * [self pcmFormat].mChannelsPerFrame * 3 * sizeof(int8_t)];
				
				break;
				
			case 32:
				
				// Convert to big endian byte order 
				alias32 = [buffer exposeBufferForWriting];
				for(sample = 0; sample < framesRead * [self pcmFormat].mChannelsPerFrame; ++sample) {
					audioSample		= mpcBuffer[sample] * (1 << 31);
					audioSample		= (audioSample < clipMin ? clipMin : (audioSample > clipMax ? clipMax : audioSample));
					*alias32++		= OSSwapHostToBigInt32(audioSample);
				}
					
				[buffer wroteBytes:framesRead * [self pcmFormat].mChannelsPerFrame * sizeof(int32_t)];
				
				break;
				
			default:
				@throw [NSException exceptionWithName:@"IllegalInputException" reason:@"Sample size not supported" userInfo:nil]; 
				break;	
		}
#endif /* MPC_FIXED_POINT */
	}
}

@end