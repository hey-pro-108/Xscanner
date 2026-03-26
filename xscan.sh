#!/usr/bin/env bash


XSCANNER_BANNER()
{
    clear
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                    X S C A N N E R   v3.2                     ║"
    echo "║                    Malware Scanner for all                     ║"
    echo "║-----------------------------------------------------------------║"
    echo "║  Developed by: Hexa Dev                                        ║"
    echo "║  License: MIT                                                   ║"
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

    mkdir -p "$CONFIG_DIR" "$DATABASE_DIR" "$REPORT_DIR" "$TEMP_DIR" 2>/dev/null

    CONFIG_FILE="$CONFIG_DIR/settings.conf"

    if [ ! -f "$CONFIG_FILE" ]; then
        cat > "$CONFIG_FILE" << 'EOF2'
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
    elif grep -qi microsoft /proc/version 2>/dev/null; then
        PLATFORM="WSL"
    elif [ "$(uname)" = "Darwin" ]; then
        PLATFORM="MACOS"
    elif [ -f "/etc/os-release" ]; then
        PLATFORM="LINUX"
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

    # Header
    echo "SHA256|NAME|FAMILY|PLATFORM" > "$TEMP_DB"

    echo "[*] Downloading Windows malware signatures..."
    curl -s --connect-timeout 15 \
        "https://raw.githubusercontent.com/romainmarcoux/malicious-hash/main/full-hash-sha256-aa.txt" \
        -o "$TEMP_DIR/win.txt" 2>/dev/null
    WIN_COUNT=0
    if [ -f "$TEMP_DIR/win.txt" ] && [ -s "$TEMP_DIR/win.txt" ]; then
        
        grep -E '^[a-fA-F0-9]{64}' "$TEMP_DIR/win.txt" | head -10000 | \
        awk -F',' '{
            hash=$1
            name=(NF>1 ? $2 : "WindowsMalware")
            gsub(/[^a-zA-Z0-9_-]/, "", name)
            if(length(name)==0) name="WindowsMalware"
            name=substr(name,1,30)
            print hash "|" name "|WindowsMalware|WINDOWS"
        }' >> "$TEMP_DB"
        WIN_COUNT=$(grep -c "WINDOWS" "$TEMP_DB" 2>/dev/null || echo 0)
    fi
    echo "[✓] Windows: $WIN_COUNT signatures"

    echo "[*] Downloading Android malware signatures..."
    curl -s --connect-timeout 15 \
        "https://bazaar.abuse.ch/export/txt/sha256/recent/" \
        -o "$TEMP_DIR/android.txt" 2>/dev/null
    AND_COUNT=0
    if [ -f "$TEMP_DIR/android.txt" ] && [ -s "$TEMP_DIR/android.txt" ]; then
        grep -E '^[a-fA-F0-9]{64}' "$TEMP_DIR/android.txt" | head -5000 | \
        awk '{print $1 "|AndroidMalware|Android|ANDROID"}' >> "$TEMP_DB"
        AND_COUNT=$(grep -c "ANDROID" "$TEMP_DB" 2>/dev/null || echo 0)
    fi
    echo "[✓] Android: $AND_COUNT signatures"

    echo "[*] Downloading Linux malware signatures..."
    curl -s --connect-timeout 15 \
        "https://urlhaus.abuse.ch/downloads/text/" \
        -o "$TEMP_DIR/linux.txt" 2>/dev/null
    LIN_COUNT=0
    if [ -f "$TEMP_DIR/linux.txt" ] && [ -s "$TEMP_DIR/linux.txt" ]; then
        
        grep -E '^[a-fA-F0-9]{64}' "$TEMP_DIR/linux.txt" | head -3000 | \
        awk '{print $1 "|LinuxMalware|Linux|LINUX"}' >> "$TEMP_DB"
        LIN_COUNT=$(grep -c "LINUX" "$TEMP_DB" 2>/dev/null || echo 0)
    fi
    echo "[✓] Linux: $LIN_COUNT signatures"


    echo "[*] Downloading Cobalt Strike signatures..."
    curl -s --connect-timeout 15 \
        "https://raw.githubusercontent.com/Sentinel-One/CobaltStrikeParser/master/hashes.txt" \
        -o "$TEMP_DIR/cobalt.txt" 2>/dev/null
    CS_COUNT=0
    if [ -f "$TEMP_DIR/cobalt.txt" ] && [ -s "$TEMP_DIR/cobalt.txt" ]; then
        grep -E '^[a-fA-F0-9]{64}' "$TEMP_DIR/cobalt.txt" | head -1000 | \
        awk '{print $1 "|CobaltStrike|C2|CROSSPLATFORM"}' >> "$TEMP_DB"
        CS_COUNT=$(grep -c "CobaltStrike" "$TEMP_DB" 2>/dev/null || echo 0)
    fi
    echo "[✓] Cobalt Strike: $CS_COUNT signatures"

    
    echo "275a021bbfb6489e54d471899f7db9d1663fc695ec2fe2a2c4538aabf651fd0f|EICAR-Test|Test|CROSSPLATFORM" >> "$TEMP_DB"

    mv "$TEMP_DB" "$DATABASE_FILE"
    rm -f "$TEMP_DIR"/*.txt 2>/dev/null

    TOTAL=$(( $(wc -l < "$DATABASE_FILE") - 1 ))
    WIN_F=$(grep -c "WINDOWS" "$DATABASE_FILE" 2>/dev/null || echo 0)
    AND_F=$(grep -c "ANDROID" "$DATABASE_FILE" 2>/dev/null || echo 0)
    LIN_F=$(grep -c "LINUX" "$DATABASE_FILE" 2>/dev/null || echo 0)

    echo ""
    echo "-------------------------------------------------------------------"
    echo "  Windows: $WIN_F | Android: $AND_F | Linux: $LIN_F | Total: $TOTAL"
    echo "-------------------------------------------------------------------"
    echo "[✓] Signatures updated successfully"

    if [ "$TOTAL" -lt 10 ]; then
        echo "[!] WARNING: Very few signatures loaded. Check internet connection."
        echo "[!] Some GitHub source URLs may have changed. Try updating again later."
    fi
}

XSCANNER_SCAN_FILE()
{
    local file="$1"
    local db="$DATABASE_DIR/malware.db"
    local result=""

    [ ! -f "$file" ] && return

    FILE_HASH=$(sha256sum "$file" 2>/dev/null | cut -d' ' -f1)
    [ -z "$FILE_HASH" ] && return

    
    result=$(grep -F "${FILE_HASH}|" "$db" 2>/dev/null | head -1)

    if [ -n "$result" ]; then
        MAL_NAME=$(echo "$result" | cut -d'|' -f2)
        MAL_FAMILY=$(echo "$result" | cut -d'|' -f3)
        MAL_PLAT=$(echo "$result" | cut -d'|' -f4)
        echo "THREAT:${MAL_NAME}:${MAL_FAMILY}:${MAL_PLAT}"
    else
        echo "CLEAN"
    fi
}

XSCANNER_FAST_SCAN()
{
    TARGET="$1"

    if [ ! -e "$TARGET" ]; then
        echo "[!] Target not found: $TARGET"
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
        echo -n "[*] Scanning: $(basename "$TARGET") ... "
        RESULT=$(XSCANNER_SCAN_FILE "$TARGET")
        if [[ "$RESULT" == THREAT:* ]]; then
            THREAT=1
            MAL_NAME=$(echo "$RESULT" | cut -d':' -f2)
            MAL_PLAT=$(echo "$RESULT" | cut -d':' -f4)
            echo ""
            echo "[!!!] THREAT DETECTED: $MAL_NAME ($MAL_PLAT)"
        else
            echo "CLEAN"
        fi
    else
        
        echo -n "[*] Fast scanning"

        IFS=',' read -ra EXTS <<< "$SUSPECT_EXTS"

        for ext in "${EXTS[@]}"; do
            while IFS= read -r file; do
                [ $TOTAL -ge "$QUICK_LIMIT" ] && break 2
                TOTAL=$((TOTAL + 1))

                RESULT=$(XSCANNER_SCAN_FILE "$file")
                if [[ "$RESULT" == THREAT:* ]]; then
                    THREAT=$((THREAT + 1))
                    MAL_NAME=$(echo "$RESULT" | cut -d':' -f2)
                    echo ""
                    echo "[!!!] $(basename "$file") -> $MAL_NAME"
                fi

                [ $((TOTAL % 50)) -eq 0 ] && echo -n "."

            done < <(find "$TARGET" -type f -name "*${ext}" 2>/dev/null | head -"$QUICK_LIMIT")
        done
        echo ""
    fi

    echo ""
    echo "-------------------------------------------------------------------"
    echo "  Platform: $PLATFORM | Scanned: $TOTAL | Threats: $THREAT"
    echo "-------------------------------------------------------------------"

    if [ "$THREAT" -eq 0 ]; then
        echo ""
        echo "[✓] No threats detected"
    else
        echo ""
        echo "[!!!] $THREAT threat(s) detected"
        if command -v termux-notification >/dev/null 2>&1; then
            termux-notification --title "XScanner" --content "$THREAT threats found" 2>/dev/null
        fi
    fi
}

XSCANNER_DEEP_SCAN()
{
    TARGET="$1"

    if [ ! -d "$TARGET" ]; then
        echo "[!] Directory not found: $TARGET"
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

    {
        echo "XScanner Deep Scan Report"
        echo "Date: $(date)"
        echo "Target: $TARGET"
        echo "Platform: $PLATFORM"
        echo "----------------------------------------"
    } > "$REPORT"

    echo "[*] Deep scanning - this may take several minutes..."
    echo -n "[*] Progress"

    IFS=',' read -ra EXTS <<< "$SUSPECT_EXTS"

    for ext in "${EXTS[@]}"; do
        while IFS= read -r file; do
            [ $TOTAL -ge "$FULL_LIMIT" ] && break 2
            TOTAL=$((TOTAL + 1))

            RESULT=$(XSCANNER_SCAN_FILE "$file")
            if [[ "$RESULT" == THREAT:* ]]; then
                THREAT=$((THREAT + 1))
                MAL_NAME=$(echo "$RESULT" | cut -d':' -f2)
                MAL_FAMILY=$(echo "$RESULT" | cut -d':' -f3)
                MAL_PLAT=$(echo "$RESULT" | cut -d':' -f4)

                {
                    echo ""
                    echo "[THREAT] $file"
                    echo "  Malware : $MAL_NAME"
                    echo "  Family  : $MAL_FAMILY"
                    echo "  Platform: $MAL_PLAT"
                    echo "  SHA256  : $(sha256sum "$file" 2>/dev/null | cut -d' ' -f1)"
                } >> "$REPORT"

                echo ""
                echo "[!!!] $(basename "$file") -> $MAL_NAME ($MAL_PLAT)"
            fi

            [ $((TOTAL % 100)) -eq 0 ] && echo -n "."

        done < <(find "$TARGET" -type f -name "*${ext}" 2>/dev/null | head -"$FULL_LIMIT")
    done

    echo ""
    {
        echo ""
        echo "----------------------------------------"
        echo "Scanned: $TOTAL | Threats: $THREAT"
        echo "Date finished: $(date)"
    } >> "$REPORT"

    echo ""
    echo "-------------------------------------------------------------------"
    echo "  Platform: $PLATFORM | Scanned: $TOTAL | Threats: $THREAT"
    echo "  Report saved: $REPORT"
    echo "-------------------------------------------------------------------"

    if [ "$THREAT" -eq 0 ]; then
        echo ""
        echo "[✓] No threats detected"
    else
        echo ""
        echo "[!!!] $THREAT threat(s) detected - see report for details"
        if command -v termux-notification >/dev/null 2>&1; then
            termux-notification --title "XScanner Deep Scan" --content "$THREAT threats found" 2>/dev/null
        fi
    fi
}

XSCANNER_MAIN()
{
    while true; do
        XSCANNER_BANNER

        if [ ! -f "$DATABASE_DIR/malware.db" ]; then
            echo ""
            echo "[!] No database found. Running initial setup..."
            XSCANNER_UPDATE_SIGNATURES
        fi

        DB_SIZE=$(wc -l < "$DATABASE_DIR/malware.db" 2>/dev/null || echo 0)
        echo "  [Database: $((DB_SIZE - 1)) signatures loaded]"
        echo ""
        echo "-------------------------------------------------------------------"
        echo "  [1] Fast Scan  [2] Deep Scan  [3] Update  [4] Exit"
        echo "-------------------------------------------------------------------"
        echo -n "  Select: "
        read -r CHOICE

        case $CHOICE in
            1)
                echo ""
                echo -n "  Target [/sdcard/Download]: "
                read -r TARGET
                TARGET=${TARGET:-/sdcard/Download}
                XSCANNER_FAST_SCAN "$TARGET"
                echo ""
                echo -n "  Press Enter to continue..."
                read -r
                ;;
            2)
                echo ""
                echo -n "  Target [/sdcard]: "
                read -r TARGET
                TARGET=${TARGET:-/sdcard}
                XSCANNER_DEEP_SCAN "$TARGET"
                echo ""
                echo -n "  Press Enter to continue..."
                read -r
                ;;
            3)
                XSCANNER_UPDATE_SIGNATURES
                echo ""
                echo -n "  Press Enter to continue..."
                read -r
                ;;
            4)
                echo ""
                echo "  Exiting XScanner - Hexa Dev"
                echo ""
                exit 0
                ;;
            *)
                echo "  [!] Invalid option"
                sleep 1
                ;;
        esac
    done
}

# ── Entry Point ─────────────────────────────────────────────────────────────

XSCANNER_CONFIG
XSCANNER_DETECT_PLATFORM

if [ ! -f "$DATABASE_DIR/malware.db" ]; then
    XSCANNER_UPDATE_SIGNATURES
fi

if [ $# -eq 0 ]; then
    XSCANNER_MAIN
else
    XSCANNER_BANNER
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
            echo "  XScanner v3.2 - Malware Scanner by Hexa Dev"
            echo "  Usage: ./xscan.sh [OPTIONS] [PATH]"
            echo ""
            echo "  Options:"
            echo "    -f, --fast [path]   Fast scan (default: /sdcard/Download)"
            echo "    -d, --deep [path]   Deep scan (default: /sdcard)"
            echo "    -u, --update        Update signature database"
            echo "    -h, --help          Show this help"
            echo ""
            ;;
        *)
            echo "  [!] Unknown option: $1"
            echo "  Use -h for help"
            ;;
    esac
fi
