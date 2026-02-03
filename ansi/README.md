# Run script on multiple machine


## Quick start

Edit your hosts inside `hosts.ini` file.

Test connection:

```bash
ansible nodes -i hosts.ini -m ping --ask-pass
```

Run scripts, e.g install nvm on all hosts:

```bash
ansible-playbook -i hosts.ini install_nvm.yml --ask-pass
```

