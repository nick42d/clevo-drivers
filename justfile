# Possible tests for clevo-drivers

# Test that package still works and makes
test-this-ver:
    echo "Testing makepkg"
    rm -rf pkg/ src/ tuxedo-drivers/
    makepkg -f --cleanbuild --nodeps
    
# Check if upstream has updated version
check-upstream-ver: 
    #!/usr/bin/env bash
    cur_ver=$(grep -oP '^pkgver=\K(\d+\.)*\d+' PKGBUILD)
    rm -rf tuxedo-drivers/
    git clone https://gitlab.com/tuxedocomputers/development/packages/tuxedo-drivers.git
    new_ver=$(grep -Pom1 '.* \(\K.*(?=\) .*; urgency=.*)' tuxedo-drivers/debian/changelog) 
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
    new_ver=$(grep -Pom1 '.* \(\K.*(?=\) .*; urgency=.*)' tuxedo-drivers/debian/changelog) 
    if [ "$cur_ver" != "$new_ver" ]; then
        echo "Updating PKGBUILD to $new_ver from $cur_ver"
        cp PKGBUILD PKGBUILD.bak
        cp .SRCINFO .SRCINFO.bak
        sed -i "s/^pkgver=$cur_ver/pkgver=$new_ver/" PKGBUILD
        if updpkgsums && makepkg -f --cleanbuild --nodeps && makepkg --printsrcinfo > .SRCINFO; then
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
push-to-aur:
    echo "TODO: remove redundant folders, clone AUR repo, copy files, cd aur repo, push aur repo"
