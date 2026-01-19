    # reconstroi o disco
    wipefs -a $system_disk
    parted $system_disk mklabel $gptOrMbr

    # cria particao de 1GB para boot
    parted -a optimal $system_disk mkpart primary 0% 1GB

    # formata a particao de boot para fat32
    mkfs.fat -F 32 -n BOOT ${system_disk}1
    sync

    # flags de para particao boot
    parted $system_disk set 1 esp on
    parted $system_disk set 1 boot on

    # cria a segunda particao usando o restante do disco
    case $separete_home in
        s|sim)
            parted -a optimal $system_disk mkpart primary 1GB 100%;;
    	n|nao)
    		parted -a optimal $system_disk mkpart primary 1G 25%
    		parted -a optimal $system_disk mkpart primary 25% 100%
       ;;
    esac

    case $system_fs in
        btrfs|tmpfs)
            mkfs.btrfs -L nixos -f ${system_disk}2
            sync

            # Montar e criar subvolumes
            mount ${system_disk}2 /mnt

            btrfs subvolume create /mnt/root
            btrfs subvolume create /mnt/nix
            btrfs subvolume create /mnt/safe

            # Cria snapshot vazia
            btrfs subvolume snapshot -r /mnt/root /mnt/root-blank

            umount /mnt

            # Montar a raiz
            mount -o subvol=root,noatime ${system_disk}2 /mnt

            # cria os diretórios no liveCD
            mkdir -p /mnt/{nix,safe,boot,home,nix/git}

            # Montar outros subvolumes do sistema
            mount -o subvol=nix,noatime ${system_disk}2 /mnt/nix
            mount -o subvol=safe,noatime ${system_disk}2 /mnt/safe
        ;;
        zfs)
            zpool create -f -o ashift=12 nixos ${system_disk}2 # ashift=12 é bom para SSDs
            sync

            zfs create -o mountpoint=legacy nixos/system # cria um dataset

            zfs set acltype=posixacl nixos/system # define as permissões do ZFS como POSIX

            # cria sub-datasets
            zfs create -p -o mountpoint=legacy nixos/system/root
            zfs create -p -o mountpoint=legacy nixos/system/nix
            zfs create -p -o mountpoint=legacy nixos/system/safe

            zfs set compression=lz4 nixos/system # compressão

            # monta os datasets
            mount -t zfs nixos/system/root /mnt
            mkdir -p /mnt/{nix,safe,boot,home,nix/git}

            mount -t zfs nixos/system/nix /mnt/nix
            mount -t zfs nixos/system/safe /mnt/safe

            zfs snapshot nixos/system/root@blank # cria uma snapshot vazia do root
        ;;
        ext4|xfs|f2fs)
            # Formatação
            if [ "$system_fs" = "f2fs" ]; then
                mkfs.f2fs -l nixos -f "${system_disk}2"
            else
                mkfs."$system_fs" -L nixos -f "${system_disk}2"
            fi

            sync

            mount -t "$system_fs" "${system_disk}2" /mnt

            mkdir -p /mnt/{nix,boot,home,nix/git}
        ;;
    esac

    # clona as configs
    git clone $git /mnt/nix/git/

    case $system_fs in
    	btrfs|zfs)
    		sed -i "10c\  fsBackend = \"$system_fs\";" $file

    		case $resp_ephemeral in
    			s|sim) sed -i "132c\    ./ephemeral/$system_fs.nix" $file;;
    		esac
        ;;
    	f2fs|ext4|xfs)
    		sed -i \
    			-e "10c\  fsBackend = \"common\";" \
    			-e "17c\  fsRoot = \"$system_fs\";" \
    		"$file"
        ;;
    	tmpfs)
    		sed -i \
    			-e "10c\  fsBackend = \"$system_fs\";" \
    			-e "132c\    ./ephemeral/tmpfs.nix" \
    		"$file"
        ;;
    esac

    case $resp2 in
    	s|sim) makeHome;;
    esac

    sed -i "20c\  users = [ \"$name\" ];" $file

    # monta o boot
    mount /dev/disk/by-label/BOOT /mnt/boot

    # instala o sistema
    warn "agora você pode instalar o sistema!"
    success "sudo nixos-install --flake /mnt/nix/git#flake"
