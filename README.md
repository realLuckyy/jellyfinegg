# JellyfinEgg 🎬

**Professional Jellyfin Media Server for Pterodactyl Panel**

Developed by **Luckyy** | Contact: `trudge.onyx2223@eagereverest.com`

A ready-to-deploy Pterodactyl egg that allows game server hosting providers and communities to offer **Jellyfin Media Server** alongside their game servers. No complex setup required - just import and deploy!

[![Jellyfin](https://img.shields.io/badge/Jellyfin-Latest-blue.svg)](https://jellyfin.org/)
[![Pterodactyl](https://img.shields.io/badge/Pterodactyl-Compatible-green.svg)](https://pterodactyl.io/)
[![Docker](https://img.shields.io/badge/Docker-Hub-blue.svg)](https://hub.docker.com/r/0xluckyy/jellyfin-pterodactyl)

## ✨ Features

- 🚀 **One-Click Deploy** - Import egg and instantly create Jellyfin servers
- 🔧 **Auto-Configuration** - Automatic network setup prevents common issues  
- 🎨 **Professional UI** - Clean, working Jellyfin experience out of the box
- 📱 **Cross-Platform** - Works on web, mobile, TV apps, and desktop clients
- 🛡️ **Secure** - Proper user permissions and container isolation
- ⚡ **Optimized** - Built on official Jellyfin Docker image for reliability

## Quick Start

### Prerequisites

- Pterodactyl Panel v1.x
- Docker support on Wings nodes
- Sufficient resources (2GB RAM recommended minimum)

### Installation

1. **Import the Egg**
   ```bash
   # Download the egg file
   wget https://raw.githubusercontent.com/your-repo/jellyfinegg/main/egg-jellyfin.json
   
   # Import via Pterodactyl admin panel:
   # Admin → Nests → Import Egg → Select egg-jellyfin.json
   ```

2. **Create a New Server**
   - Navigate to your Pterodactyl panel
   - Create a new server using the "JellyfinEgg" egg
   - **IMPORTANT**: Allocate port **8096** to the server (required for web access)
   - Optional: Allocate port **8920** for HTTPS (if needed)
   - Configure other server settings (RAM: 1GB minimum, 2GB+ recommended)
   - Start the server

3. **Initial Setup**
   - Wait for server installation to complete
   - Access Jellyfin web interface at `http://YOUR_SERVER_IP:8096`
   - You'll see a friendly "SERVER IS READY!" message in the console
   - Complete the initial setup wizard (create admin account, add libraries)
   - Start streaming your media!
   - Add your media libraries

## Configuration

### Server Variables

The following variables can be configured in the Pterodactyl panel:

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `JELLYFIN_VERSION` | Jellyfin version to install | `latest` | Yes |
| `SERVER_PORT` | HTTP port for web interface | `8096` | Yes |
| `HTTPS_PORT` | HTTPS port (if SSL enabled) | `8920` | No |
| `ENABLE_DLNA` | Enable DLNA functionality | `true` | Yes |
| `AUTO_UPDATE` | Automatically update Jellyfin | `false` | Yes |

### Port Allocation

The following ports are used by Jellyfin:

- **8096** (HTTP): Main web interface (configurable)
- **8920** (HTTPS): Secure web interface (configurable)
- **7359** (UDP): Auto-discovery
- **1900** (UDP): DLNA discovery

### Directory Structure

```
/home/container/
├── data/          # Jellyfin database and metadata
├── config/        # Configuration files
├── cache/         # Transcoding cache
├── logs/          # Application logs
├── media/         # Media files (mount point)
└── backups/       # Automated backups
```

## Usage

### Accessing Jellyfin

Once your server is running, you can access Jellyfin through:

- **Web Interface**: `http://your-allocated-ip:8096` (use the IP shown in Pterodactyl panel)
- **Setup Wizard**: `http://your-allocated-ip:8096/web/index.html#!/wizardstart.html`
- **Direct Login**: `http://your-allocated-ip:8096/web/index.html#!/login.html`

**Note:** Use the specific IP address allocated by Pterodactyl, not `localhost` or `127.0.0.1`
- **Mobile Apps**: Available for iOS, Android, and other platforms
- **Desktop Apps**: Available for Windows, macOS, and Linux
- **Smart TV Apps**: Available for most smart TV platforms

### Managing Your Server

The egg includes several management scripts accessible via the Pterodactyl console:

#### Server Status
```bash
./scripts/jellyfin-manage.sh status
```

#### Create Backup
```bash
./scripts/jellyfin-manage.sh backup
```

#### Restore from Backup
```bash
./scripts/jellyfin-manage.sh restore /home/container/backups/backup-file.tar.gz
```

#### Clean Cache
```bash
./scripts/jellyfin-manage.sh clean-cache
```

#### View Logs
```bash
./scripts/jellyfin-manage.sh logs 100
```

#### Update Jellyfin
```bash
./scripts/update.sh check          # Check for updates
./scripts/update.sh update         # Update to latest version
```

### Adding Media

1. **Upload Media Files**
   - Use the Pterodactyl file manager to upload media to `/home/container/media/`
   - Organize files in folders (Movies, TV Shows, Music, etc.)

2. **Configure Libraries**
   - Access Jellyfin web interface
   - Go to Dashboard → Libraries
   - Add new libraries pointing to your media folders
   - Wait for Jellyfin to scan and organize your media

## Advanced Configuration

### Hardware Acceleration

For GPU transcoding (if your server supports it):

1. **Modify Docker Configuration**
   ```yaml
   # In docker-compose.yml, uncomment:
   devices:
     - /dev/dri:/dev/dri
   ```

2. **Configure in Jellyfin**
   - Dashboard → Playback → Transcoding
   - Select appropriate hardware acceleration method
   - Test with a transcoding session

### SSL/HTTPS Setup

1. **Obtain SSL Certificate**
   ```bash
   # Generate self-signed certificate (development only)
   openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes
   
   # Move certificates to config directory
   mv cert.pem key.pem /home/container/config/
   ```

2. **Configure HTTPS in Jellyfin**
   - Dashboard → Networking
   - Enable HTTPS
   - Set certificate paths
   - Restart server

### External Access

To access your Jellyfin server from outside your network:

1. **Configure Firewall**
   - Open ports 8096 (HTTP) and 8920 (HTTPS) in your firewall
   - Configure port forwarding in your router if needed

2. **Set Public URL**
   - Dashboard → Networking → Published Server URL
   - Set to your external IP or domain name

## Troubleshooting

### Common Issues

**Server won't start**
- Check available disk space and memory
- Verify port conflicts with `netstat -tulpn | grep :8096`
- Review logs: `./scripts/jellyfin-manage.sh logs`

**Can't access web interface**
- ✅ Use the allocated IP from Pterodactyl panel (e.g., `http://138.201.222.190:8096`)
- ❌ Don't use `localhost:8096` - this won't work with Pterodactyl
- Verify server is running and shows "Kestrel is listening on 0.0.0.0"
- Check firewall settings on the host server
- Try direct setup URL: `http://your-ip:8096/web/index.html#!/wizardstart.html`

**Connection errors after setup**
- Access main interface directly: `http://your-ip:8096/web/index.html`
- Or try login page: `http://your-ip:8096/web/index.html#!/login.html`

**Transcoding issues**
- Check available CPU/RAM resources
- Verify FFmpeg installation
- Consider enabling hardware acceleration

**Media not showing**
- Verify file permissions: `ls -la /home/container/media/`
- Check library scan progress in Dashboard
- Ensure media formats are supported

### Performance Optimization

**For better performance:**

1. **Increase Resources**
   - Allocate more RAM for transcoding
   - Use SSD storage for cache directory
   - Ensure adequate CPU for concurrent streams

2. **Optimize Settings**
   - Enable hardware acceleration if available
   - Adjust transcoding settings for your needs
   - Configure appropriate cache sizes

3. **Network Optimization**
   - Use wired connections when possible
   - Optimize video quality settings per client
   - Consider CDN for remote access

### Backup and Restore

**Automated Backups**
```bash
# Create daily backup cron job
echo "0 2 * * * /home/container/scripts/jellyfin-manage.sh backup" | crontab -
```

**Manual Backup**
```bash
./scripts/jellyfin-manage.sh backup
```

**Restore Process**
```bash
# List available backups
./scripts/jellyfin-manage.sh list-backups

# Restore from specific backup
./scripts/jellyfin-manage.sh restore /home/container/backups/jellyfin-backup-20250922-120000.tar.gz
```

## Security Considerations

### User Management
- Create individual user accounts instead of sharing admin access
- Configure appropriate parental controls
- Use strong passwords and consider enabling two-factor authentication

### Network Security
- Use HTTPS for external access
- Consider VPN for remote access instead of port forwarding
- Regularly update Jellyfin to latest version

### File Permissions
```bash
# Ensure proper permissions
chown -R jellyfin:jellyfin /home/container/data
chmod 755 /home/container/media
```

## Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Setup
```bash
git clone https://github.com/your-repo/jellyfinegg.git
cd jellyfinegg

# Test the egg configuration
docker build -t jellyfin-pterodactyl ./docker/
docker run -p 8096:8096 jellyfin-pterodactyl
```

## Support

- **Documentation**: [Jellyfin Documentation](https://jellyfin.org/docs/)
- **Community**: [Jellyfin Forum](https://forum.jellyfin.org/)
- **Issues**: [GitHub Issues](https://github.com/your-repo/jellyfinegg/issues)
- **Discord**: [Pterodactyl Discord](https://discord.gg/pterodactyl)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Jellyfin Team](https://jellyfin.org/) for the amazing media server software
- [Pterodactyl Panel](https://pterodactyl.io/) for the server management platform
- Community contributors and testers

---

**Note**: This is an unofficial egg created by the community. For official Jellyfin support, please visit the [Jellyfin website](https://jellyfin.org/).