{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.modules.virtualization = {
    virt-manager.enable = lib.mkEnableOption "Enable Virt Manager";
    podman.enable = lib.mkEnableOption "Enable Podman";
  };

  config = lib.mkMerge [
    (lib.mkIf config.modules.virtualization.virt-manager.enable {
      programs.virt-manager.enable = true;

      virtualisation.libvirtd = {
        enable = true;
        qemu = {
          package = pkgs.qemu_kvm;
          runAsRoot = true;
          swtpm.enable = true;
        };
      };

      environment.persistence."/persist" = {
        directories = [
          "/var/lib/libvirt/images"
          "/var/lib/libvirt/qemu"
        ];
      };

      environment.systemPackages = with pkgs; [
        killall
      ];
      
      boot.kernelParams = [
        "amd_iommu=on"
        "iommu=pt"
        "initcall_blacklist=sysfb_init"
        "pci=realloc=off"
      ];
  
      boot.initrd.kernelModules = [
        "vfio"
        "vfio_pci"
        "vfio_iommu_type1"
      ];
  
      systemd.services.libvirtd = {
        path = let
          env = pkgs.buildEnv {
            name = "qemu-hook-env";
            paths = with pkgs; [
              bash
              libvirt
              kmod
              ripgrep
              sd
            ];
          };
          in
          [ env ];
  
        preStart =
        ''
          mkdir -p /var/lib/libvirt/hooks/qemu.d/win11/prepare/begin
          mkdir -p /var/lib/libvirt/hooks/qemu.d/win11/release/end
          mkdir -p /var/lib/libvirt/vbios
  
          ln -sf /etc/nixos/config/modules/virtualization/scripts/qemu /var/lib/libvirt/hooks/qemu
          ln -sf /etc/nixos/config/modules/virtualization/scripts/start.sh /var/lib/libvirt/hooks/qemu.d/win11/prepare/begin/start.sh
          ln -sf /etc/nixos/config/modules/virtualization/scripts/stop.sh /var/lib/libvirt/hooks/qemu.d/win11/release/end/stop.sh
          #ln -sf /etc/nixos/config/modules/virtualization/rom/rx-7800xt.rom /var/lib/libvirt/vbios/rx-7800xt.rom
  
          chmod +x /var/lib/libvirt/hooks/qemu
          chmod +x /var/lib/libvirt/hooks/qemu.d/win11/prepare/begin/start.sh
          chmod +x /var/lib/libvirt/hooks/qemu.d/win11/release/end/stop.sh
      '';
      };
    })

    (lib.mkIf config.modules.virtualization.podman.enable {
      virtualisation.podman.enable = true;

      environment.systemPackages = with pkgs; [
        podman-compose
      ];
  
  

    })
  ];
}
