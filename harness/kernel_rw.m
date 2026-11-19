// Add at top of main()
FILE *log = fopen("/var/mobile/Containers/Data/Application/[YOUR-APP-ID]/Documents/exploit.log", "w");
if (log) {
    fprintf(log, "=== Exploit Starting ===\n");
    fflush(log);
}

// After each step:
if (log) {
    fprintf(log, "[*] Step 1: Getting IOSurface service...\n");
    fflush(log);
}

// If service fails:
if (!service) {
    if (log) {
        fprintf(log, "[-] Failed to get IOSurface service\n");
        fprintf(log, "[-] Error: IOKit access blocked by sandbox\n");
        fprintf(log, "[-] Need com.apple.private.iokit.allow entitlement\n");
        fclose(log);
    }
    return -1;
}
