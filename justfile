# Variables
pkg_yml := "tuxedo-drivers/package.yml"

# Possible tests for clevo-drivers

# Test that package still works and makes
makepkg:
    echo "Testing makepkg"
    rm -rf pkg/ src/ tuxedo-drivers/
    makepkg -f --cleanbuild --nodeps

# use namcap to check for common errors
namcap:
    namcap --info PKGBUILD
    
# Generate dkms.conf from upstream package.yml
generate-dkms-conf file=pkg_yml out="dkms.conf":
    @./generate-dkms-conf.py "{{file}}" "{{out}}"

# Check if upstream has updated version
check-upstream-ver: 
    #!/usr/bin/env bash
    cur_ver=$(grep -oP '^pkgver=\K(\d+\.)*\d+' PKGBUILD)
    rm -rf tuxedo-drivers/
    git clone https://gitlab.com/tuxedocomputers/development/packages/tuxedo-drivers.git
    new_ver=$(./extract-latest-version.py {{pkg_yml}})
    if [ "$cur_ver" != "$new_ver" ]; then
        echo "Upstream version $new_ver not equal to local version $cur_ver"
        exit 1
    else 
        echo "Versions match $new_ver"
        exit 0
    fi

# Automatically update PKGBUILD, if it builds on the latest upstream version.
update-to-upstream:
    #!/usr/bin/env bash
    cur_ver=$(grep -oP '^pkgver=\K(\d+\.)*\d+' PKGBUILD)
    rm -rf pkg/ src/ tuxedo-drivers/
    git clone https://gitlab.com/tuxedocomputers/development/packages/tuxedo-drivers.git
    new_ver=$(./extract-latest-version.py {{pkg_yml}})
    if [ "$cur_ver" != "$new_ver" ]; then
        echo "Updating PKGBUILD to $new_ver from $cur_ver"
        kernel_ver=$(uname -r)
        pwd=$(pwd)
        cp PKGBUILD PKGBUILD.bak
        cp .SRCINFO .SRCINFO.bak
        ./generate-dkms-conf.py {{pkg_yml}} dkms.conf
        sed -i "s/^pkgver=$cur_ver/pkgver=$new_ver/" PKGBUILD
        sed -i "s/^pkgrel=.*/pkgrel=1/" PKGBUILD
        if ./updpkgsums \
            && makepkg -f --cleanbuild --nodeps \
            && make -C /lib/modules/$kernel_ver/build M=$pwd/src/clevo-drivers-$new_ver modules \
            && makepkg --printsrcinfo > .SRCINFO; then
            echo "Update successful"
            exit 0
        else
            echo "New PKGBUILD / .SRCINFO failed - reverting"
            cp PKGBUILD.bak PKGBUILD
            cp .SRCINFO.bak .SRCINFO
            exit 1
        fi
    else 
        echo "Already at latest version $new_ver"
        exit 0
    fi

# Push to AUR
push-to-aur COMMIT-MSG:
    #!/usr/bin/env bash
    # https://just.systems/man/en/chapter_45.html
    set -euxo pipefail
    echo "Pushing to AUR"
    rm -rf aur/
    git clone ssh://aur@aur.archlinux.org/clevo-drivers-dkms-git.git aur
    cp PKGBUILD aur/PKGBUILD
    cp .SRCINFO aur/.SRCINFO
    cp patch.diff aur/patch.diff
    cp dkms.conf aur/dkms.conf
    cd aur
    git commit -am '{{COMMIT-MSG}}'
    git push
