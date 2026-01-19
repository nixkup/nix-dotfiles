	info() {
		printf "${BLUE}%s${RESET}\n" "$1"
	}

	success() {
		printf "${GREEN}%s${RESET}\n" "$1"
	}

	warn() {
		printf "${YELLOW}%s${RESET}\n" "$1"
	}

	error() {
		printf "${RED}%s${RESET}\n" "$1"
	}

	unidade() {
		local prompt="$1"
		local type="$2"
		local dev

		while true; do
			read -p "$prompt" dev

			case $type in
				system)
					if lsblk -dn -o NAME,TYPE "$dev" 2>/dev/null | awk '$2=="disk"' | grep -q .; then
						break
					else
						error "$dev não é um disco válido" >&2
					fi
					;;
				home)
					if lsblk "$dev" &>/dev/null; then
						scheme=$(lsblk -no TYPE "$dev")
						break
					else
						error "$dev não é um disco ou partição válida" >&2
					fi
					;;
			esac
		done

		printf "$dev"; return 0
	}

	ask_choice() {
		local prompt="$1"
		shift
		local options=("$@")
		local resp

		while true; do
			read -p "$prompt" resp
			resp="${resp,,}"
			for opt in "${options[@]}"; do
				[[ "$resp" == "$opt" ]] && { printf "$resp"; return 0; }
			done
			error "Opção inválida, tente novamente." >&2
		done
	}

	boot() {
		# reconstroi o disco com gpt
		wipefs -a $system_disk
		parted $system_disk mklabel $gptOrMbr

		# cria particao de 1GB para boot
		parted -a optimal $system_disk mkpart primary 0% 1GB

		# formata a particao de boot para fat32
		mkfs.fat -F 32 -n BOOT ${system_disk}1
		sync

		# flags de para particao boot
		parted $system_disk \
		    set 1 esp on \
			set 1 boot on \

		# cria a segunda particao usando o restante do disco
		case $separete_home in
		    s|sim)
		        parted -a optimal $system_disk mkpart primary 1GB 100%;;
			n|nao)
			    parted -a optimal \
					$system_disk mkpart primary 1G 25% \
					$system_disk mkpart primary 25% 100% \
				;;
		esac
		return 0
	}

	makeHome() {
	    case $separete_home in
		s|sim)
		    if [[ "$home_fs" != "tmpfs" ]]; then
				wipefs -a "$home_disk"

    		    [[ "$scheme" == "disk" ]] && parted "$home_disk" mklabel gpt
            fi
            ;;
		esac

		# muda nas configuracoes para o fs da home escolhido
		sed -i "18c\  fsHome = \"$home_fs\";" $file

		case $home_fs in
			ext4|xfs|btrfs)
				mkfs.$home_fs -L home -f $home_disk # cria a home com as opcoes escolhidas
				sync
				mount -o noatime $home_disk /mnt/home # monta a home
				;;
			f2fs)
				mkfs.$home_fs -l home -f $home_disk # cria a home com as opcoes escolhidas
				sync
				mount -o noatime $home_disk /mnt/home # monta a home
				;;
			zfs)
				zpool create -f -o ashift=12 -m none home $home_disk # cria um pool
				zfs create -o mountpoint=legacy home/user # cria um dataset
				mount -t zfs home/user /mnt/home # monta o dataset
				sed -i '13c\  zfsH = true;' $file
				warn "LEMBRE-SE DE EXPORTAR O POOL HOME NO TEMPHOME!"
				;;
			tmpfs)
				sed -i \
					-e "133c\    ./ephemeral/tmpfsH.nix" \
					-e "14c\  tmpfsH = true;" \
				"$file"
				;;
		esac
	}

	install() {
		# clona as configs
		git clone $github /mnt/nix/git/

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

		return 0
	}
