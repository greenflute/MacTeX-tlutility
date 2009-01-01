//
//  TLMListOperation.m
//  TeX Live Manager
//
//  Created by Adam Maxwell on 12/22/08.
/*
 This software is Copyright (c) 2008
 Adam Maxwell. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 - Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 - Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in
 the documentation and/or other materials provided with the
 distribution.
 
 - Neither the name of Adam Maxwell nor the names of any
 contributors may be used to endorse or promote products derived
 from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "TLMListOperation.h"
#import "TLMPreferenceController.h"
#import "TLMOutputParser.h"
#import "TLMLogServer.h"

@interface TLMListOperation()
@property (readwrite, copy) NSURL *updateURL;
@end

@implementation TLMListOperation

@synthesize updateURL = _updateURL;

- (id)init
{
    NSAssert(0, @"Invalid initializer.  Location parameter is required.");
    return [self initWithLocation:nil];
}

- (id)initWithLocation:(NSURL *)location
{
    NSParameterAssert([location absoluteString]);
    NSMutableArray *options = [NSMutableArray arrayWithObjects:@"--location", [location absoluteString], @"list", nil];
    NSString *cmd = [[TLMPreferenceController sharedPreferenceController] tlmgrAbsolutePath];
    return [self initWithCommand:cmd options:options];
}

- (void)dealloc
{
    [_updateURL release];
    [_packageNodes release];
    [super dealloc];
}

- (void)_parseLines:(NSArray *)lines
{
    NSParameterAssert([self isFinished]);
    NSParameterAssert(nil == _packageNodes);
    
    NSMutableArray *packageLines = [[lines mutableCopy] autorelease];
    
    /*
     version 1: 
     tlmgr: installation location http://mirror.hmc.edu/ctan/systems/texlive/tlnet/2008
     */
    NSString *installPrefix = @"tlmgr: installation location ";
    if ([packageLines count] && [[packageLines objectAtIndex:0] hasPrefix:installPrefix]) {
        NSString *urlString = [[packageLines objectAtIndex:0] stringByReplacingOccurrencesOfString:installPrefix withString:@""];
        TLMLog(__func__, @"Using mirror at %@", urlString);
        [self setUpdateURL:[NSURL URLWithString:urlString]];
        [packageLines removeObjectAtIndex:0];
    }
    else if ([packageLines count]) {
        TLMLog(__func__, @"Expected prefix \"%@\" but actual line was:\n%@", installPrefix, [packageLines objectAtIndex:0]);
    }
    
    _packageNodes = [[TLMOutputParser nodesWithListLines:packageLines] copy];
}

- (NSArray *)packageNodes
{
    // return nil for cancelled or failed operations (prevents logging error messages)
    if (nil == _packageNodes && [self isFinished] && NO == [self isCancelled] && NO == [self failed]) {
        if ([[self outputData] length]) {
            NSString *outputString = [[NSString alloc] initWithData:[self outputData] encoding:NSUTF8StringEncoding];        
            NSArray *lines = [outputString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
            [outputString release];
            [self _parseLines:lines];
        }   
        else {
            TLMLog(__func__, @"No data read from standard output stream.");
        }
    }
    return _packageNodes;
}

@end
