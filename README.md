# Raptors NixOS configuration

A small Nix flake repository containing RaptorsPŁ NixOS configuration and per-device modules.

This repository is structured to make adding and maintaining NixOS machines easy: general settings live in `general-configuration.nix`, packages and lists in `package-lists.nix`, and machine-specific configuration lives in `specific-configs/` (for example `legion.nix` imports the `nvidia.nix` module).

## Quick overview 

- Flake entry: `nixosConfigurations.legion-nix` (defined in `flake.nix`).
- Global configuration: `general-configuration.nix` (contains time, users, bash aliases, system packages, etc.).
- Device-specific modules: `specific-configs/*.nix` (for host- or hardware-specific configuration).

## Adding another device / host configuration, actually working with this repository 

This repository is designed to keep per-device configuration separate and composable. **It is also recommended to leave the default user of the system gid=1000 to the default one that is created in general-configuratino.nix eg. raptors**

To add another device:

1. Install the NixOS system with the normal procedure with the default user set to ```raptors``` and then copy this repository to ```nixos-config``` directory located in ```raptors``` home directory.

2. Create a new file `specific-configs/<device-host-name>.nix` and place device-specific settings there. Example pattern:

```nix
{ config, lib, pkgs, modulesPath, ... }:

{
	imports = [ ./nvidia.nix ]; # import shared modules as needed

	# The new device configuration should be built using the existing options in the configuration.nix and hardware-configuration.nix files. Pay attention to existing options defined in general-configuration.nix in order to not duplicate them. If needed, you can override some options defined in general-configuration.nix using <option> = lib.mkForce <value>;
	environment.systemPackages = with pkgs; [ firefox ];
}
```

3. Register the host in `flake.nix` under `outputs.nixosConfigurations`:

```nix
nixosConfigurations.<device-host-name> = nixpkgs.lib.nixosSystem {
	system = "x86_64-linux";
	modules = [ 
    ./general-configuration.nix 
    ./specific-configs/my-host.nix
  ];
};
```

4. In order for the system to actually recognize the changes you also need to make the configuration seen as the system configuration. To do that you need to delete the configuration stored inside /etc/nixos/ and link up configuration stored in this repository folder. **DO THIS STEP ONLY AFTER YOU ARE SURE THAT THE NEW CONFIGURATION IS ACTUALLY CREATED AND SHOULD WORK. It is also recommended to make the backup of default configuration if you are not sure about the working of the new one.**

```bash
rm -rf /etc/nixos
ln -s <absolute-path to your cloned repository folder> /etc/nixos
```

5. Rebuild the new host using the new flake entry:

```bash
sudo nixos-rebuild switch --flake .#my-host
```

6. After that the rebuilds can be done by the alias:

```bash
nrs
```

This pattern allows you to share common modules (like `nvidia.nix`) across hosts and keep per-device overrides minimal and readable.


## Bash aliases 

The file `general-configuration.nix` defines the following bash aliases via `programs.bash.shellAliases`:

- `nrs`  — runs `sudo nixos-rebuild switch` (quick rebuild of the current configuration)
- `nrsu` — changes to `/home/raptors/nixos-config`, runs `sudo nix flake update`, then `sudo nixos-rebuild switch` (update inputs + rebuild)

If you want these aliases on a non-NixOS host or for a single user without reconfiguring the system, append them to your `~/.bashrc` or `~/.bash_aliases`:

```bash
alias nrs='sudo nixos-rebuild switch'
alias nrsu='cd /home/raptors/nixos-config && sudo nix flake update && sudo nixos-rebuild switch'
```

## Updating the system & rebuilding 

Recommended way is to use the alias ```nrsu``` defined as  in the system or you can run these commands directly:

```bash
cd ~/nixos-config
sudo nix flake update
sudo nixos-rebuild
```

The `nrsu` alias performs those two steps in one command (the path is set to `/home/raptors/nixos-config` in the alias). Use `nrs` for a quick rebuild when you don't need to update flakes.


