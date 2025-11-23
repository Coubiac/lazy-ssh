# lazy-ssh

`lazy-ssh` is a small wrapper around `ssh` that automatically updates your `~/.ssh/config` based on the `ssh` commands you actually use.

Less manual editing, more "I use it once, it is remembered".

## Features

- Automatically creates `Host` entries in `~/.ssh/config` from commands like:
  - `ssh user@host`
  - `ssh user@host -p 2222`
  - `ssh -i ~/.ssh/id_ed25519 user@host`
- Handles `-p`:
  - adds or updates the `Port` line in the matching `Host` block.
- Handles `-i`:
  - adds or updates the `IdentityFile` line in the matching `Host` block.
- Handles raw IPs:
  - if you connect to `ssh root@192.168.10.42`, `lazy-ssh` asks for a friendly name (for example `srv-lab`),
  - it then creates a `Host` entry that contains both:
    ```text
    Host srv-lab 192.168.10.42
      HostName 192.168.10.42
      User root
    ```
  - you can later use:
    - `ssh srv-lab`
    - or `ssh 192.168.10.42`

`lazy-ssh` does not replace `ssh`. It parses the arguments, maintains `~/.ssh/config`, and then calls the real `ssh` command with the original arguments.

## Installation

### 1. Download the script

For example into `~/.config`:

```bash
mkdir -p ~/.config
curl -o ~/.config/lazy-ssh.sh https://raw.githubusercontent.com/Coubiac/lazy-ssh/main/lazy-ssh.sh
```

### 2. Load it from your shell config

In your `~/.bashrc` or `~/.zshrc`, add:

```bash
# lazy-ssh: ssh auto config wrapper
if [ -f "$HOME/.config/lazy-ssh.sh" ]; then
  . "$HOME/.config/lazy-ssh.sh"
fi
```


Then reload your shell:

```bash
source ~/.bashrc
# or
source ~/.zshrc
```

The script defines a `lazy_ssh` function and an alias:

```bash
alias ssh=lazy_ssh
```

So you keep using the `ssh` command as usual.

## Usage

Once installed, you just use `ssh` as you normally would.  
`lazy-ssh` works behind the scenes.

### First simple connection

```bash
ssh alice@server.example.com
```

`lazy-ssh` will create something like this in `~/.ssh/config`:

```text
Host server.example.com
  HostName server.example.com
  User alice
```

Next time you can simply type:

```bash
ssh server.example.com
```

### Connection with custom port

```bash
ssh alice@server.example.com -p 2222
```

If no entry exists yet, `lazy-ssh` creates:

```text
Host server.example.com
  HostName server.example.com
  User alice
  Port 2222
```

If an entry already exists, it updates the `Port` field.

### Connection with specific key

```bash
ssh -i ~/.ssh/id_ed25519_admin root@192.168.10.42 -p 2222
```

Behavior:

- If there is no matching entry for this IP yet:

  `lazy-ssh` prompts you:

  ```text
  New IP detected: 192.168.10.42
  Name to use for this host (ex: srv-lab):
  ```

  You type for example:

  ```text
  srv-lab
  ```

  It creates:

  ```text
  Host srv-lab 192.168.10.42
    HostName 192.168.10.42
    User root
    Port 2222
    IdentityFile ~/.ssh/id_ed25519_admin
  ```

- If an entry already exists for this host or IP:

  `lazy-ssh` updates the existing block:

  - `User` (if you used `user@host`),
  - `Port` (if you passed `-p`),
  - `IdentityFile` (if you passed `-i`).

You can then connect with:

```bash
ssh srv-lab
# or
ssh 192.168.10.42
```

without typing `-i` or `-p` again.

## Backup of ~/.ssh/config

As a safety measure, you can create a backup before your first use:

```bash
cp ~/.ssh/config ~/.ssh/config.bak.$(date +%F-%H%M)
```

`lazy-ssh`:

- only modifies `Host` blocks that contain the target host or IP,
- does not delete other entries.

But having a backup never hurts.


## Limitations

The script does not handle every advanced SSH use case, for example:

- complex `-o` options,
- advanced `ProxyJump` or `ProxyCommand` chains.

The main focus is on:

- `Host`
- `HostName`
- `User`
- `Port`
- `IdentityFile`

For more advanced setups, you can still edit `~/.ssh/config` manually.


## Contributing

Contributions are welcome:

- bug fixes,
- better host detection,
- support for more SSH options,
- automated tests,
- advanced usage examples.

Fork, open issues, and PRs are all appreciated.

## License

This project is released under the Unlicense (public domain).

You can freely use, modify, and redistribute it.