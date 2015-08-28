# Vhost

This script has been created to manage the virtual host files from Apache server and Nginx server.

*It has been only tested in systems Debian-like.*

# Installation

```sh
git clone git@github.com:diogocavilha/vhost.git
cd vhost/
chmod +x vhost.sh
sudo ./vhost.sh
```

## Usage

`$ vhost [options]`

## Options
#### Add/Create a host configuration.
`vhost -a` or `vhost --add`

#### Delete a host configuration.
`vhost -d <filename>` or `vhost -r <filename>` or `vhost --delete <filename>` or `vhost --remove <filename>`

#### Show created hosts.
`vhost -l` or `vhost --list`

#### Show the script help.
`vhost -h` or `vhost --help`

---

## Enjoy it!

#####Thanks for downloading this script! I hope it might help you. Let me know if it is useful to you by sending an email to [diogocavilha@gmail.com](mailto:diogocavilha@gmail.com)
