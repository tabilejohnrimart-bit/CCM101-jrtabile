# CCM101 – CLOUD COMPUTING

# ENTERPRISE CLOUD ARCHITECT
# OPERATIONAL MANUAL

**Project:** Secure Multi-Tier Web Application

**Application Stack:** WordPress + MariaDB

**Prepared by:**

Angelito P. Dimagan

Leonil F. Fuentes

John Rimart T. Tabile

**Section:** BSIT-4A

**Instructor:** Jenkielyn C. Torres

**Date:** October 2026

---

## Project Overview

This manual explains how to run, check, secure, back up, and recover the CCM101 Enterprise Cloud web application. The project uses WordPress for the website and MariaDB for its database. Docker Compose runs the two services together on Ubuntu Server inside VirtualBox.

The steps are written for the project as configured during the lab. Before using them, check that your actual file names, passwords, and port-forwarding settings match your setup.

## 1. System Details

| Item | Project configuration |
|---|---|
| Host computer | Windows laptop/desktop |
| Virtualization | Oracle VirtualBox |
| Server OS | Ubuntu Server 26.04.1 LTS |
| Project folder | `/home/ubuntu/ccm101-mission10` |
| Application | WordPress (Apache container) |
| Database | MariaDB 11 container |
| Browser address | `http://127.0.0.1:8080` |
| Published port | Host port 8080 forwarded to the VM, then Docker port 8080 to container port 80 |
| Firewall | UFW; incoming traffic denied by default, ports 8080 and 22 allowed |
| Data storage | Docker named volumes: `mariadb_data` and `wordpress_data` |
| Backup script | `scripts/automation-script.sh` |
| Backup folder | `/home/ubuntu/ccm101-mission10/backups` |

**Note:** WordPress is available on your own host computer through localhost because VirtualBox port forwarding is configured. The Ubuntu VM address shown in the lab was `10.0.2.15`, but a NAT address can change. Use the VirtualBox forwarding rule and localhost address for browser access.

## 2. Architecture and How It Works

The Windows computer runs VirtualBox. Inside VirtualBox, Ubuntu Server runs Docker. Docker Compose starts two connected containers: WordPress and MariaDB. WordPress serves the web pages and stores site content in the database. MariaDB stores the database records. Docker named volumes keep the data outside the containers, so recreating a container does not automatically erase the saved data.

**Browser request path:** Windows browser → `127.0.0.1:8080` → VirtualBox NAT port-forwarding → Ubuntu VM port 8080 → WordPress container port 80.

WordPress connects to MariaDB over the private Docker network. The database port is not published to the Windows host.

## 3. Before You Start

1. Open VirtualBox and start the Ubuntu Server VM.
2. Log in using your Ubuntu account.
3. Confirm the VM has internet access if you need to download images or updates.
4. Open a terminal and go to the project folder:

   ```bash
   cd ~/ccm101-mission10
   ```

5. Do not share passwords or put real secrets in screenshots or a public GitHub repository. The database passwords used during setup appeared in troubleshooting screenshots. Replace them with new, unique passwords before treating this project as secure.

## 4. Start, Stop, and Check the Application

### Check container status

```bash
cd ~/ccm101-mission10
sudo docker compose ps
```

**Expected result:** Both `ccm101-wordpress` and `ccm101-mariadb` show a running/Up status.

### Start the stack

```bash
cd ~/ccm101-mission10
sudo docker compose up -d
```

### Stop the stack

```bash
cd ~/ccm101-mission10
sudo docker compose down
```

This stops and removes the containers, but normally keeps the named volumes. Do not add `-v` unless you intentionally want to delete the persistent volumes and their data.

### Restart the stack

```bash
cd ~/ccm101-mission10
sudo docker compose restart
```

### View logs

```bash
sudo docker compose logs --tail=100
sudo docker compose logs --tail=100 wordpress
sudo docker compose logs --tail=100 mariadb
```

To open the website, use `http://127.0.0.1:8080` in the Windows browser. If it does not load, first check the containers, then check VirtualBox NAT port forwarding and UFW.

## 5. WordPress Administration

Open `http://127.0.0.1:8080/wp-admin/` in the browser. Sign in with the WordPress administrator username and password created during the first installation. Keep these credentials separate from the MariaDB passwords.

From the WordPress dashboard, you can create pages and posts, change the theme, and manage users. Use a strong administrator password. Install themes and plugins only from trusted sources, and update them when appropriate.

## 6. Security and Firewall

UFW is configured with a default-deny incoming policy and default-allow outgoing policy. The project allows TCP port 8080 for the web application and TCP port 22 for SSH administration. MariaDB's port 3306 should remain internal to the Docker network and should not be exposed to the host.

### Check firewall status

```bash
sudo ufw status verbose
```

### Review current rules

```bash
sudo ufw status numbered
```

If you need to configure the firewall again, allow SSH before enabling UFW so that a remote SSH session is not locked out:

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw allow 8080/tcp
sudo ufw enable
sudo ufw status verbose
```

Only allow port 22 if SSH administration is needed. If you do not need SSH, remove that rule only when you are sure you will not lock yourself out. Port 8080 is allowed for this lab so the host browser can reach WordPress. Do not publish MariaDB port 3306.

## 7. Persistent Data

The Compose configuration uses the named volumes `mariadb_data` and `wordpress_data`. The database volume stores MariaDB data; the WordPress volume stores WordPress files. These volumes survive normal container restarts and a normal `docker compose down`.

```bash
sudo docker volume ls
sudo docker volume inspect ccm101-mission10_mariadb_data
sudo docker volume inspect ccm101-mission10_wordpress_data
```

The exact volume names may include a Compose project prefix. Use the names shown by `docker volume ls`. A volume is not a backup by itself. Keep separate backup files and test that they are created.

## 8. Automated Backup

The Bash script backs up the MariaDB database to an SQL file and archives the WordPress files to a compressed `.tar.gz` file. Backups are saved in the project's `backups` folder.

### Run a backup manually

```bash
cd ~/ccm101-mission10
./scripts/automation-script.sh
```

If the script asks for your sudo password, type your Ubuntu account password and press Enter. Linux does not show characters while you type the password; this is normal. Do not wait for a long time without checking the result. The successful run should print a backup-completed message.

### Check backup files

```bash
ls -lh ~/ccm101-mission10/backups
```

A successful run should create a `database_*.sql` file and a `wordpress_*.tar.gz` file. Check that both files have a non-zero size. If the database backup is empty or an error appears, check the script and container logs before relying on the backup.

### Make sure the script is executable

```bash
chmod +x ~/ccm101-mission10/scripts/automation-script.sh
ls -l ~/ccm101-mission10/scripts/automation-script.sh
```

**Important:** Store backup copies somewhere outside the VM as well, such as a secure external drive or private storage. If the entire VM disk is lost, backups stored only inside that VM may be lost too.

## 9. Cron Schedule

Cron can run the backup script automatically. In the lab, the example schedule is 2:00 AM every day. The cron line should use the full script path and write output to a log file.

Use this as a **single line** in your crontab:

```cron
0 2 * * * /home/ubuntu/ccm101-mission10/scripts/automation-script.sh >> /home/ubuntu/ccm101-mission10/backups/cron.log 2>&1
```

Edit your personal cron table with:

```bash
crontab -e
```

Add the line above on its own line, save, and exit. Check that it was saved:

```bash
crontab -l
systemctl status cron --no-pager
```

The cron service should show active (running). The schedule uses the server's local time zone. Check the VM time with `timedatectl` if the job runs at an unexpected time.

The script uses sudo Docker commands. A scheduled job can fail if it waits for a password or other interactive input. Test the job and review the log. For a cleaner setup, configure the script to run Docker commands as a user with Docker access and avoid interactive sudo, or create a carefully restricted system-level scheduled task.

## 10. Troubleshooting

| Problem | What to check |
|---|---|
| Website does not open | Run `sudo docker compose ps`; check VirtualBox NAT forwarding from host `127.0.0.1:8080` to guest port 8080; run `sudo ufw status verbose`. |
| WordPress shows a database connection error | Run `sudo docker compose logs --tail=100 mariadb` and check that the WordPress database name, username, and password match the MariaDB settings. |
| One container is not running | Run `sudo docker compose ps` and `sudo docker compose logs --tail=100`. |
| Backup script appears stuck | Check whether it is asking for a sudo password. Password typing is invisible. Press `Ctrl+C` only if you need to stop it, then rerun and inspect the output. |
| No backup files appear | Check the script path, execute permission, project directory, and logs. Run the script manually to see errors. |
| Cron does not create a backup | Check `crontab -l`, `systemctl status cron --no-pager`, the cron log, and the full script path. |
| Changes disappear after container recreation | Confirm the named volumes are attached in `docker-compose.yml`. Do not run `docker compose down -v` unless you intend to erase volumes. |

### Useful commands

```bash
cd ~/ccm101-mission10
sudo docker compose ps
sudo docker compose logs --tail=100
sudo ufw status verbose
ls -lh backups
crontab -l
```

## 11. Backup Recovery Notes

Before restoring, stop and preserve the current application data. Never overwrite the only copy of your backup. Restore steps depend on whether you are restoring only the database or both database and WordPress files.

**Database restore outline:** Identify the correct SQL backup; copy it to a safe location; confirm the MariaDB container is running; then import the SQL file into the intended database using the MariaDB client inside the container. The exact import command depends on the database name, user, and password configured in your Compose file. Do not paste passwords into public screenshots or GitHub.

**WordPress file restore outline:** Stop WordPress before extracting the archive into the WordPress data location, confirm the archive contents first, and ensure file ownership and permissions are appropriate. Because a mistaken restore can overwrite current site data, perform this only after making a separate copy of the current volumes or after asking the project administrator/instructor to verify the target path.

For the lab defense, demonstrate that backups are created and explain how you would protect and restore them. Do not claim a full disaster-recovery test is successful until you have actually performed and verified a restore.

## 12. Maintenance Checklist

- [ ] Check container status with `docker compose ps`.
- [ ] Review recent WordPress and MariaDB logs.
- [ ] Check UFW rules and confirm MariaDB is not publicly exposed.
- [ ] Confirm the latest database and WordPress backup files exist and are non-empty.
- [ ] Review the cron schedule and cron log.
- [ ] Keep Ubuntu, Docker images, WordPress, themes, and plugins updated carefully.
- [ ] Keep a secure copy of backups outside the VM.
- [ ] Do not publish passwords, `.env` files, or private backups to GitHub.

## 13. Project Files and GitHub

The required Mission 10 repository folder should contain the README, architecture diagram, Docker Compose file, automation script, operational manual, and final reflection. Keep filenames consistent with the instructor's required structure.

Before committing to GitHub, inspect the files and remove passwords, private keys, personal data, and backup archives. The Compose file should use safe placeholder values or environment variables for secrets in a public repository. Never upload the backups folder if it contains real site or user data.

Recommended repository files:

- `README.md`
- `architecture-diagram.png`
- `docker-compose.yml`
- `automation-script.sh`
- `operational-manual.md`
- `final-reflection.md`

## 14. Final Notes

This is a student lab deployment, not a production-ready public service. Before exposing it to the internet, add HTTPS, safer secret management, restricted administration access, off-VM backups, tested restore procedures, and a regular update plan. The student is responsible for verifying the final configuration on the actual VM.
