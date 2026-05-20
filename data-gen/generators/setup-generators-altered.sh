#!/bin/bash

set -e  # quit on error
cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")" >/dev/null

####################################################################################################
# Robust Google Drive download (handles large files and confirmation)
# Usage: download_gdrive <file_id> <output_file>
download_gdrive() {
    local file_id="$1"
    local output="$2"
    local cookie="/tmp/gdrive-cookies-$$.txt"

    # First request to get confirmation token
    curl -sc "$cookie" "https://drive.google.com/uc?export=download&id=$file_id" > /tmp/inter.html

    # Extract confirm token
    local confirm=$(sed -n 's/.*confirm=\([0-9A-Za-z_-]\+\).*/\1/p' /tmp/inter.html)
    if [[ -n "$confirm" ]]; then
        # Second request with confirm token
        curl -Lb "$cookie" "https://drive.google.com/uc?export=download&confirm=$confirm&id=$file_id" -o "$output"
    else
        # No confirmation needed
        curl -Lb "$cookie" "https://drive.google.com/uc?export=download&id=$file_id" -o "$output"
    fi

    rm -f "$cookie" /tmp/inter.html

    # Verify that we got a real ZIP file (starts with PK)
    if [[ ! -f "$output" ]] || [[ $(head -c 2 "$output") != "PK" ]]; then
        echo "ERROR: Downloaded file is not a valid ZIP archive. Download failed."
        exit 1
    fi
}
####################################################################################################

declare -A GDMC_GENERATOR_URLS=(
    ["Mikes-Angels"]="1aCM8Veh8xOFu3Xd42DfQO2l1yGxtjRpT"
)

shopt -s dotglob
cd "code"
mkdir -p "gdmc-2022"
pushd "gdmc-2022" >/dev/null

    # Download generators
    for team in "${!GDMC_GENERATOR_URLS[@]}"; do
        if [[ ! -d "$team" ]]; then
            mkdir -p "$team"
            pushd "$team" >/dev/null
                file_id="${GDMC_GENERATOR_URLS[$team]}"
                echo "Downloading $team (ID: $file_id) ..."
                download_gdrive "$file_id" "generator.zip"
                echo "Unzipping ..."
                unzip -q "generator.zip"
                rm "generator.zip"
            popd >/dev/null
        fi
    done

    # Mike's Angels - reorganise extracted contents
    pushd "Mikes-Angels" >/dev/null
        if [[ ! -d ".venv" ]]; then
            # The ZIP may contain a folder with a space in its name
            if [[ -d "Medieval City Generator" ]]; then
                mv "Medieval City Generator"/* . 2>/dev/null || true
                rmdir "Medieval City Generator" 2>/dev/null || true
            elif [[ -d "medieval_city_generator" ]]; then
                mv "medieval_city_generator"/* . 2>/dev/null || true
                rmdir "medieval_city_generator" 2>/dev/null || true
            else
                echo "WARNING: Expected 'Medieval City Generator' folder not found."
                echo "Contents of $(pwd):"
                ls -la
                # Continue anyway – maybe the files are already in the root
            fi
            # Create requirements.txt
            cat > "requirements.txt" <<EOF
astar==0.93
gdpc==5.0.2
numpy==1.19.3
PyGLM==2.6.0
pyglm-typing==0.2.1
requests==2.22.0
scikit-image==0.19.3
scipy==1.9.3
EOF
        fi
    popd >/dev/null

    # Mike's Angels - Patches (only if patch files exist)
    for dir in "Mikes-Angels-Wall" "Mikes-Angels-Roads" "Mikes-Angels-Roads-Wall"; do
        if [[ ! -d "$dir" ]]; then
            cp -r "Mikes-Angels" "$dir"
            pushd "$dir" >/dev/null
                patch_file="../../../patches/${dir}.diff"
                if [[ -f "$patch_file" ]]; then
                    patch -p0 < "$patch_file"
                else
                    echo "Skipping patch for $dir (file not found)"
                fi
            popd >/dev/null
        fi
    done

popd >/dev/null

# Create Python virtualenvs
for dir in "gdmc-2022/Mikes-Angels" "gdmc-2022/Mikes-Angels-Roads" "gdmc-2022/Mikes-Angels-Wall" "gdmc-2022/Mikes-Angels-Roads-Wall" "ring" "ring-adaptive"; do
    if [[ -d "$dir" ]]; then
        pushd "$dir" >/dev/null
            if [[ ! -d ".venv" ]]; then
                echo "Creating virtualenv for $dir ..."
                python3 -m virtualenv -p "$(which python3)" ".venv"
                source ".venv/bin/activate"
                pip install -r "requirements.txt"
                deactivate
            fi
        popd >/dev/null
    else
        echo "Directory $dir does not exist – skipping."
    fi
done

echo "Setup completed successfully."