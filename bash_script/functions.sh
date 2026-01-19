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
