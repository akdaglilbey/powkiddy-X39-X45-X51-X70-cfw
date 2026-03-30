#/bin/sh

SYSROOT=$(pwd)/sysroot
OUT=$(pwd)/output/
TOOLCHAIN=$(pwd)/sysroot

rm -rf $OUT/lib
rm -rf $OUT/usr/lib
mkdir -p $OUT/lib
mkdir -p $OUT/usr/lib
mkdir -p $OUT/proc
mkdir -p $OUT/tmp
mkdir -p $OUT/dev
mkdir -p $OUT/sys


# fichiers déjà traités
declare -A SEEN

# trouver une lib dans le sysroot
find_lib() {
    local name=$1
    find $SYSROOT/lib $SYSROOT/usr/lib $SYSROOT/usr/local/lib -name "$name" 2>/dev/null | head -n 1
}

# copier une lib
copy_lib() {
    local src=$1
    local name=$(basename "$src")

    if [[ "$src" == *"/usr/lib/"* ]] || [[ "$src" == *"/usr/local/lib/"* ]]; then
        dest=$OUT/usr/lib
    else
        dest=$OUT/lib
    fi

    if [ ! -f "$dest/$name" ]; then
        echo "  -> copy $name"
        cp -L "$src" "$dest/"
    fi
}

# analyser un fichier ELF
process_file() {
    local file=$1

    # éviter boucle
    if [[ -n "${SEEN[$file]}" ]]; then
        return
    fi
    SEEN[$file]=1

    # vérifier ELF ARM
    if ! file "$file" | grep -q "ARM"; then
        return
    fi

    echo "Processing $file"

    # lire les dépendances
    arm-linux-gnueabihf-readelf -d "$file" 2>/dev/null | grep NEEDED | awk -F'[][]' '{print $2}' | while read lib; do

        # éviter re-traitement
        if [[ -n "${SEEN[$lib]}" ]]; then
            continue
        fi

        found=$(find_lib "$lib")

        if [ -n "$found" ]; then
            copy_lib "$found"
            SEEN[$lib]=1

            # recursion sur la lib trouvée
            process_file "$found"
        else
            echo "  !! MISSING: $lib"
        fi

    done
}

echo "=== Scan des binaires ==="

# scan initial (binaires + .so déjà présents)
find $OUT -type f | while read f; do
    process_file "$f"
done

echo "=== Terminé ==="
