/* History.m
 *  
 * Copyright (C) 2003 Free Software Foundation, Inc.
 *
 * Author: Enrico Sersale <enrico@imago.ro>
 * Date: August 2001
 *
 * This file is part of the GNUstep GWorkspace application
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include "History.h"
#include "GWViewersManager.h"
#include "GWFunctions.h"
#include "GNUstep.h"

@implementation History

- (void)dealloc
{
  RELEASE (win);
  [super dealloc];
}

- (id)init
{
	self = [super init];
  
  if (self) {
		NSSize ms;
	  unsigned int style = NSTitledWindowMask | NSClosableWindowMask				
							                                    | NSResizableWindowMask;

	  win = [[NSWindow alloc] initWithContentRect: NSZeroRect
						  styleMask: style backing: NSBackingStoreBuffered defer: YES];

    if ([win setFrameUsingName: @"History"] == NO) {
      [win setFrame: NSMakeRect(100, 100, 250, 400) display: NO];
    }            

    [win setTitle: NSLocalizedString(@"History",@"")];
    [win setReleasedWhenClosed: NO]; 
    [win setDelegate: self];

  	scrollView = [NSScrollView new];
    [scrollView setBorderType: NSBezelBorder];
    [scrollView setHasHorizontalScroller: YES];
    [scrollView setHasVerticalScroller: YES]; 
  	[scrollView setAutoresizingMask: (NSViewWidthSizable | NSViewHeightSizable)];
		[scrollView setFrame: [[win contentView] frame]];
    [win setContentView: scrollView];
    RELEASE (scrollView);
    
    matrix = [[NSMatrix alloc] initWithFrame: NSMakeRect(0, 0, 100, 100)
				            	                mode: NSRadioModeMatrix 
                                 prototype: [[NSBrowserCell new] autorelease]
			       						      numberOfRows: 0 
                           numberOfColumns: 0];
    [matrix setTarget: self];
    [matrix setDoubleAction: @selector(matrixAction:)];
    [matrix setIntercellSpacing: NSZeroSize];
    ms.width = [[scrollView contentView] frame].size.width;
    ms.height = [[NSFont systemFontOfSize: 12] defaultLineHeightForFont];
    [matrix setCellSize: ms];
    [matrix setAutoscroll: YES];
	  [matrix setAllowsEmptySelection: YES];
	  [scrollView setDocumentView: matrix];	
    RELEASE (matrix);

		viewer = nil;
  }

  return self;
}

- (void)activate
{
	[win makeKeyAndOrderFront: nil];
}

- (void)setViewer:(id)aviewer
{
	viewer = aviewer;
}

- (id)viewer
{
	return viewer;
}

- (void)setHistoryNodes:(NSArray *)nodes
{
	int i;
	  	    
  while (1) {
    if ([[matrix cells] count] == 0) {
      break;
    }
    [matrix removeRow: 0];
  }
	  
	if ((nodes == nil) || ([nodes count] == 0)) {
		[matrix sizeToCells];
		if ([win isVisible]) {
  		[matrix setNeedsDisplay: YES];  
		}
		return;
	}

  for (i = 0; i < [nodes count]; i++) {
    FSNode *node = [nodes objectAtIndex: i];
		NSString *base = [node parentPath];		
		NSString *name = [node name];
		NSString *title = [NSString stringWithFormat: @"%@ - %@", name, base];
    id cell;

    [matrix insertRow: i];
    cell = [matrix cellAtRow: i column: 0];  
    [cell setTitle: title];
    [cell setLeaf: YES]; 
	}

	[self setMatrixWidth];
	[matrix sizeToCells];
	
	if ([win isVisible]) {
  	[matrix setNeedsDisplay: YES];  
	}
}

- (void)setHistoryPosition:(int)position
{
  if ((position >= 0) && (position < [[matrix cells] count])) {
    NSRect rect = [matrix cellFrameAtRow: position column: 0];
	  rect = NSMakeRect(rect.origin.x, rect.origin.y, 10, 10);
	  [matrix scrollRectToVisible: rect];	
	  [matrix selectCellAtRow: position column: 0];
  }
}

- (void)setHistoryNodes:(NSArray *)nodes
               position:(int)position
{
	[self setHistoryNodes: nodes];
	[self setHistoryPosition: position];
}

- (void)matrixAction:(id)sender
{
	if (viewer) {
	  int row, col;

	  [matrix getRow: &row column: &col ofCell: [matrix selectedCell]];

    [[GWViewersManager viewersManager] viewer: viewer 
                          goToHistoryPosition: row];
	}
}

- (void)setMatrixWidth
{
	NSFont *font = [NSFont systemFontOfSize: 12];
	NSArray *cells = [matrix cells];
	float mh = [matrix cellSize].height;
	float maxw = [[scrollView contentView] frame].size.width;
	int i;
	
	for (i = 0; i < [cells count]; i++) {
		NSString *s = [[cells objectAtIndex: i] stringValue];
		float w = [font widthOfString: s] + 10;
		maxw = (maxw < w) ? w : maxw;
	}
	
  if ([matrix cellSize].width != maxw) {
	  [matrix setCellSize: NSMakeSize(maxw, mh)];
  }
}

- (void)updateDefaults
{
	if ([win isVisible]) {
		[win saveFrameUsingName: @"History"];
	}
}

- (NSWindow *)myWin
{
	return win;
}

- (void)windowDidResize:(NSNotification *)aNotification
{
	if ([aNotification object] == win) {
		[self setMatrixWidth];
	}
}

- (BOOL)windowShouldClose:(id)sender
{
  [self updateDefaults];
	return YES;
}

@end
