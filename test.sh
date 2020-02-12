#!/bin/sh
git checkout --quiet "release/${version}"
if [ "${?}" -ne "0" ]; then # branch doesnt exist
    git checkout -b "release/${version}"
    echo "${version}" > version.txt
    git add version.txt
    git commit -m "Creating new branch"
    git tag "${version}.0"
    git push -u --all
else
    git pull origin master
    git checkout "release/${version}"
    subver=$(( $(git tag | sort -r | head -n 1 | cut -d '.' -f 3) + 1 ))
    git tag "${version}.${subver}"
    echo "${version}" > version.txt
    docker build -t cowsay:"${version}.${subver}" .
    docker tag cowsay:"${version}.${subver}" 324586282795.dkr.ecr.eu-central-1.amazonaws.com/cowsay:"${version}.${subver}"
    docker run -p 8000:8000 --name apptest -d cowsay:"${version}.${subver}" 8000
    while ! wget localhost:8000; do
        sleep 1
    done
    curl localhost:8000
    docker login -u "lordg66" -p "L9o+5xK@b<*q" docker.io
    docker push 324586282795.dkr.ecr.eu-central-1.amazonaws.com/cowsay:"${version}.${subver}"
fi
docker rm -f apptest