#!/data/data/com.termux/files/usr/bin/bash

XSCANNER()
{
    clear
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                    X S C A N N E R   v3.1                      ║"
    echo "║                    Malware Scanner for all              ║"
    echo "║-----------------------------------------------------------------║"
    echo "║  Developed by: Hexa Dev                                        ║"
    echo "║  License: MIT                                                  ║"
    echo "║  Real-time Signatures | Multi-Platform Support                 ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo ""
}

XSCANNER_CONFIG()
{
    CONFIG_DIR="$HOME/xscanner"
    DATABASE_DIR="$CONFIG_DIR/database"
    REPORT_DIR="$CONFIG_DIR/reports"
    TEMP_DIR="$CONFIG_DIR/temp"
    
    mkdir -p $CONFIG_DIR $DATABASE_DIR $REPORT_DIR $TEMP_DIR 2>/dev/null
    
    CONFIG_FILE="$CONFIG_DIR/settings.conf"
    
    if [ ! -f "$CONFIG_FILE" ]; then
        cat > $CONFIG_FILE << 'EOF2'
MAX_FILE_SIZE=104857600
QUICK_SCAN_LIMIT=500
FULL_SCAN_LIMIT=5000
SUSPICIOUS_EXTENSIONS=.exe,.dll,.scr,.bat,.cmd,.vbs,.ps1,.msi,.jar,.elf,.sh,.py,.apk,.dex,.odex,.so,.bin,.run
EOF2
    fi
}

XSCANNER_DETECT_PLATFORM()
{
    if [ -d "/data/data/com.termux" ]; then
        PLATFORM="ANDROID"
    elif [ -f "/etc/os-release" ]; then
        PLATFORM="LINUX"
    elif [ "$(uname)" = "Darwin" ]; then
        PLATFORM="MACOS"
    elif grep -qi microsoft /proc/version 2>/dev/null; then
        PLATFORM="WSL"
    else
        PLATFORM="UNIX"
    fi
    echo "$PLATFORM" > "$TEMP_DIR/platform.tmp"
    echo "[✓] Platform: $PLATFORM"
}

XSCANNER_UPDATE_SIGNATURES()
{
    echo ""
    echo "-------------------------------------------------------------------"
    echo "         REAL-TIME SIGNATURE UPDATE FROM GITHUB"
    echo "-------------------------------------------------------------------"
    echo ""
    
    DATABASE_FILE="$DATABASE_DIR/malware.db"
    TEMP_DB="$TEMP_DIR/new_signatures.db"
    
    echo "SHA256|NAME|FAMILY|PLATFORM" > "$TEMP_DB"
    
    echo "[*] Downloading Windows malware signatures..."
    curl -s --connect-timeout 10 "https://raw.githubusercontent.com/ytisf/theZoo/master/malware_samples/sha256.txt" -o "$TEMP_DIR/win.txt" 2>/dev/null
    if [ -f "$TEMP_DIR/win.txt" ]; then
        grep -E '^[a-f0-9]{64}' "$TEMP_DIR/win.txt" | head -10000 | while read line; do
            hash_val=$(echo "$line" | cut -d',' -f1)
            name_val=$(echo "$line" | cut -d',' -f2 | cut -d'_' -f1 | cut -c1-30)
            echo "$hash_val|$name_val|WindowsMalware|WINDOWS" >> "$TEMP_DB"
        done
        echo "[✓] Windows: $(grep -c "WINDOWS" "$TEMP_DB") signatures"
    fi
    
    echo "[*] Downloading Android malware signatures..."
    curl -s --connect-timeout 10 "https://raw.githubusercontent.com/ashishb/android-malware/master/malware_hashes.txt" -o "$TEMP_DIR/android.txt" 2>/dev/null
    if [ -f "$TEMP_DIR/android.txt" ]; then
        grep -E '^[a-f0-9]{64}' "$TEMP_DIR/android.txt" | head -5000 | while read hash_val; do
            echo "$hash_val|AndroidMalware|Android|ANDROID" >> "$TEMP_DB"
        done
        echo "[✓] Android: $(grep -c "ANDROID" "$TEMP_DB") signatures"
    fi
    
    echo "[*] Downloading Linux malware signatures..."
    curl -s --connect-timeout 10 "https://raw.githubusercontent.com/Neo23x0/signature-base/master/iocs/sha256-apt-iocs.txt" -o "$TEMP_DIR/linux.txt" 2>/dev/null
    if [ -f "$TEMP_DIR/linux.txt" ]; then
        grep -E '^[a-f0-9]{64}' "$TEMP_DIR/linux.txt" | head -3000 | while read hash_val; do
            echo "$hash_val|LinuxMalware|Linux|LINUX" >> "$TEMP_DB"
        done
        echo "[✓] Linux: $(grep -c "LINUX" "$TEMP_DB") signatures"
    fi
    
    echo "[*] Downloading cross-platform threat intelligence..."
    curl -s --connect-timeout 10 "https://raw.githubusercontent.com/Sentinel-One/CobaltStrikeParser/master/hashes.txt" -o "$TEMP_DIR/cobalt.txt" 2>/dev/null
    if [ -f "$TEMP_DIR/cobalt.txt" ]; then
        grep -E '^[a-f0-9]{64}' "$TEMP_DIR/cobalt.txt" | head -1000 | while read hash_val; do
            echo "$hash_val|CobaltStrike|C2|CROSSPLATFORM" >> "$TEMP_DB"
        done
        echo "[✓] Cobalt Strike signatures loaded"
    fi
    
    echo "275a021bbfb6489e54d471899f7db9d1663fc695ec2fe2a2c4538aabf651fd0f|EICAR-Test|Test|CROSSPLATFORM" >> "$TEMP_DB"
    echo "44d88612fea8a8f36de82e1278abb02f|EICAR-MD5|Test|CROSSPLATFORM" >> "$TEMP_DB"
    
    mv "$TEMP_DB" "$DATABASE_FILE"
    rm -f "$TEMP_DIR"/*.txt
    
    TOTAL=$(($(wc -l < "$DATABASE_FILE") - 1))
    WIN=$(grep -c "WINDOWS" "$DATABASE_FILE")
    AND=$(grep -c "ANDROID" "$DATABASE_FILE")
    LIN=$(grep -c "LINUX" "$DATABASE_FILE")
    
    echo ""
    echo "-------------------------------------------------------------------"
    echo "  Windows: $WIN | Android: $AND | Linux: $LIN | Total: $TOTAL"
    echo "-------------------------------------------------------------------"
    echo "[✓] Signatures updated from GitHub"
}

XSCANNER_FAST_SCAN()
{
    TARGET="$1"
    
    if [ ! -e "$TARGET" ]; then
        echo "[!] Target not found"
        return 1
    fi
    
    echo ""
    echo "-------------------------------------------------------------------"
    echo "              FAST SCAN MODE - Maximum Speed"
    echo "-------------------------------------------------------------------"
    echo ""
    
    TOTAL=0
    THREAT=0
    
    QUICK_LIMIT=$(grep QUICK_SCAN_LIMIT "$CONFIG_FILE" | cut -d'=' -f2)
    SUSPECT_EXTS=$(grep SUSPICIOUS_EXTENSIONS "$CONFIG_FILE" | cut -d'=' -f2)
    PLATFORM=$(cat "$TEMP_DIR/platform.tmp" 2>/dev/null)
    
    if [ -f "$TARGET" ]; then
        TOTAL=1
        echo -n "[*] Scanning: $(basename "$TARGET") "
        
        FILE_HASH=$(sha256sum "$TARGET" 2>/dev/null | cut -d' ' -f1)
        MATCH=$(grep "$FILE_HASH" "$DATABASE_DIR/malware.db" 2>/dev/null | head -1)
        
        if [ -n "$MATCH" ]; then
            THREAT=1
            MAL_NAME=$(echo "$MATCH" | cut -d'|' -f2)
            MAL_PLAT=$(echo "$MATCH" | cut -d'|' -f4)
            echo ""
            echo "[!!!] THREAT: $MAL_NAME ($MAL_PLAT)"
        else
            echo "CLEAN"
        fi
    else
        echo -n "[*] Fast scanning"
        
        IFS=',' read -ra EXTS <<< "$SUSPECT_EXTS"
        
        for ext in "${EXTS[@]}"; do
            while IFS= read -r file; do
                TOTAL=$((TOTAL + 1))
                
                if [ $TOTAL -gt $QUICK_LIMIT ]; then
                    break 2
                fi
                
                FILE_HASH=$(sha256sum "$file" 2>/dev/null | cut -d' ' -f1)
                MATCH=$(grep "$FILE_HASH" "$DATABASE_DIR/malware.db" 2>/dev/null | head -1)
                
                if [ -n "$MATCH" ]; then
                    THREAT=$((THREAT + 1))
                    MAL_NAME=$(echo "$MATCH" | cut -d'|' -f2)
                    echo ""
                    echo "[!!!] $(basename "$file") -> $MAL_NAME"
                fi
                
                if [ $((TOTAL % 50)) -eq 0 ]; then
                    echo -n "."
                fi
                
            done < <(find "$TARGET" -type f \( -name "*$ext" \) 2>/dev/null | head -$QUICK_LIMIT)
        done
        
        echo ""
    fi
    
    echo ""
    echo "-------------------------------------------------------------------"
    echo "  Platform: $PLATFORM | Scanned: $TOTAL | Threats: $THREAT"
    echo "-------------------------------------------------------------------"
    
    if [ $THREAT -eq 0 ]; then
        echo ""
        echo "[✓] No threats detected"
    else
        echo ""
        echo "[!!!] $THREAT threats detected"
        if command -v termux-notification >/dev/null 2>&1; then
            termux-notification --title "XScanner" --content "$THREAT threats found" 2>/dev/null
        fi
    fi
}

XSCANNER_DEEP_SCAN()
{
    TARGET="$1"
    
    if [ ! -d "$TARGET" ]; then
        echo "[!] Directory not found"
        return 1
    fi
    
    echo ""
    echo "-------------------------------------------------------------------"
    echo "              DEEP SCAN MODE - Maximum Detection"
    echo "-------------------------------------------------------------------"
    echo ""
    
    REPORT="$REPORT_DIR/deep_scan_$(date +%Y%m%d_%H%M%S).log"
    
    TOTAL=0
    THREAT=0
    
    FULL_LIMIT=$(grep FULL_SCAN_LIMIT "$CONFIG_FILE" | cut -d'=' -f2)
    SUSPECT_EXTS=$(grep SUSPICIOUS_EXTENSIONS "$CONFIG_FILE" | cut -d'=' -f2)
    PLATFORM=$(cat "$TEMP_DIR/platform.tmp" 2>/dev/null)
    
    echo "XScanner Deep Scan Report" > "$REPORT"
    echo "Date: $(date)" >> "$REPORT"
    echo "Target: $TARGET" >> "$REPORT"
    echo "Platform: $PLATFORM" >> "$REPORT"
    echo "----------------------------------------" >> "$REPORT"
    
    echo "[*] Deep scanning - this may take several minutes"
    echo -n "[*] Progress"
    
    IFS=',' read -ra EXTS <<< "$SUSPECT_EXTS"
    
    for ext in "${EXTS[@]}"; do
        while IFS= read -r file; do
            TOTAL=$((TOTAL + 1))
            
            if [ $TOTAL -gt $FULL_LIMIT ]; then
                break 2
            fi
            
            FILE_HASH=$(sha256sum "$file" 2>/dev/null | cut -d' ' -f1)
            MATCH=$(grep "$FILE_HASH" "$DATABASE_DIR/malware.db" 2>/dev/null | head -1)
            
            if [ -n "$MATCH" ]; then
                THREAT=$((THREAT + 1))
                MAL_NAME=$(echo "$MATCH" | cut -d'|' -f2)
                MAL_FAMILY=$(echo "$MATCH" | cut -d'|' -f3)
                MAL_PLAT=$(echo "$MATCH" | cut -d'|' -f4)
                
                echo "" >> "$REPORT"
                echo "[THREAT] $file" >> "$REPORT"
                echo "  Malware: $MAL_NAME" >> "$REPORT"
                echo "  Family: $MAL_FAMILY" >> "$REPORT"
                echo "  Platform: $MAL_PLAT" >> "$REPORT"
                
                echo ""
                echo "[!!!] $(basename "$file") -> $MAL_NAME"
            fi
            
            if [ $((TOTAL % 100)) -eq 0 ]; then
                echo -n "."
            fi
            
        done < <(find "$TARGET" -type f -name "*$ext" 2>/dev/null | head -$FULL_LIMIT)
    done
    
    echo ""
    echo "" >> "$REPORT"
    echo "----------------------------------------" >> "$REPORT"
    echo "Scanned: $TOTAL | Threats: $THREAT" >> "$REPORT"
    
    echo ""
    echo "-------------------------------------------------------------------"
    echo "  Platform: $PLATFORM | Scanned: $TOTAL | Threats: $THREAT"
    echo "  Report: $REPORT"
    echo "-------------------------------------------------------------------"
    
    if [ $THREAT -eq 0 ]; then
        echo ""
        echo "[✓] No threats detected"
    else
        echo ""
        echo "[!!!] $THREAT threats detected"
        if command -v termux-notification >/dev/null 2>&1; then
            termux-notification --title "XScanner Deep Scan" --content "$THREAT threats found" 2>/dev/null
        fi
    fi
}

XSCANNER_MAIN()
{
    while true; do
        XSCANNER
        
        if [ ! -f "$DATABASE_DIR/malware.db" ]; then
            echo ""
            echo "[!] No database found. Running setup..."
            XSCANNER_UPDATE_SIGNATURES
        fi
        
        echo ""
        echo "-------------------------------------------------------------------"
        echo "  [1] Fast Scan  [2] Deep Scan  [3] Update  [4] Exit"
        echo "-------------------------------------------------------------------"
        echo -n "  Select: "
        read CHOICE
        
        case $CHOICE in
            1)
                echo ""
                echo -n "Target [/sdcard/Download]: "
                read TARGET
                TARGET=${TARGET:-/sdcard/Download}
                XSCANNER_FAST_SCAN "$TARGET"
                echo ""
                echo -n "Press Enter"
                read
                ;;
            2)
                echo ""
                echo -n "Target [/sdcard]: "
                read TARGET
                TARGET=${TARGET:-/sdcard}
                XSCANNER_DEEP_SCAN "$TARGET"
                echo ""
                echo -n "Press Enter"
                read
                ;;
            3)
                XSCANNER_UPDATE_SIGNATURES
                echo ""
                echo -n "Press Enter"
                read
                ;;
            4)
                echo ""
                echo "Exiting XScanner - Hexa Dev"
                exit 0
                ;;
            *)
                echo "Invalid"
                sleep 1
                ;;
        esac
    done
}

XSCANNER_CONFIG
XSCANNER_DETECT_PLATFORM

if [ ! -f "$DATABASE_DIR/malware.db" ]; then
    XSCANNER_UPDATE_SIGNATURES
fi

if [ $# -eq 0 ]; then
    XSCANNER_MAIN
else
    XSCANNER
    case $1 in
        -f|--fast)
            TARGET="${2:-/sdcard/Download}"
            XSCANNER_FAST_SCAN "$TARGET"
            ;;
        -d|--deep)
            TARGET="${2:-/sdcard}"
            XSCANNER_DEEP_SCAN "$TARGET"
            ;;
        -u|--update)
            XSCANNER_UPDATE_SIGNATURES
            ;;
        -h|--help)
            echo ""
            echo "XScanner v3.1 - Malware Scanner"
            echo "Usage: ./xscan.sh [OPTIONS]"
            echo "  -f, --fast [path]   Fast scan"
            echo "  -d, --deep [path]   Deep scan"
            echo "  -u, --update        Update signatures"
            echo ""
            ;;
        *)
            echo "Use -h for help"
            ;;
    esac
fi
