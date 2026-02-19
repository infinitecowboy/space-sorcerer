#ifndef CGSBridge_h
#define CGSBridge_h

#include <CoreFoundation/CoreFoundation.h>

extern int CGSMainConnectionID(void);
extern CFArrayRef _Nullable CGSCopyManagedDisplaySpaces(int cid) CF_RETURNS_RETAINED;
extern int CGSGetActiveSpace(int cid);

#endif /* CGSBridge_h */
