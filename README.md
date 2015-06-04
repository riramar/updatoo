updatoo is a bash script that performing a simple full (silent if you want) update in a Gentoo System. By default updatoo will synchronize your portage tree with eix-sync, check if your system is update and for bad packages, create a pretend list of packages, try to install all the packages from the pretend list, clean up the system and run revdep-rebuild command.<br>
If occur any problem updatoo will abort with code 1 so you can combine with && or || operator. Everything is loged in /root/.updatoo/ where you can check anytime.<br>
Please report any bug to ricardo.iramar@gmail.com. 
