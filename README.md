## Ansible for setting of overture.bio DMS

1. `ansible-galaxy collection install -r requirements.yml` and `ansible-galaxy install -r requirements.yml -p roles` to install required Ansible roles
2. Check that hosts, host\_vars and group\_vars has the correct settings for your server (in particular check the certbot settings.
3. `ansible-playbook playbook.yml`

This currently does the machine setup for DMS (tested on Ilifu OpenStack). Installing the config in `.dms/config.yaml` isn't currently working and after setting up the config you need to run `dms cluster start`.
