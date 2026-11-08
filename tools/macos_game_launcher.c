#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/hid/IOHIDManager.h>
#include <mach-o/dyld.h>
#include <errno.h>
#include <limits.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static bool microbit_connected(void) {
    IOHIDManagerRef manager = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);
    if (!manager) return false;
    CFMutableDictionaryRef query = CFDictionaryCreateMutable(kCFAllocatorDefault, 0,
        &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    int vendor = 0x1209, product = 0x0001;
    CFNumberRef vid = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &vendor);
    CFNumberRef pid = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &product);
    CFDictionarySetValue(query, CFSTR(kIOHIDVendorIDKey), vid);
    CFDictionarySetValue(query, CFSTR(kIOHIDProductIDKey), pid);
    IOHIDManagerSetDeviceMatching(manager, query);
    bool found = false;
    if (IOHIDManagerOpen(manager, kIOHIDOptionsTypeNone) == kIOReturnSuccess) {
        CFSetRef devices = IOHIDManagerCopyDevices(manager);
        if (devices) {
            CFIndex count = CFSetGetCount(devices);
            const void **items = calloc((size_t)count, sizeof(void *));
            if (items) {
                CFSetGetValues(devices, items);
                for (CFIndex index = 0; index < count; ++index) {
                    CFTypeRef name = IOHIDDeviceGetProperty((IOHIDDeviceRef)items[index], CFSTR(kIOHIDProductKey));
                    if (name && CFGetTypeID(name) == CFStringGetTypeID() &&
                        CFStringFind((CFStringRef)name, CFSTR("micro:bit"), kCFCompareCaseInsensitive).location != kCFNotFound) {
                        found = true;
                        break;
                    }
                }
                free(items);
            }
            CFRelease(devices);
        }
        IOHIDManagerClose(manager, kIOHIDOptionsTypeNone);
    }
    CFRelease(pid);
    CFRelease(vid);
    CFRelease(query);
    CFRelease(manager);
    return found;
}

static bool load_mapping(const char *directory) {
    char path[PATH_MAX];
    if (snprintf(path, sizeof(path), "%s/../Resources/microbit-gamepad-macos.txt", directory) >= (int)sizeof(path)) return false;
    FILE *file = fopen(path, "r");
    if (!file) return false;
    char mapping[2048];
    bool loaded = fgets(mapping, sizeof(mapping), file) != NULL;
    fclose(file);
    if (!loaded) return false;
    mapping[strcspn(mapping, "\r\n")] = '\0';
    if (!mapping[0]) return false;
    const char *existing = getenv("SDL_GAMECONTROLLERCONFIG");
    size_t length = strlen(mapping) + (existing ? strlen(existing) : 0) + 2;
    char *combined = malloc(length);
    if (!combined) return false;
    if (existing && existing[0]) snprintf(combined, length, "%s\n%s", existing, mapping);
    else snprintf(combined, length, "%s", mapping);
    loaded = setenv("SDL_GAMECONTROLLERCONFIG", combined, 1) == 0;
    free(combined);
    return loaded;
}

int main(int argc, char **argv) {
    char executable[PATH_MAX], resolved[PATH_MAX], directory[PATH_MAX], engine[PATH_MAX];
    uint32_t size = sizeof(executable);
    if (_NSGetExecutablePath(executable, &size) != 0 || !realpath(executable, resolved)) return 126;
    if (snprintf(engine, sizeof(engine), "%s.engine", resolved) >= (int)sizeof(engine)) return 126;
    snprintf(directory, sizeof(directory), "%s", resolved);
    char *slash = strrchr(directory, '/');
    if (!slash) return 126;
    *slash = '\0';
    bool detected = microbit_connected();
    bool mapped = false;
    if (detected) {
        setenv("SDL_JOYSTICK_MFI", "0", 1);
        mapped = load_mapping(directory);
    }
    if (argc == 2 && strcmp(argv[1], "--microbit-bootstrap-check") == 0) {
        printf("microbit_detected=%s mapping_loaded=%s\n", detected ? "true" : "false", mapped ? "true" : "false");
        return detected && !mapped ? 1 : 0;
    }
    argv[0] = engine;
    execv(engine, argv);
    fprintf(stderr, "Unable to start The Sleeping Grove: %s\n", strerror(errno));
    return 126;
}
