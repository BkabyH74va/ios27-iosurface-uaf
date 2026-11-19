// kernel_rw.m
// iOS 27.0.1 Kernel Exploit

#import <Foundation/Foundation.h>
#import <IOKit/IOKitLib.h>

int main(int argc, char *argv[]) {
    @autoreleasepool {
        NSLog(@"=== iOS 27.0.1 Kernel Exploit ===");
        NSLog(@"[*] Starting...");
        
        io_service_t service = IOServiceGetMatchingService(kIOMainPortDefault,
            IOServiceMatching("IOSurfaceRoot"));
        
        if (!service) {
            NSLog(@"[-] Failed to find IOSurfaceRoot");
            return -1;
        }
        NSLog(@"[+] Found IOSurfaceRoot");
        
        io_connect_t connect = 0;
        kern_return_t kr = IOServiceOpen(service, mach_task_self(), 0, &connect);
        if (kr != KERN_SUCCESS) {
            NSLog(@"[-] Failed to open: 0x%x", kr);
            return -1;
        }
        NSLog(@"[+] Opened connection");
        
        // Create test surface
        NSDictionary *props = @{
            @"IOSurfaceWidth": @64,
            @"IOSurfaceHeight": @64,
            @"IOSurfacePixelFormat": @(0x42475241),
            @"IOSurfaceAllocSize": @16384
        };
        
        uint64_t input[3] = {0};
        input[0] = (uint64_t)(__bridge void *)props;
        uint64_t output[1] = {0};
        uint32_t outputCnt = 1;
        
        kr = IOConnectCallMethod(connect, 0, input, 3, NULL, 0, output, &outputCnt, NULL, NULL);
        
        if (kr == KERN_SUCCESS) {
            NSLog(@"[+] Created surface: ID=%u", (uint32_t)output[0]);
        } else {
            NSLog(@"[-] Failed: 0x%x", kr);
        }
        
        IOServiceClose(connect);
        NSLog(@"[*] Done");
        return 0;
    }
}
