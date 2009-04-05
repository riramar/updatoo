#!/bin/bash
#
# updatoo 
# Agent Smith (Ricardo Iramar dos Santos)
# ricardo.iramar@gmail.com
# 
# updatoo is a bash script that performing a simple full (silent if you want) update in a Gentoo System.
# By default updatoo will synchronize your portage tree with eix-sync, check if your system is update and for bad packages, create a pretend list of packages, try to install all the packages from the pretend list, clean up the system and run revdep-rebuild command.
# If occur any problem updatoo will abort with code 1 so you can combine with && or || operator.
# Everything is loged in /root/.updatoo/ where you can check anytime.
# Please report any bug to ricardo.iramar@gmail.com or http://forums.gentoo.org/viewtopic-t-717092.html.
#
# ChangeLog
#   Version 0.1 (29/11/2008)
#   - First version. No bugs yet.
#
#   Version 0.2 (07/12/2008)
#   - Gentoo look output (/etc/init.d/functions.sh").
#   - Some code fix.
#
#   Version 0.3 (02/02/2009)
#   - Code improvement.
#   - Changed force mode by ask mode.
#   - Multiple independent options.
#   - Error check.
#   - Detect masked packages.
#   - Prepare mode added.
#
#   Version 0.4 (15/03/2009)
#   - Parallel fetch.
#
# ToDo
#   - None.
#

### Variables ###
StrVersion="v0.4"
StrHomeDir="$HOME/.updatoo"
StrWorkDir="$StrHomeDir/`date +%F`"
StrFuncFile="/etc/init.d/functions.sh"
StrSyncCmd="/usr/bin/eix-sync"
StrEmergeWorld="/usr/bin/emerge --verbose --pretend --update --deep --newuse world"
StrEmergeFetch="/usr/bin/emerge --fetchonly --nodeps"
StrEmergeOnePkg="/usr/bin/emerge --oneshot --nodeps"
StrEmergeDepClean="/usr/bin/emerge --depclean"
StrEclean="/usr/bin/eclean distfiles"
StrRmRfClean="rm -rf /var/tmp/portage/*"
StrRevdep="/usr/bin/revdep-rebuild"
### End Variables ###

### Begin SubHelp ###
SubHelp()
{
echo "updatoo [ options ]
Options:
--help (-h)		Print this help.
--ask (-a)		Ask me to confirm each step.
--sync (-s)		Synchronize the portage tree with eix-sync.
--prepare (-p)		Don't emerge anything, only create the lists and check for bad packages.
--fetch (-f)		Fetch the packages from the last list of the day in parallel.
--execute (-e)		Don't create the lists, only update the system using the last lists of the day.
--clean (-c)		Clean up the entire system.
--revdep (-r)		Run revdep-rebuild command after all.
You can combine the options.
The default operation is the same that \"updatoo -spfecr\"."
}
### End SubHelp ###

### Begin SubAbort ###
SubAbort()
{
	eend "Aborted!"
	exit 1
}
### End SubAbort ###

### Begin Script ###
if [ ! -f "$StrFuncFile" ]
then
	echo "Could not found $StrFuncFile. Please emerge baselayout first."
	echo "Aborted!"
	exit 1
fi
source "$StrFuncFile"
if [ "$USER" != "root" ]
then
	ewarn "You need to be root to run updatoo."
	SubAbort
elif [ ! -f "/usr/bin/eix" ]
then
	ewarn "Please install eix first (emerge eix)."
	SubAbort
elif [ ! -f "/usr/bin/revdep-rebuild" ]
then
	ewarn "Please emerge gentoolkit first (emerge gentoolkit)."
	SubAbort
fi

if [[ -z "$@" || "$@" =~ ^(-a|--ask)$ ]]
then
	StrDefault="Y"
	if [[ "$@" =~ ^(-a|--ask)$ ]]; then StrAsk="Y"; fi
else
	for StrOpt in "$@"
	do
		if [[ "$StrOpt" =~ ^-([^-].*)$ ]]
		then
			for StrOpt in `echo ${BASH_REMATCH[1]} | sed 's/\(.\)/\1 /g'`
			do
				if [ "$StrOpt" = "h" -a "$StrHelp" != "Y" -a "$StrAsk" != "Y" -a "$StrPrepare" != "Y" -a "$StrFetch" != "Y" -a "$StrExecute" != "Y" ]
				then
					StrHelp="Y"
				elif [ "$StrOpt" = "a" -a "$StrAsk" != "Y" -a "$StrHelp" != "Y" ]
				then
					StrAsk="Y"
				elif [ "$StrOpt" = "s" -a "$StrSync" != "Y" -a "$StrHelp" != "Y" ]
				then
					StrSync="Y"
				elif [ "$StrOpt" = "p" -a "$StrPrepare" != "Y" -a "$StrHelp" != "Y" ]
				then
					StrPrepare="Y"
				elif [ "$StrOpt" = "f" -a "$StrFetch" != "Y" -a "$StrHelp" != "Y" ]
				then
					StrFetch="Y"
				elif [ "$StrOpt" = "e" -a "$StrExecute" != "Y" -a "$StrHelp" != "Y" ]
				then
					StrExecute="Y"
				elif [ "$StrOpt" = "c" -a "$StrClean" != "Y" -a "$StrHelp" != "Y" ]
				then
					StrClean="Y"
				elif [ "$StrOpt" = "r" -a "$StrRev" != "Y" -a "$StrHelp" != "Y" ]
				then
					StrRev="Y"
				else
					eerror "Invalid option!"
					SubHelp
					exit 1
				fi
			done
		elif [[ "$StrOpt" =~ ^--([^-].*)$ ]]
		then
			if [ "${BASH_REMATCH[1]}" = "help" -a "$StrHelp" != "Y" -a "$StrAsk" != "Y" -a "$StrPrepare" != "Y" -a "$StrFetch" != "Y" -a "$StrExecute" != "Y" ]
			then
				StrHelp="Y"
			elif [ "${BASH_REMATCH[1]}" = "ask" -a "$StrAsk" != "Y" -a "$StrHelp" != "Y" ]
			then
				StrAsk="Y"
			elif [ "${BASH_REMATCH[1]}" = "sync" -a "$StrSync" != "Y" -a "$StrHelp" != "Y" ]
			then
				StrSync="Y"
			elif [ "${BASH_REMATCH[1]}" = "prepare" -a "$StrPrepare" != "Y" -a "$StrHelp" != "Y" ]
			then
				StrPrepare="Y"
			elif [ "${BASH_REMATCH[1]}" = "fetch" -a "$StrFetch" != "Y" -a "$StrHelp" != "Y" ]
			then
				StrFetch="Y"
			elif [ "${BASH_REMATCH[1]}" = "execute" -a "$StrExecute" != "Y" -a "$StrHelp" != "Y" ]
			then
				StrExecute="Y"
			elif [ "${BASH_REMATCH[1]}" = "clean" -a "$StrClean" != "Y" -a "$StrHelp" != "Y" ]
			then
				StrClean="Y"
			elif [ "${BASH_REMATCH[1]}" = "revdep" -a "$StrRev" != "Y" -a "$StrHelp" != "Y" ]
			then
				StrRev="Y"
			else
				eerror "Invalid option!"
				SubHelp
				exit 1
			fi

		else
			eerror "Invalid option!"
			SubHelp
			exit 1
		fi
	done
fi

if [ "$StrHelp" = "Y" ]
then
	SubHelp
	exit 0
fi

if [ ! -d "$StrHomeDir" ]; then mkdir "$StrHomeDir"; fi
if [ ! -d "$StrWorkDir" ]; then mkdir "$StrWorkDir"; fi
StrError="N"

if [ "$StrSync" = "Y" -o "$StrDefault" = "Y" ]
then
	StrAnswer=""
	if [ -e "$StrWorkDir/eix-sync.log" -a "$StrAsk" = "Y" ]
	then
		ewarn "The portage tree has already synchronized today."
		ewarn "Would you like to synchronize again with eix-sync? (Y/n)"
		read StrAnswer
	fi
	if [[ "$StrAnswer" =~ ^([yY]([eE][sS])?)?$ ]]
	then
		ebegin "Synchronizing the portage tree with eix-sync"
		$StrSyncCmd &> "$StrWorkDir/eix-sync.log"
		if [ "$?" -eq 0 ]
		then
			eend
		else
			eerror "Failed, please fix the errors describe in $StrWorkDir/eix-sync.log first and run updantoo late."
			SubAbort
		fi
	else
		ewarn "The portage tree was not synchronized."
	fi
fi

if [ "$StrPrepare" = "Y" -o "$StrDefault" = "Y" ]
then
	StrAnswer=""
	if [ -e "$StrWorkDir/emerge_world.out" -a -e "$StrWorkDir/blocked.lst" -a -e "$StrWorkDir/fetched.lst" -a -e "$StrWorkDir/masked.lst" -a -e "$StrWorkDir/pretend.lst" -a "$StrAsk" = "Y" ]
	then
		ewarn "updatoo has alredy prepared today."
		ewarn "Would you like to prepare again? (Y/n)"
		read StrAnswer
	fi
	if [[ "$StrAnswer" =~ ^([yY]([eE][sS])?)?$ ]]
	then
		einfo "Preparing your system"
		eindent
		ebegin "Checking if your system is already updated"
		$StrEmergeWorld &> "$StrWorkDir/emerge_world.out"
		if [ "`tail -1 $StrWorkDir/emerge_world.out`" = "Total: 0 packages, Size of downloads: 0 kB" ]
		then
			einfo "Your system is alredy updated!"
			eoutdent
			einfo "Finished successfully!"
			exit 0
		else
			ebegin "Checking for blocks packages"
			grep '^\[blocks' "$StrWorkDir/emerge_world.out" &> "$StrWorkDir/blocked.lst"
			if [ -s "$StrWorkDir/blocked.lst" ]
			then
				eerror "There are the follows blocks packages."
				cat "$StrWorkDir/blocked.lst"
				eerror "Please fix them first and run updantoo late."
				eoutdent
				SubAbort
			else
				eend
			fi
			ebegin "Checking for fetched packages"
			grep '^\[ebuild[^]F]*F' "$StrWorkDir/emerge_world.out" &> "$StrWorkDir/fetched.lst"
			if [ -s "$StrWorkDir/fetched.lst" ]
			then
				eerror "There are the follows fetch packages."
				cat "$StrWorkDir/fetched.lst"
				eerror "Please download them manually first and run updantoo late."
				einfo "Trying to emerge these packages in order to get the download URL."
				while read -r StrLine
				do
					StrPackage="`echo $StrLine | sed -e 's/^[^]]*\] //g' -e 's/ .*$//g'`"
					$StrEmergeOnePkg "=$StrPackage"
				done < "$StrWorkDir/fetched.lst"
				eoutdent
				SubAbort
			else
				eend
			fi
			ebegin "Checking for masked packages"
			grep '^!!! All ebuilds that could satisfy.*have been masked.' "$StrWorkDir/emerge_world.out" &> "$StrWorkDir/masked.lst"
			if [ -s "$StrWorkDir/masked.lst" ]
			then
				eerror "There are the follows masked packages."
				cat "$StrWorkDir/emerge_world.out"
				eerror "Please fix them first and run updantoo late."
				eoutdent
				SubAbort
			else
				eend
			fi
			ebegin "Creating pretend list"
			grep '^\[' "$StrWorkDir/emerge_world.out" &> "$StrWorkDir/pretend.lst"
			if [ ! -s "$StrWorkDir/pretend.lst" ]
			then
				eerror "Failed, please fix the errors below and run updantoo late."
				cat "$StrWorkDir/emerge_world.out"
				eoutdent
				SubAbort
			else
				eend
			fi
		fi
		eoutdent
	else
		ewarn "updatoo was not prepared."
	fi
fi

if [ "$StrFetch" = "Y" -o "$StrDefault" = "Y" ]
then
	if [ ! -e "$StrWorkDir/pretend.lst" ]
	then
		ewarn "You need to prepare first in order to fetch."
		SubAbort
	fi
	StrAnswer=""
	if [ -e "$StrWorkDir/fetch.log" -a "$StrAsk" = "Y" ]
	then
		ewarn "updatoo has alredy fetched packages from the last list today."
		ewarn "Would you like to fetch in parallel again? (Y/n)"
		read StrAnswer
	fi
	if [[ "$StrAnswer" =~ ^([yY]([eE][sS])?)?$ ]]
	then
		ebegin "Fetching packages in parallel from pretend list"
		while read -r StrLine
		do
			StrPackage="`echo $StrLine | sed -e 's/^[^]]*\] //g' -e 's/ .*$//g'`"
			StrPackages="$StrPackages =$StrPackage"
		done < "$StrWorkDir/pretend.lst"
		$StrEmergeFetch $StrPackages &> "$StrWorkDir/fetch.log" &
	else
		ewarn "updatoo didn't fetch packages in parallel."
	fi
fi

if [ "$StrExecute" = "Y" -o "$StrDefault" = "Y" ]
then
	StrAnswer=""
	if [ -e "$StrWorkDir/emerged.lst" -a -e "$StrWorkDir/emerge.log" -a "$StrAsk" = "Y" ]
	then
		ewarn "updatoo has alredy executed today."
		ewarn "Would you like to execute again? (Y/n)"
		read StrAnswer
	fi
	if [[ "$StrAnswer" =~ ^([yY]([eE][sS])?)?$ ]]
	then
		rm -f "$StrWorkDir/emerged.lst" "$StrWorkDir/failed.lst" "$StrWorkDir/emerge.log"
		touch "$StrWorkDir/emerged.lst" "$StrWorkDir/failed.lst" "$StrWorkDir/emerge.log"
		NumPackages="`wc -l $StrWorkDir/pretend.lst | cut -d' ' -f1`"
		NumPackage="0"
		ebegin "Emerging $NumPackages packages from pretend list"
		eindent
		while read -r StrLine
		do
			let NumPackage++
			StrPackage="`echo $StrLine | sed -e 's/^[^]]*\] //g' -e 's/ .*$//g'`"
			ebegin "Emerging $StrPackage ($NumPackage of $NumPackages)"
			$StrEmergeOnePkg "=$StrPackage" >> "$StrWorkDir/emerge.log" 2>&1
			if [ "$?" -eq "0" ]
			then
				echo "$StrPackage" >> "$StrWorkDir/emerged.lst" 2>&1
				eend
			else
				echo "$StrPackage" >> "$StrWorkDir/failed.lst" 2>&1
				eend "Fail emerging $StrPackage!"
			fi
		done < "$StrWorkDir/pretend.lst"
		eoutdent
		if [ -s "$StrWorkDir/failed.lst" ]
		then
			StrError="Y"
		else
			einfo "All packages were emerged successfully!"; eend
		fi
	else
		ewarn "updatoo was not executed."
	fi
fi

if [ "$StrClean" = "Y" -o "$StrDefault" = "Y" ]
then
	StrAnswer=""
	if [ -e "$StrWorkDir/cleanup.log" -a "$StrAsk" = "Y" ]
	then
		ewarn "updatoo has alredy cleaned up your system today."
		ewarn "Would you like to clean up again? (Y/n)"
		read StrAnswer
	fi
	if [[ "$StrAnswer" =~ ^([yY]([eE][sS])?)?$ ]]
	then
		ebegin "Cleaning up the system"
		$StrEmergeDepClean &> "$StrWorkDir/cleanup.log" && $StrEclean >> "$StrWorkDir/cleanup.log" 2>&1 && $StrRmRfClean >> "$StrWorkDir/cleanup.log" 2>&1
		if [ "$?" -eq 0 ]
		then
			eend
		else
			eerror "Failed, please fix the errors describe in $StrWorkDir/cleanup.log first and run updantoo late."
			SubAbort
		fi
	fi
fi

if [ "$StrRev" = "Y" -o "$StrDefault" = "Y" ]
then
	StrAnswer=""
	if [ -e "$StrWorkDir/revdep-rebuild.log" -a "$StrAsk" = "Y" ]
	then
		ewarn "updatoo has alredy run revdep-rebuild today."
		ewarn "Would you like to run again? (Y/n)"
		read StrAnswer
	fi
	if [[ "$StrAnswer" =~ ^([yY]([eE][sS])?)?$ ]]
	then
		ebegin "Running revdep-rebuild"
		$StrRevdep &> "$StrWorkDir/revdep-rebuild.log"
		if [ "$?" -eq 0 ]
		then
			eend
		else
			eerror "Failed, please fix the errors describe in $StrWorkDir/revdep-rebuild.log first and run updantoo late."
			SubAbort
		fi
	fi
fi

if [ "$StrError" = "Y" ]
then
	eerror "Failed, some packages could not be emerged. Please fix the errors describe in $StrWorkDir/emerge.log for all packages in $StrWorkDir/failed.lst and run updantoo late."
	eend "Finished with errors!"
	exit 1
else
	einfo "Finished successfully!"
	eend
	exit 0
fi
### End Script ###
