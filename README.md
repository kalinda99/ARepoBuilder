# ARepoBuilder
## Arch Linux custom repos made easy

Named after ~~or shamelessly stolen from~~ the awesome [aconfmgr](https://github.com/CyberShadow/aconfmgr), ARepoBuilder (ARB) is a BASH program for Arch Linux to make maintaining a custom repository easier through automation. Features include a systemd service and timer, package signing, and adding/removing packages from your repository. ARB mainly supports uploading to a remote web server via SSH, but there is an option for a local repo as well, although I haven't really fully implemented it yet.

## DISCLAIMER
This is ALPHA software, it may break things or delete files inside your repo folder without you wanting it to! To mitigate this, you can change the `trash` variable in `vars.sh` to `true` so that [trash-put](https://github.com/andreafrancia/trash-cli) will be used instead of rm, just in case. Make sure the `trash-cli` package is installed to use it. 

This may be coded very poorly. I started writing this to maintain my [own custom repo](https://aur.andontie.net/) sometime near the beginning of 2019 with little to no prior programming experience. I know a lot more now than I did then, but I'm sure that there are better ways of doing things than how I do here. I just want to say that I am open to any and all suggestions for improvements to this program and Shell scripting in general. Feel free to open an issue.

## Okay, I get it! Let's go to the Getting Started section already!
Before we get to using ARB, here's some things you should have installed and setup:
### Requirements:
- Everything needed to compile packages (`base-devel`, for example)
- [A clean Chroot](https://wiki.archlinux.org/index.php/DeveloperWiki:Building_in_a_clean_chroot) (we'll be compiling packages here to keep things seperate from the system)
- `sudo` (more on this later)
- `git` (the AUR uses this)
- `rsync` (for keeping the remote repo up to date with the local one)
- [GNU Screen](https://wiki.archlinux.org/index.php/GNU_Screen) (the systemd timer works inside a screen to make switching into it easy, it's also nice to attach to and from it when you're compiling big packages)
- [SSH keys](https://wiki.archlinux.org/index.php/SSH_keys) (ARB does not and will store your server passwords, so please set this up if you're using SSH. It's one of the best ways to secure SSH access anyway so everyone should probably use it.)

### Optional:
- [Keychain](https://www.funtoo.org/Keychain) (Recomended to enable easy, passwordless logins to your web server, also see the Arch Wiki [section on it](https://wiki.archlinux.org/index.php/SSH_keys#Keychain))
- [trash-cli](https://github.com/andreafrancia/trash-cli) (Keep my crappy coding from causing ARB to delete anything important by accident)
- [Knockd](https://wiki.archlinux.org/index.php/Port_knocking) (ARB supports port knocking if you use it on your web server)

### Using sudo
If you don't want to be constantly prompted for a password whenever `makechrootpkg` is run, add the following to your `sudoers` file in the User Privledge section, with your user in place of `username`:

```
# run makechrootpkg for building packages without password
username ALL = (root) NOPASSWD: /usr/bin/makechrootpkg
```

This allows you to run this command without your root password, which I figure should be safe enough since it's inside the chroot and therefore isolated from your real system.

### Running ARB
Clone this git repo to your computer, doesn't matter where. Navigate to the folder in a terminal, then run `sh arepobuilder` and select the option to make a new repo.

Go through the prompts within the script. A vars.sh file will be created for you with variables for all the info you provided and options you enabled or disabled.

After you're all setup, you can run arepobuilder again to start adding and building packages! You can use a list or just add them one at a time.

### Systemd and GNU Screen
To setup systemd copy the `builder@.build` and `builder@.timer` files into `/etc/systemd/system/`. The timer is set to update and upload packages nightly at 3 am, but feel free to modify it to suit your needs before enabling it with systemd. In order to use this, you must Screen enabled via systemd as well. I have provided a systemd unit to start Screen when the system starts up.

You should also add the following to your /.screenrc config file so that your Screen defaults to your repo build folder when opened:
```
# starting directory
chdir $HOME/ARepoBuilder
```

And that's all! Feel free to look through the scripts, edit them to suit your needs, and open an issue if you find any bugs.
