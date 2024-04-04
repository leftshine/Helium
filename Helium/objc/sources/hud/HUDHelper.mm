//
//  HUDHelper.mm
//  Helium
//
//  Created by Fuuko on 2024/3/27.
//

#import <mach-o/dyld.h>
#import <notify.h>
#import <objc/runtime.h>
#import <spawn.h>

#import "HUDHelper.h"

#import "AXEventRepresentation.h"
#import "BackboardServices.h"
#import "TSEventFetcher.h"
#import "UIApplication+Private.h"

extern "C" char **environ;

#define POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE 1
extern "C" int posix_spawnattr_set_persona_np(const posix_spawnattr_t *__restrict, uid_t, uint32_t);
extern "C" int posix_spawnattr_set_persona_uid_np(const posix_spawnattr_t *__restrict, uid_t);
extern "C" int posix_spawnattr_set_persona_gid_np(const posix_spawnattr_t *__restrict, uid_t);

BOOL IsHUDEnabled(void) {
    static char *executablePath = NULL;
    uint32_t executablePathSize = 0;

    _NSGetExecutablePath(NULL, &executablePathSize);
    executablePath = (char *)calloc(1, executablePathSize);
    _NSGetExecutablePath(executablePath, &executablePathSize);

    posix_spawnattr_t attr;
    posix_spawnattr_init(&attr);

    posix_spawnattr_set_persona_np(&attr, 99, POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE);
    posix_spawnattr_set_persona_uid_np(&attr, 0);
    posix_spawnattr_set_persona_gid_np(&attr, 0);

    pid_t task_pid;
    const char *args[] = {
        executablePath, "-check", NULL
    };
    posix_spawn(&task_pid, executablePath, NULL, &attr, (char **)args, environ);
    posix_spawnattr_destroy(&attr);

#if DEBUG
    os_log_debug(OS_LOG_DEFAULT, "spawned %{public}s -check pid = %{public}d", executablePath, task_pid);
#endif

    int status;
    do {
        if (waitpid(task_pid, &status, 0) != -1) {
#if DEBUG
            os_log_debug(OS_LOG_DEFAULT, "child status %d", WEXITSTATUS(status));
#endif
        }
    } while (!WIFEXITED(status) && !WIFSIGNALED(status));

    return WEXITSTATUS(status) != 0;
}

void SetHUDEnabled(BOOL isEnabled) {
#ifdef NOTIFY_DISMISSAL_HUD
    notify_post(NOTIFY_DISMISSAL_HUD);
#endif

    static char *executablePath = NULL;
    uint32_t executablePathSize = 0;
    _NSGetExecutablePath(NULL, &executablePathSize);
    executablePath = (char *)calloc(1, executablePathSize);
    _NSGetExecutablePath(executablePath, &executablePathSize);

    posix_spawnattr_t attr;
    posix_spawnattr_init(&attr);

    posix_spawnattr_set_persona_np(&attr, 99, POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE);
    posix_spawnattr_set_persona_uid_np(&attr, 0);
    posix_spawnattr_set_persona_gid_np(&attr, 0);

    if (isEnabled) {
        posix_spawnattr_setpgroup(&attr, 0);
        posix_spawnattr_setflags(&attr, POSIX_SPAWN_SETPGROUP);

        pid_t task_pid;
        const char *args[] = {
            executablePath, "-hud", NULL
        };
        posix_spawn(&task_pid, executablePath, NULL, &attr, (char **)args, environ);
        posix_spawnattr_destroy(&attr);

#if DEBUG
        os_log_debug(OS_LOG_DEFAULT, "spawned %{public}s -hud pid = %{public}d", executablePath, task_pid);
#endif
    } else {
        [NSThread sleepForTimeInterval:0.25];

        pid_t task_pid;
        const char *args[] = {
            executablePath, "-exit", NULL
        };
        posix_spawn(&task_pid, executablePath, NULL, &attr, (char **)args, environ);
        posix_spawnattr_destroy(&attr);

#if DEBUG
        os_log_debug(OS_LOG_DEFAULT, "spawned %{public}s -exit pid = %{public}d", executablePath, task_pid);
#endif

        int status;
        do {
            if (waitpid(task_pid, &status, 0) != -1) {
#if DEBUG
                os_log_debug(OS_LOG_DEFAULT, "child status %d", WEXITSTATUS(status));
#endif
            }
        } while (!WIFEXITED(status) && !WIFSIGNALED(status));
    }
}

void waitForNotification(void (^onFinish)(), BOOL isEnabled) {
    if (isEnabled) {
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

        int token;
        notify_register_dispatch(NOTIFY_LAUNCHED_HUD, &token, dispatch_get_main_queue(), ^(int token) {
            notify_cancel(token);
            dispatch_semaphore_signal(semaphore);
        });

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
            long timedOut = dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)));
            dispatch_async(dispatch_get_main_queue(), ^{
                if (timedOut) {
                    os_log_debug(OS_LOG_DEFAULT, "Timed out waiting for HUD to launch");
                }

                onFinish();
            });
        });
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            onFinish();
        });
    }
}

static __used
void _HUDEventCallback(void *target, void *refcon, IOHIDServiceRef service, IOHIDEventRef event) {
    static UIApplication *app = [UIApplication sharedApplication];

#if DEBUG
    os_log_debug(OS_LOG_DEFAULT, "_HUDEventCallback => %{public}@", event);
#endif

    // iOS 15.1+ has a new API for handling HID events.
    if (@available(iOS 15.1, *)) {
    } else {
        [app _enqueueHIDEvent:event];
    }

    BOOL shouldUseAXEvent = YES;  // Always use AX events now...

    BOOL isExactly15 = NO;
    static NSOperatingSystemVersion version = [[NSProcessInfo processInfo] operatingSystemVersion];

    if (version.majorVersion == 15 && version.minorVersion == 0 && version.patchVersion == 0) {
        isExactly15 = YES;
    }

    if (@available(iOS 15.0, *)) {
        shouldUseAXEvent = !isExactly15;
    } else {
        shouldUseAXEvent = NO;
    }

    if (shouldUseAXEvent) {
        static Class AXEventRepresentationCls = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [[NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/AccessibilityUtilities.framework"] load];
            AXEventRepresentationCls = objc_getClass("AXEventRepresentation");
        });

        AXEventRepresentation *rep = [AXEventRepresentationCls representationWithHIDEvent:event hidStreamIdentifier:@"UIApplicationEvents"];
#if DEBUG
        os_log_debug(OS_LOG_DEFAULT, "_HUDEventCallback => %{public}@", rep.handInfo);
#endif

        /* I don't like this. It's too hacky, but it works. */
        {
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                static UIWindow *keyWindow = nil;
                static dispatch_once_t onceToken;
                dispatch_once(&onceToken, ^{
                    keyWindow = [[app windows] firstObject];
                });

                UIView *keyView = [keyWindow hitTest:[rep location] withEvent:nil];

                UITouchPhase phase = UITouchPhaseEnded;

                if ([rep isTouchDown]) {
                    phase = UITouchPhaseBegan;
                } else if ([rep isMove]) {
                    phase = UITouchPhaseMoved;
                } else if ([rep isCancel]) {
                    phase = UITouchPhaseCancelled;
                } else if ([rep isLift] || [rep isInRange] || [rep isInRangeLift]) {
                    phase = UITouchPhaseEnded;
                }

                NSInteger pointerId = [[[[rep handInfo] paths] firstObject] pathIdentity];

                if (pointerId > 0) {
                    [TSEventFetcher receiveAXEventID:MIN(MAX(pointerId, 1), 98) atGlobalCoordinate:[rep location] withTouchPhase:phase inWindow:keyWindow onView:keyView];
                }
            });
        }
    }
}

static NSString *_cachesDirectoryPath = nil;
static NSString *_hudPIDFilePath = nil;
static NSString * GetPIDFilePath(void) {
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        _cachesDirectoryPath =
            [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
        _hudPIDFilePath = [_cachesDirectoryPath stringByAppendingPathComponent:@"hud.pid"];
    });
    return _hudPIDFilePath;
}

void runMainHUD() {
    pid_t pid = getpid();
    pid_t pgid = getgid();

    (void)pgid;
    #if DEBUG
    os_log_debug(OS_LOG_DEFAULT, "HUD pid %d, pgid %d", pid, pgid);
    #endif
    NSString *pidString = [NSString stringWithFormat:@"%d", pid];
    [pidString writeToFile:GetPIDFilePath()
                atomically:YES
                  encoding:NSUTF8StringEncoding
                     error:nil];

    [UIScreen initialize];
    CFRunLoopGetCurrent();

    GSInitialize();
    BKSDisplayServicesStart();
    UIApplicationInitialize();

    UIApplicationInstantiateSingleton(objc_getClass("HUDMainApplication"));
    static id<UIApplicationDelegate> appDelegate = [[objc_getClass("HUDMainApplicationDelegate") alloc] init];
    [UIApplication.sharedApplication setDelegate:appDelegate];
    [UIApplication.sharedApplication _accessibilityInit];

    [NSRunLoop currentRunLoop];
    BKSHIDEventRegisterEventCallback(_HUDEventCallback);

    if (@available(iOS 15.0, *)) {
        GSEventInitialize(0);
        GSEventPushRunLoopMode(kCFRunLoopDefaultMode);
    }

    [UIApplication.sharedApplication __completeAndRunAsPlugin];

    static int _springboardBootToken;
    notify_register_dispatch("SBSpringBoardDidLaunchNotification", &_springboardBootToken, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0l), ^(int token) {
        notify_cancel(token);

        // Re-enable HUD after SpringBoard is launched.
        SetHUDEnabled(YES);

        // Exit the current instance of HUD.
    #ifdef NOTIFY_DISMISSAL_HUD
        notify_post(NOTIFY_DISMISSAL_HUD);
    #endif
        kill(pid, SIGKILL);
    });

    CFRunLoopRun();
}
