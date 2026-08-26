# RaptorsPL NixOS configuration

A small Nix flake repository containing RaptorsPL NixOS configuration and per-device modules.

This repository is structured to make adding and maintaining NixOS devices easy: general settings live in `general-configuration.nix`, packages and lists in `package-lists.nix`, and device-specific configuration lives in `device-specific/` (for example `legion.nix` imports the `nvidia.nix` module from additional-features).

## Quick overview 

- Flake entries: `nixosConfigurations.legion-nix`, `gmk`, `nuc`, `rex-vm` (defined in `flake.nix`).
- Global configuration: `general-configuration.nix` (contains time, users, bash aliases, system packages, etc.).
- Device-specific modules: `device-specific/*.nix` (for host- or hardware-specific configuration).

## Adding another device / host configuration, actually working with this repository 

This repository is designed to keep per-device configuration separate and composable. **It is also recommended to leave the default user of the system gid=1000 to the default one that is created in general-configuration.nix eg. raptors**

To add another device:

1. Install the NixOS system with the normal procedure with the default user set to ```raptors``` and then copy this repository to ```nixos-config``` directory located in ```raptors``` home directory.

2. Create a new file `device-specific/<device-host-name>.nix` and place device-specific settings there. Example pattern:

```nix
{ config, lib, pkgs, modulesPath, ... }:

{
	imports = [ ./nvidia.nix ]; # import shared modules as needed

	# The new device configuration should be built using the existing options 
	# in the configuration.nix and hardware-configuration.nix files. 
	# Pay attention to existing options defined in general-configuration.nix in order to
	# not duplicate them. If needed, you can override some options defined in
	# general-configuration.nix using <option> = lib.mkForce <value>;
	environment.systemPackages = with pkgs; [ firefox ];
}
```

3. Register the host in `flake.nix` under `outputs.nixosConfigurations`:

```nix
nixosConfigurations.<device-host-name> = nixpkgs.lib.nixosSystem {
	system = "x86_64-linux";
	modules = [ 
    ./general-configuration.nix 
    ./device-specific/<device-host-name>.nix
  ];
};
```

4. In order for the system to actually recognize the changes you also need to make the configuration seen as the system configuration. To do that you need to delete the configuration stored inside /etc/nixos/ and link up configuration stored in this repository folder. **DO THIS STEP ONLY AFTER YOU ARE SURE THAT THE NEW CONFIGURATION IS ACTUALLY CREATED AND SHOULD WORK. It is also recommended to make the backup of default configuration if you are not sure about the working of the new one.**

```bash
rm -rf /etc/nixos
ln -s <absolute-path-to-your-cloned-repository-folder> /etc/nixos
```

5. Rebuild the new host using the new flake entry:

```bash
sudo nixos-rebuild switch --flake .#<device-host-name>
```

6. After that the rebuilds can be done by the alias:

```bash
nrs
```

This pattern allows you to share common modules (like `nvidia.nix`) across hosts and keep per-device overrides minimal and readable.


## Bash aliases 

The file `general-configuration.nix` defines the following bash aliases via `programs.bash.shellAliases`:

- `nrs`  — runs `sudo nixos-rebuild switch` (quick rebuild of the current configuration)
- `nrsu` — changes to `/home/raptors/nixos-config`, runs `sudo nix flake update`, then `sudo nixos-rebuild switch`, and returns to the previous directory (`cd -`)

If you want these aliases on a non-NixOS host or for a single user without reconfiguring the system, append them to your `~/.bashrc` or `~/.bash_aliases`:

```bash
alias nrs='sudo nixos-rebuild switch'
alias nrsu='cd /home/raptors/nixos-config && sudo nix flake update && sudo nixos-rebuild switch && cd -'
```

## Updating the system & rebuilding 

The recommended way is to use the `nrsu` alias, or you can run these commands directly:

```bash
cd ~/nixos-config
sudo nix flake update
sudo nixos-rebuild switch
```

The `nrsu` alias performs those steps in one command (the path is set to `/home/raptors/nixos-config` in the alias). Use `nrs` for a quick rebuild when you don't need to update flakes.

## Running the Virtual Machine (`rex-vm`)
**For this part you need to have access to nix command on your system (nix as a package see [installation guide](https://nixos.org/download/#nix-install-linux) for non-NixOS system) and access to /dev/kvm (kvm group)**

The repository includes a VM target (`rex-vm`) for testing without physical hardware. You can manage the VM lifecycle using the [`rex-vm.sh`](./rex-vm.sh) script:

```bash
./rex-vm.sh start     # Start the VM in the background (logs to rex-vm.log, PID in .rex-vm.pid)
./rex-vm.sh stop      # Stop the running VM
./rex-vm.sh rebuild   # Stop and restart/rebuild the VM
./rex-vm.sh remove    # Stop the VM and delete persistent state (*.qcow2 disk image)
```

### Accessing the VM

SSH port forwarding is mapped from guest port `22` to host port `2222`:

```bash
ssh -p 2222 raptors@localhost
# or as root:
ssh -p 2222 root@localhost
```

Default credentials:
- User: `raptors` / Password: `vm`
- User: `root` / Password: `vm`
