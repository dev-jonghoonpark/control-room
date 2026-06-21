#ifndef CGSPRIVATE_H
#define CGSPRIVATE_H

#include <CoreFoundation/CoreFoundation.h>
#include <CoreGraphics/CoreGraphics.h>
#include <ApplicationServices/ApplicationServices.h>

// These are *private* Apple symbols living in SkyLight.framework (and the
// HIServices part of ApplicationServices). They are not part of the public SDK,
// can change between macOS releases, and disqualify an app from the App Store.
// They are exactly what Mission Control, yabai, AltTab, etc. rely on.

typedef int CGSConnectionID;
typedef int CGSSpaceID;

// The connection to the WindowServer for the current process.
CGSConnectionID SLSMainConnectionID(void);

// Array of dictionaries, one per display. Each contains:
//   "Display Identifier" -> CFString (display UUID, or "Main")
//   "Current Space"      -> CFDictionary with "ManagedSpaceID"
//   "Spaces"             -> CFArray of space dictionaries, each with
//                           "ManagedSpaceID" (CGSSpaceID), "id64", "uuid",
//                           "type" (0 = user desktop, 4 = fullscreen)
CF_RETURNS_RETAINED CFArrayRef SLSCopyManagedDisplaySpaces(CGSConnectionID cid);

// Window numbers (CFArray of CFNumber) living on the given spaces.
//   owner: 0 = any owner
//   spaces: CFArray of CFNumber space ids
//   options: 0x2 returns the windows currently on those spaces
CF_RETURNS_RETAINED CFArrayRef SLSCopyWindowsWithOptionsAndTags(
    CGSConnectionID cid, uint32_t owner, CFArrayRef spaces, uint32_t options,
    uint64_t *setTags, uint64_t *clearTags);

// Space ids (CFArray of CFNumber) that the given windows live on.
//   mask 0x7 = current | other | all
CF_RETURNS_RETAINED CFArrayRef SLSCopySpacesForWindows(
    CGSConnectionID cid, int mask, CFArrayRef windowIDs);

// Hardware-accelerated capture of the given window list. Returns a CFArray of
// CGImageRef (one per window). Works for windows on *other* spaces too,
// returning their last buffered frame. Requires Screen Recording permission.
//   options: bitmask, see CRCaptureOptions below.
CF_RETURNS_RETAINED CFArrayRef SLSHWCaptureWindowList(
    CGSConnectionID cid, uint32_t *windowList, int count, uint32_t options);

// Switch the given display to a different space (no animation).
void SLSManagedDisplaySetCurrentSpace(
    CGSConnectionID cid, CFStringRef display, CGSSpaceID space);

// Map an Accessibility window element back to its CGWindowID. Private HIServices.
AXError _AXUIElementGetWindow(AXUIElementRef element, uint32_t *identifier);

// Capture option bits used with SLSHWCaptureWindowList.
enum CRCaptureOptions {
    CRCaptureNominalResolution      = 0x0200,
    CRCaptureBestResolution         = 0x0400,
    CRCaptureIgnoreGlobalClipShape  = 0x0800,
};

#endif /* CGSPRIVATE_H */
