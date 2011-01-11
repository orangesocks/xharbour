#ifndef _NMEXPERT_H
#define _NMEXPERT_H

/* Microsoft Network Monitor Experts definitions */

#ifdef __cplusplus
extern "C" {
#endif

#define EXPERTSTRINGLENGTH  MAX_PATH
#define EXPERTGROUPNAMELENGTH  25

#define EXPERTENTRY_REGISTER  "Register"
#define EXPERTENTRY_CONFIGURE  "Configure"
#define EXPERTENTRY_RUN  "Run"

#define EXPERT_ENUM_FLAG_CONFIGURABLE  0x0001
#define EXPERT_ENUM_FLAG_VIEWER_PRIVATE  0x0002
#define EXPERT_ENUM_FLAG_NO_VIEWER  0x0004
#define EXPERT_ENUM_FLAG_ADD_ME_TO_RMC_IN_SUMMARY  0x0010
#define EXPERT_ENUM_FLAG_ADD_ME_TO_RMC_IN_DETAIL  0x0020

#define GET_SPECIFIED_FRAME  0
#define GET_FRAME_NEXT_FORWARD  1
#define GET_FRAME_NEXT_BACKWARD  2

#define FLAGS_DEFER_TO_UI_FILTER  0x1
#define FLAGS_ATTACH_PROPERTIES  0x2

#define EXPERTSUBSTATUS_ABORTED_USER  0x0001
#define EXPERTSUBSTATUS_ABORTED_LOAD_FAIL  0x0002
#define EXPERTSUBSTATUS_ABORTED_THREAD_FAIL  0x0004
#define EXPERTSUBSTATUS_ABORTED_BAD_ENTRY  0x0008

#define EXPERT_STARTUP_FLAG_USE_STARTUP_DATA_OVER_CONFIG_DATA  0x00000001

typedef LPVOID HEXPERTKEY, *PHEXPERTKEY;
typedef LPVOID HEXPERT, *PHEXPERT;
typedef LPVOID HRUNNINGEXPERT, *PHRUNNINGEXPERT;
typedef LPVOID HGROUP, *PHGROUP;

typedef struct _EXPERTENUMINFO *PEXPERTENUMINFO;
typedef struct _EXPERTCONFIG *PEXPERTCONFIG;
typedef struct _EXPERTSTARTUPINFO *PEXPERTSTARTUPINFO;

typedef BOOL (WINAPI *PEXPERTREGISTERPROC)(PEXPERTENUMINFO);
typedef BOOL (WINAPI *PEXPERTCONFIGPROC)(HEXPERTKEY,PEXPERTCONFIG*,PEXPERTSTARTUPINFO,DWORD,HWND);
typedef BOOL (WINAPI *PEXPERTRUNPROC)(HEXPERTKEY,PEXPERTCONFIG,PEXPERTSTARTUPINFO,DWORD,HWND);

typedef struct _EXPERTENUMINFO {
    char szName[EXPERTSTRINGLENGTH];
    char szVendor[EXPERTSTRINGLENGTH];
    char szDescription[EXPERTSTRINGLENGTH];
    DWORD Version;
    DWORD Flags;
    char szDllName[MAX_PATH];
    HEXPERT hExpert;
    HINSTANCE hModule;
    PEXPERTREGISTERPROC pRegisterProc;
    PEXPERTCONFIGPROC pConfigProc;
    PEXPERTRUNPROC pRunProc;
} EXPERTENUMINFO, *PEXPERTENUMINFO;

typedef struct {
    char szGroupName[EXPERTGROUPNAMELENGTH+1];
    HGROUP hGroup;
} GROUPINFO, *PGROUPINFO;

typedef struct _EXPERTSTARTUPINFO {
    DWORD Flags;
    HCAPTURE hCapture;
    char szCaptureFile[MAX_PATH];
    DWORD dwFrameNumber;
    HPROTOCOL hProtocol;
    LPPROPERTYINST lpPropertyInst;
    struct {
        BYTE BitNumber;
        BOOL bOn;
    } sBitfield;
} EXPERTSTARTUPINFO;

typedef struct _EXPERTCONFIG {
    DWORD RawConfigLength;
    BYTE RawConfigData[];
} EXPERTCONFIG, *PEXPERTCONFIG;

typedef struct {
    HEXPERT hExpert;
    DWORD StartupFlags;
    PEXPERTCONFIG pConfig;
} CONFIGUREDEXPERT, *PCONFIGUREDEXPERT;

typedef struct {
    DWORD FrameNumber;
    HFRAME hFrame;
    ULPFRAME pFrame;
    LPRECOGNIZEDATATABLE lpRecognizeDataTable;
    LPPROPERTYTABLE lpPropertyTable;
} EXPERTFRAMEDESCRIPTOR, *LPEXPERTFRAMEDESCRIPTOR;

typedef enum {
    EXPERTSTATUS_INACTIVE = 0,
    EXPERTSTATUS_STARTING,
    EXPERTSTATUS_RUNNING,
    EXPERTSTATUS_PROBLEM,
    EXPERTSTATUS_ABORTED,
    EXPERTSTATUS_DONE,
} EXPERTSTATUSENUMERATION;

typedef struct {
    EXPERTSTATUSENUMERATION Status;
    DWORD SubStatus;
    DWORD PercentDone;
    DWORD Frame;
    char szStatusText[EXPERTSTRINGLENGTH];
} EXPERTSTATUS, *PEXPERTSTATUS;

#ifdef __cplusplus
}
#endif

#endif /* _NMEXPERT_H */
