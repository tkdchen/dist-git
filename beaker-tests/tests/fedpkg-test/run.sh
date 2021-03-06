#!/bin/bash

. /usr/bin/rhts-environment.sh || exit 1
. /usr/share/beakerlib/beakerlib.sh || exit 1

export TESTPATH="$( builtin cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function pkgs_cmd {
	ssh  -o 'StrictHostKeyChecking no' clime@pkgs.example.org $1
}

rlJournalStart
    rlPhaseStartSetup FedpkgTest
        pkgs_cmd 'git config --global user.email "clime@redhat.com"'
        pkgs_cmd 'git config --global user.name "clime"'
        pkgs_cmd '/usr/share/dist-git/setup_git_package prunerepo'
    rlPhaseEnd

    rlPhaseStartTest FedpkgTest
        CWD=`pwd`

        cd $TESTPATH

        # clone repo using fedpkg
        rlRun "fedpkg clone /var/lib/dist-git/git/prunerepo"

        cd prunerepo || exit
        git config user.email "somebody@example.com"
        git config user.name "Some name"

        # upload into lookaside and working tree update
        rlRun "fedpkg import --skip-diffs ../../../data/prunerepo-1.1-1.fc23.src.rpm"

        # test of presence of the uploaded file
        rlRun 'wget http://pkgs.example.org/repo/pkgs/prunerepo/prunerepo-1.1.tar.gz/sha512/6a6a30c0e8c661176ba0cf7e8f1909a493a298fd5088389f5eb630b577dee157106e5f89dc429bcf2a6fdffe4bc10b498906b9746220882827560bc5f72a1b01/prunerepo-1.1.tar.gz'

        # commit of spec and updated sources and push into the git repo
        rlRun "git add -A && git commit -m 'test commit'"
        rlRun "fedpkg push"

        # get srpm file using fedpkg
        rlRun "fedpkg --dist f27 srpm"

        cd $CWD
    rlPhaseEnd

    rlPhaseStartCleanup FedpkgTest
        rm -rf $TESTPATH/prunerepo $TESTPATH/prunerepo-1.1.tar.gz
        pkgs_cmd 'rm -rf /var/lib/dist-git/git/prunerepo.git'
        pkgs_cmd 'sudo rm -rf /var/lib/dist-git/cache/lookaside/pkgs/prunerepo'
    rlPhaseEnd
rlJournalEnd &> /dev/null
