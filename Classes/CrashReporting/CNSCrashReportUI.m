/*
 * Author: Andreas Linde <mail@andreaslinde.de>
 *         Kent Sutherland
 *
 * Copyright (c) 2011 Andreas Linde & Kent Sutherland.
 * All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

#import "CNSCrashReportUI.h"
#import "CNSCrashReportManager.h"
#import <sys/sysctl.h>
#import <CrashReporter/CrashReporter.h>

@interface CNSCrashReportUI(private)
- (void) askCrashReportDetails;
- (void) endCrashReporter;
@end

const CGFloat kCommentsHeight = 105;
const CGFloat kDetailsHeight = 285;

@implementation CNSCrashReportUI

- (id)initWithManager:(CNSCrashReportManager *)crashReportManager crashReport:(NSString *)crashReport companyName:(NSString *)companyName applicationName:(NSString *)applicationName {
  
  self = [super initWithWindowNibName: @"CNSCrashReportUI"];
  
  if ( self != nil) {
    _xml = nil;
    _crashReportManager = crashReportManager;
    _crashLogContent = [crashReport copy];
    _companyName = [companyName copy];
    _applicationName = applicationName;
    [self setShowComments: YES];
    [self setShowDetails: NO];
    
    NSRect windowFrame = [[self window] frame];
    windowFrame.size = NSMakeSize(windowFrame.size.width, windowFrame.size.height - kDetailsHeight);
    windowFrame.origin.y -= kDetailsHeight;
    [[self window] setFrame: windowFrame
                    display: YES
                    animate: NO];
    
  }
  return self;  
}


- (void) endCrashReporter {
  [self close];
}


- (IBAction) showComments: (id) sender {
  NSRect windowFrame = [[self window] frame];
  
  if ([sender intValue]) {
    [self setShowComments: NO];
    
    windowFrame.size = NSMakeSize(windowFrame.size.width, windowFrame.size.height + kCommentsHeight);
    windowFrame.origin.y -= kCommentsHeight;
    [[self window] setFrame: windowFrame
                    display: YES
                    animate: YES];
    
    [self setShowComments: YES];
  } else {
    [self setShowComments: NO];
    
    windowFrame.size = NSMakeSize(windowFrame.size.width, windowFrame.size.height - kCommentsHeight);
    windowFrame.origin.y += kCommentsHeight;
    [[self window] setFrame: windowFrame
                    display: YES
                    animate: YES];
  }
}


- (IBAction) showDetails:(id)sender {
  NSRect windowFrame = [[self window] frame];
  
  windowFrame.size = NSMakeSize(windowFrame.size.width, windowFrame.size.height + kDetailsHeight);
  windowFrame.origin.y -= kDetailsHeight;
  [[self window] setFrame: windowFrame
                  display: YES
                  animate: YES];
  
  [self setShowDetails:YES];
  
}


- (IBAction) hideDetails:(id)sender {
  NSRect windowFrame = [[self window] frame];
  
  [self setShowDetails:NO];
  
  windowFrame.size = NSMakeSize(windowFrame.size.width, windowFrame.size.height - kDetailsHeight);
  windowFrame.origin.y += kDetailsHeight;
  [[self window] setFrame: windowFrame
                  display: YES
                  animate: YES];
}


- (IBAction) cancelReport:(id)sender {
  [self endCrashReporter];
  [NSApp stopModal];
  
  [_crashReportManager cancelReport];
}

- (void) _sendReportAfterDelay {
  NSString *notes = [NSString stringWithFormat:@"Comments:\n%@\n\nConsole:\n%@", [descriptionTextField stringValue], _consoleContent];
  
  [_crashReportManager sendReportCrash:_crashLogContent crashNotes:notes];
  [_crashLogContent release];
  _crashLogContent = nil;
}

- (IBAction) submitReport:(id)sender {
  [submitButton setEnabled:NO];
  
  [[self window] makeFirstResponder: nil];
  
  [self performSelector:@selector(_sendReportAfterDelay) withObject:nil afterDelay:0.01];
    
  [self endCrashReporter];
  [NSApp stopModal];
}


- (void) askCrashReportDetails {
  [[self window] setTitle:[NSString stringWithFormat:NSLocalizedString(@"Problem Report for %@", @"Window title"), _applicationName]];
  
  [[descriptionTextField cell] setPlaceholderString:NSLocalizedString(@"Please describe any steps needed to trigger the problem", @"User description placeholder")];
  [noteText setStringValue:NSLocalizedString(@"No personal information will be sent with this report.", @"Note text")];
  
  [crashLogTextView setString:[NSString stringWithFormat:@"%@", _crashLogContent]];
  
  
  NSBeep();
  [NSApp runModalForWindow:[self window]];
}


- (void)dealloc {
  [_crashLogContent release]; _crashLogContent = nil;
  [_consoleContent release]; _consoleContent = nil;
  [_companyName release]; _companyName = nil;
  _crashReportManager = nil;
  
  [super dealloc];
}


- (BOOL)showComments {
  return showComments;
}


- (void)setShowComments:(BOOL)value {
  showComments = value;
}


- (BOOL)showDetails {
  return showDetails;
}


- (void)setShowDetails:(BOOL)value {
  showDetails = value;
}

#pragma mark NSTextField Delegate

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector {
  BOOL commandHandled = NO;
  
  if (commandSelector == @selector(insertNewline:)) {
    [textView insertNewlineIgnoringFieldEditor:self];
    commandHandled = YES;
  }
  
  return commandHandled;
}

@end

