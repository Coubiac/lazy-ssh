#!/bin/bash
update_ssh_entry() {
  local host_token="$1"
  local user="$2"
  local port="$3"
  local identity="$4"
  local ssh_config="$HOME/.ssh/config"
  local tmp
  tmp=$(mktemp)

  awk -v host_token="$host_token" -v user="$user" -v port="$port" -v identity="$identity" '
    BEGIN { in_block=0; has_user=0; has_port=0; has_identity=0 }

    /^Host[ \t]/ {
      if (in_block) {
        if (user != "" && !has_user)      print "  User " user
        if (port != "" && port != "22" && !has_port) print "  Port " port
        if (identity != "" && !has_identity) print "  IdentityFile " identity
      }

      in_block=0; has_user=0; has_port=0; has_identity=0

      split($0, a, /[ \t]+/)
      for (i=2; i<=NF; i++) {
        if (a[i] == host_token) {
          in_block=1
          break
        }
      }

      print
      next
    }

    {
      if (in_block) {
        if ($1 == "User" && user != "") {
          print "  User " user
          has_user=1
          next
        }
        if ($1 == "Port" && port != "" && port != "22") {
          print "  Port " port
          has_port=1
          next
        }
        if ($1 == "IdentityFile" && identity != "") {
          print "  IdentityFile " identity
          has_identity=1
          next
        }
      }
      print
    }

    END {
      if (in_block) {
        if (user != "" && !has_user)      print "  User " user
        if (port != "" && port != "22" && !has_port) print "  Port " port
        if (identity != "" && !has_identity) print "  IdentityFile " identity
      }
    }
  ' "$ssh_config" > "$tmp" && mv "$tmp" "$ssh_config"
}

lazy-ssh() {
  local args=("$@")

  if [[ ${#args[@]} -eq 0 ]]; then
    command ssh "$@"
    return
  fi

  local target=""
  local port=22
  local identity=""
  local i=0
  local user_explicit=0

  while (( i < ${#args[@]} )); do
    local a="${args[i]}"

    case "$a" in
      -p)
        ((i++))
        if (( i < ${#args[@]} )); then
          port="${args[i]}"
        fi
        ;;
      -i)
        ((i++))
        if (( i < ${#args[@]} )); then
          identity="${args[i]}"
        fi
        ;;
      -*)
        ;;
      *)
        target="$a"
        break
        ;;
    esac
    ((i++))
  done

  if [[ -z "$target" ]]; then
    command ssh "$@"
    return
  }

  local user host
  if [[ "$target" == *"@"* ]]; then
    user="${target%@*}"
    host="${target#*@}"
    user_explicit=1
  else
    user="$USER"
    host="$target"
    user_explicit=0
  fi

  local ssh_config="$HOME/.ssh/config"
  [[ -f "$ssh_config" ]] || touch "$ssh_config"

  local host_re
  host_re=$(printf '%s\n' "$host" | sed "s/[][.^$*+?{}|()\\/]/\\\\&/g")

  if grep -qE "^Host[[:space:]].*${host_re}([[:space:]]|\$)" "$ssh_config"; then
    local user_for_update=""
    [[ $user_explicit -eq 1 ]] && user_for_update="$user"

    update_ssh_entry "$host" "$user_for_update" "$port" "$identity"
  else
    local alias="$host"

    if [[ "$host" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      echo
      echo "Nouvelle IP détectée: $host"
      read -rp "Nom à utiliser pour cette machine (ex: srv-lab) : " alias_input
      if [[ -n "$alias_input" ]]; then
        alias="$alias_input"
      fi

      echo "Ajout d une entrée SSH pour \"$alias\" (IP $host)"
      {
        echo ""
        echo "Host $alias $host"
        echo "  HostName $host"
        echo "  User $user"
        [[ "$port" != 22 ]] && echo "  Port " $port
        [[ -n "$identity" ]] && echo "  IdentityFile $identity"
      } >> "$ssh_config"
    else
      echo "Ajout d une entrée SSH pour \"$host\""
      {
        echo ""
        echo "Host $host"
        echo "  HostName $host"
        echo "  User $user"
        [[ "$port" != 22 ]] && echo "  Port " $port
        [[ -n "$identity" ]] && echo "  IdentityFile $identity"
      } >> "$ssh_config"
    fi
  fi

  command ssh "$@"
}

alias ssh=lazy_ssh