#!/bin/bash

source PKGBUILD

function read_comments () {
    curl -s "https://aur.archlinux.org/packages/albion-online-launcher-bin" |
	sed "/^[ \t]*$/d" | tr -d '\n' | sed "s/>[ \t]*</></g;s/<h4/\n/g" |
	grep 'comment-[0-9]\{3,\}' |
	sed 's/^[^>]*>[ \t]*//;s/ .*\?class="article-content"><div><p>/: /;s/^./\t&/;s/<div id="footer">.*$//;s|</p>|¬|g;s|[^¬]*$||'
}

function update_sources () {
clear

read paquete current_url <<< $( echo ${source[0]} | sed 's/::/ /' )
echo $current_url

url="https:"$( curl 'https://albiononline.com/en/download' 2>/dev/null | grep Linux | grep -o '[^"]*albion-online-setup[^"]*' )
echo $url

_new_cs=${sha256sums[0]} # Default

if [[ "$url" != "$current_url" ]]
then echo "There is a new URL... Updating..."
     #sed -i 's|::"'$current_url'|::"'$url'|' PKGBUILD
fi

## It always has to refresh the source bin
if [ -e $paquete ]
then rm $paquete; fi
updpkgsums
#wget $url -O $paquete
#if (( $? ))
#then exit 1; fi # Exit if wrong code

_new_cs="$( sha256sum $paquete | cut -f 1 --delimiter=' ' )"    # new checksum


echo ${sha256sums[0]} # current checksum
echo ${_new_cs}

_new_ver=$pkgver

if [[ "${_new_cs}" != "${sha256sums[0]}" ]]
then echo "There is a new checksum... Updating..."
     rm -rf decompress
     mkdir decompress &>/dev/null ; pushd decompress
     bsdtar -xf ../$paquete
     pushd data/launcher
     _new_ver=$( cat version.txt | rev | cut -f 1 --delimiter='-' | rev )
     popd
     popd
fi

echo $pkgver
echo $_new_ver

if [[ "$pkgver" != "$_new_ver" ]]
then echo "There is a new version"
     # sed -i "s/pkgver="${pkgver//./\\.}"/pkgver="${_new_ver}"/" PKGBUILD
fi   

## Verify checksums
makepkg --printsrcinfo >.SRCINFO
git status .SRCINFO PKGBUILD

makepkg --verifysource -f
return $?
}

while update_sources
do read_comments; sleep 3h; done
