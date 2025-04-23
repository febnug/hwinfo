#!/bin/bash

echo "====================================="
echo "        HARDWARE INFO CHECKER        "
echo "====================================="
echo ""

### CEK CPU UTAMA
echo "🧩 INFO CPU"
echo "-----------------------------"

if command -v lscpu &> /dev/null; then
    lscpu | grep -E "Model name|Socket|Thread|Core(s)|CPU\(s\)" | sed 's/^[ \t]*//'
else
    echo "Perintah lscpu tidak tersedia."
fi

### CEK SUHU CPU (jika tersedia)
echo ""
echo "🌡️  INFO SUHU CPU"
echo "-----------------------------"

if command -v sensors &> /dev/null; then
    sensors 
else
    echo "Perintah sensors tidak tersedia atau sensor tidak terdeteksi."
    echo "Coba install dengan: sudo pacman -S lm_sensors && sudo sensors-detect"
fi

### CEK RAM (via dmidecode)
echo ""
echo "🧠 INFO RAM"
echo "-----------------------------"

if ! command -v dmidecode &> /dev/null; then
    echo "dmidecode belum terinstall. Install dengan: sudo pacman -S dmidecode"
else
    sudo dmidecode --type 17 | awk -F: '
    /Memory Device/ {slot++}
    /Size:/ && $2 !~ /No Module Installed/ {
        gsub(/^[ \t]+/, "", $2);
        size=gensub(/ ([A-Za-z]+).*/, "\\1", "g", $2);
        sizes[size]++;
        total += size;
    }
    /Type:/ && $2 ~ /DDR/ {
        gsub(/^[ \t]+/, "", $2);
        types[$2]++;
    }
    /Speed:/ && $2 ~ /[0-9]/ {
        gsub(/^[ \t]+/, "", $2);
        gsub(/ MHz/, "", $2);
        speeds[$2]++;
    }
    END {
        if (length(types) > 0) {
            for (t in types) {
                print "Jenis RAM       : " t " (" types[t] " slot)";
            }
        } else {
            print "Jenis RAM       : Tidak terdeteksi";
        }

        if (length(sizes) > 0) {
            for (s in sizes) {
                print "Ukuran Keping   : " s " GB (" sizes[s] " slot)";
            }
            print "Total RAM       : " total " GB";
        }

        if (length(speeds) > 0) {
            print "Kecepatan (MHz) :";
            for (sp in speeds) {
                print "  - " sp " MHz (" speeds[sp] " slot)";
            }
        }
        print "-----------------------------";
    }'
fi

### CEK CPU CACHE
echo ""
echo "📦 INFO CACHE CPU"
echo "-----------------------------"

CACHE_PATH="/sys/devices/system/cpu/cpu0/cache"

if [ -d "$CACHE_PATH" ]; then
    for i in $CACHE_PATH/index*; do
        level=$(cat $i/level)
        type=$(cat $i/type)
        size=$(cat $i/size)
        assoc=$(cat $i/ways_of_associativity)

        echo "Level L$level ($type):"
        echo "  Ukuran          : $size"
        echo "  Associativity   : $assoc"
        echo ""
    done
else
    echo "Info cache CPU tidak tersedia di direktori sysfs."
fi

echo "====================================="
