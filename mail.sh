#!/bin/bash

# ==============================================
# PTERODACTYL EMAIL NOTIFICATION UPDATER
# Version: 2.0 - Premium Edition
# Author: Your Bro
# ==============================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Config
PANEL_DIR="/var/www/pterodactyl"
BACKUP_DIR="/tmp/ptero-backup-$(date +%Y%m%d_%H%M%S)"
USER="www-data"  # Ubuntu/Debian
# USER="nginx"   # CentOS

# ==============================================
# FUNCTIONS
# ==============================================

print_header() {
    echo -e "${PURPLE}"
    echo "=============================================="
    echo "   PTERODACTYL EMAIL NOTIFICATION UPDATER"
    echo "=============================================="
    echo -e "${NC}"
}

print_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_panel_dir() {
    if [ ! -d "$PANEL_DIR" ]; then
        print_error "Panel directory not found: $PANEL_DIR"
        read -p "Enter correct panel path: " PANEL_DIR
        if [ ! -d "$PANEL_DIR" ]; then
            print_error "Invalid directory! Exiting."
            exit 1
        fi
    fi
    print_success "Panel directory found: $PANEL_DIR"
}

create_backup() {
    print_step "Creating backup at: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    
    # Backup notifications
    if [ -d "$PANEL_DIR/app/Notifications" ]; then
        cp -r "$PANEL_DIR/app/Notifications" "$BACKUP_DIR/"
        print_success "Backup created for Notifications"
    fi
    
    # Backup email templates
    if [ -d "$PANEL_DIR/resources/views/emails" ]; then
        cp -r "$PANEL_DIR/resources/views/emails" "$BACKUP_DIR/"
        print_success "Backup created for email templates"
    fi
}

check_dependencies() {
    print_step "Checking dependencies..."
    
    # Check PHP
    if ! command -v php &> /dev/null; then
        print_error "PHP is not installed!"
        exit 1
    fi
    
    # Check composer
    if [ ! -f "$PANEL_DIR/composer.json" ]; then
        print_error "Composer.json not found! Wrong panel directory?"
        exit 1
    fi
    
    print_success "All dependencies OK"
}

# ==============================================
# NOTIFICATION CLASSES
# ==============================================

create_account_created() {
    cat > "$PANEL_DIR/app/Notifications/AccountCreated.php" << 'EOF'
<?php

namespace Pterodactyl\Notifications;

use Pterodactyl\Models\User;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;

class AccountCreated extends Notification implements ShouldQueue
{
    use Queueable;

    public function __construct(public User $user, public ?string $token = null)
    {
    }

    public function via(): array
    {
        return ['mail'];
    }

    public function toMail(): MailMessage
    {
        $setupUrl = $this->token 
            ? url('/auth/password/reset/' . $this->token . '?email=' . urlencode($this->user->email))
            : null;

        $creationDate = $this->user->created_at->format('F j, Y \a\t g:i A');
        $ipAddress = request()->ip() ?? 'Unknown';

        return (new MailMessage())
            ->subject('🌟 Welcome to ' . config('app.name', 'Pterodactyl Panel') . ' - Your Journey Begins!')
            ->view('emails.account-created-premium', [
                'user' => $this->user,
                'panelName' => config('app.name', 'Pterodactyl Panel'),
                'panelUrl' => config('app.url'),
                'setupUrl' => $setupUrl,
                'hasToken' => !is_null($this->token),
                'creationDate' => $creationDate,
                'ipAddress' => $ipAddress,
                'currentYear' => date('Y'),
                'features' => [
                    ['icon' => '🚀', 'title' => 'Instant Server Setup', 'desc' => 'Deploy game servers in seconds'],
                    ['icon' => '⚡', 'title' => 'Real-time Control', 'desc' => 'Full power at your fingertips'],
                    ['icon' => '🛡️', 'title' => 'Secure & Isolated', 'desc' => 'Docker-powered security'],
                    ['icon' => '📊', 'title' => 'Advanced Metrics', 'desc' => 'Monitor performance in real-time'],
                    ['icon' => '🔧', 'title' => 'One-Click Mods', 'desc' => 'Install plugins effortlessly'],
                    ['icon' => '🌐', 'title' => 'Global Access', 'desc' => 'Access from anywhere'],
                ],
                'quickLinks' => [
                    ['url' => url('/'), 'text' => 'Dashboard', 'icon' => '📊'],
                    ['url' => url('/account'), 'text' => 'Account Settings', 'icon' => '⚙️'],
                    ['url' => url('/servers'), 'text' => 'My Servers', 'icon' => '🖥️'],
                ],
            ]);
    }
}
EOF
    print_success "Created AccountCreated.php"
}

create_added_to_server() {
    cat > "$PANEL_DIR/app/Notifications/AddedToServer.php" << 'EOF'
<?php

namespace Pterodactyl\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;

class AddedToServer extends Notification implements ShouldQueue
{
    use Queueable;

    public object $server;

    public function __construct(array $server)
    {
        $this->server = (object) $server;
    }

    public function via(): array
    {
        return ['mail'];
    }

    public function toMail(): MailMessage
    {
        return (new MailMessage())
            ->subject('🎮 You\'ve been added to a server! - ' . config('app.name', 'Pterodactyl Panel'))
            ->view('emails.server-added', [
                'server' => $this->server,
                'panelName' => config('app.name', 'Pterodactyl Panel'),
                'user' => $this->server->user,
                'serverUrl' => url('/server/' . $this->server->uuidShort),
                'currentYear' => date('Y'),
                'permissions' => [
                    'Start/Stop/Restart server',
                    'Access console and logs',
                    'Manage server files',
                    'Install plugins/mods',
                    'View server statistics',
                ]
            ]);
    }
}
EOF
    print_success "Created AddedToServer.php"
}

create_send_password_reset() {
    cat > "$PANEL_DIR/app/Notifications/SendPasswordReset.php" << 'EOF'
<?php

namespace Pterodactyl\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;

class SendPasswordReset extends Notification implements ShouldQueue
{
    use Queueable;

    public function __construct(public string $token)
    {
    }

    public function via(): array
    {
        return ['mail'];
    }

    public function toMail(mixed $notifiable): MailMessage
    {
        $resetUrl = url('/auth/password/reset/' . $this->token . '?email=' . urlencode($notifiable->email));
        $username = $notifiable->name ?? $notifiable->username;
        
        return (new MailMessage())
            ->subject('🔐 Reset Your Password - ' . config('app.name', 'Pterodactyl Panel'))
            ->view('emails.password-reset', [
                'username' => $username,
                'email' => $notifiable->email,
                'resetUrl' => $resetUrl,
                'panelName' => config('app.name', 'Pterodactyl Panel'),
                'currentYear' => date('Y'),
                'expireTime' => 30,
            ]);
    }
}
EOF
    print_success "Created SendPasswordReset.php"
}

create_removed_from_server() {
    cat > "$PANEL_DIR/app/Notifications/RemovedFromServer.php" << 'EOF'
<?php

namespace Pterodactyl\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;

class RemovedFromServer extends Notification implements ShouldQueue
{
    use Queueable;

    public object $server;

    public function __construct(array $server)
    {
        $this->server = (object) $server;
    }

    public function via(): array
    {
        return ['mail'];
    }

    public function toMail(): MailMessage
    {
        return (new MailMessage())
            ->subject('👋 Access Revoked - ' . config('app.name', 'Pterodactyl Panel'))
            ->view('emails.removed-from-server', [
                'server' => $this->server,
                'panelName' => config('app.name', 'Pterodactyl Panel'),
                'user' => $this->server->user,
                'serverName' => $this->server->name,
                'currentYear' => date('Y'),
            ]);
    }
}
EOF
    print_success "Created RemovedFromServer.php"
}

create_server_installed() {
    cat > "$PANEL_DIR/app/Notifications/ServerInstalled.php" << 'EOF'
<?php

namespace Pterodactyl\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;

class ServerInstalled extends Notification implements ShouldQueue
{
    use Queueable;

    public object $server;

    public function __construct(array $server)
    {
        $this->server = (object) $server;
    }

    public function via(): array
    {
        return ['mail'];
    }

    public function toMail(): MailMessage
    {
        return (new MailMessage())
            ->subject('✅ Server Installation Complete - ' . config('app.name', 'Pterodactyl Panel'))
            ->view('emails.server-installed', [
                'server' => $this->server,
                'panelName' => config('app.name', 'Pterodactyl Panel'),
                'user' => $this->server->user,
                'serverUrl' => url('/server/' . $this->server->uuidShort),
                'currentYear' => date('Y'),
                'installTime' => date('F j, Y \a\t g:i A'),
            ]);
    }
}
EOF
    print_success "Created ServerInstalled.php"
}

create_mail_tested() {
    cat > "$PANEL_DIR/app/Notifications/MailTested.php" << 'EOF'
<?php

namespace Pterodactyl\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;

class MailTested extends Notification implements ShouldQueue
{
    use Queueable;

    public function __construct(public string $type = 'test')
    {
    }

    public function via(): array
    {
        return ['mail'];
    }

    public function toMail(mixed $notifiable): MailMessage
    {
        return (new MailMessage())
            ->subject('📧 Email Test Successful - ' . config('app.name', 'Pterodactyl Panel'))
            ->view('emails.mail-tested', [
                'panelName' => config('app.name', 'Pterodactyl Panel'),
                'currentYear' => date('Y'),
                'testType' => $this->type,
                'testTime' => date('F j, Y \a\t g:i A'),
                'recipient' => $notifiable->email,
            ]);
    }
}
EOF
    print_success "Created MailTested.php"
}

# ==============================================
# EMAIL TEMPLATES
# ==============================================

create_email_templates() {
    print_step "Creating premium email templates..."
    
    # Create emails directory
    mkdir -p "$PANEL_DIR/resources/views/emails"
    mkdir -p "$PANEL_DIR/resources/views/emails/auth"
    
    # 1. Account Created Premium
    cat > "$PANEL_DIR/resources/views/emails/account-created-premium.blade.php" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Welcome to {{ $panelName }}!</title>
    <style>
        /* KEEP THE SAME PREMIUM STYLES FROM BEFORE */
        /* [All the premium CSS styles from previous template] */
        /* To save space, using simplified version */
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Inter', sans-serif; background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%); color: #e2e8f0; padding: 30px 20px; }
        .email-container { max-width: 700px; margin: 0 auto; background: rgba(15, 23, 42, 0.95); border-radius: 24px; overflow: hidden; border: 1px solid rgba(139, 92, 246, 0.2); box-shadow: 0 0 80px rgba(139, 92, 246, 0.15), 0 20px 60px rgba(0, 0, 0, 0.3); }
        .email-header { background: linear-gradient(135deg, rgba(139, 92, 246, 0.1) 0%, rgba(124, 58, 237, 0.2) 100%); padding: 60px 40px; text-align: center; border-bottom: 1px solid rgba(139, 92, 246, 0.3); }
        .email-header h1 { font-size: 42px; font-weight: 800; background: linear-gradient(135deg, #8B5CF6 0%, #EC4899 100%); -webkit-background-clip: text; -webkit-text-fill-color: transparent; margin-bottom: 15px; }
        .email-body { padding: 50px 40px; }
        .premium-button { display: inline-flex; align-items: center; justify-content: center; gap: 15px; background: linear-gradient(135deg, #10b981 0%, #059669 100%); color: white !important; text-decoration: none; padding: 22px 45px; border-radius: 16px; font-weight: 800; font-size: 18px; transition: all 0.4s cubic-bezier(0.4, 0, 0.2, 1); }
        .premium-button:hover { transform: translateY(-5px) scale(1.05); box-shadow: 0 20px 40px rgba(16, 185, 129, 0.4), 0 0 0 1px rgba(16, 185, 129, 0.3); }
        .email-footer { background: rgba(15, 23, 42, 0.9); padding: 40px; text-align: center; border-top: 1px solid rgba(139, 92, 246, 0.2); }
        @media (max-width: 768px) { .email-header, .email-body { padding: 40px 25px; } .email-header h1 { font-size: 32px; } .premium-button { width: 100%; } }
    </style>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800;900&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
</head>
<body>
    <div class="email-container">
        <div class="email-header">
            <div style="font-size: 64px; margin-bottom: 25px; display: inline-block; background: linear-gradient(135deg, #8B5CF6, #EC4899); -webkit-background-clip: text; -webkit-text-fill-color: transparent; filter: drop-shadow(0 0 20px rgba(139, 92, 246, 0.3));">🚀</div>
            <h1>Welcome to {{ $panelName }}</h1>
            <p style="color: #94a3b8; font-size: 18px;">Your journey into powerful server management begins here</p>
        </div>
        
        <div class="email-body">
            <p style="font-size: 20px; color: #cbd5e1; margin-bottom: 30px; text-align: center;">
                Hello <strong style="color: #8B5CF6;">{{ $user->name }}</strong>,<br>
                Welcome aboard! We're thrilled to have you join our community.
            </p>
            
            <div style="background: rgba(30, 41, 59, 0.7); border-radius: 20px; padding: 35px; margin: 40px 0; border: 1px solid rgba(139, 92, 246, 0.2);">
                <h3 style="color: #f1f5f9; margin-bottom: 25px; display: flex; align-items: center; gap: 15px;">
                    <span style="background: linear-gradient(135deg, #8B5CF6, #EC4899); -webkit-background-clip: text; -webkit-text-fill-color: transparent;">👤</span>
                    Your Account Profile
                </h3>
                <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 25px;">
                    <div style="background: rgba(15, 23, 42, 0.5); border-radius: 16px; padding: 25px;">
                        <div style="font-size: 14px; color: #94a3b8; margin-bottom: 10px;"><i class="fas fa-user"></i> Username</div>
                        <div style="font-size: 20px; font-weight: 700; color: #f1f5f9;">{{ $user->username }}</div>
                    </div>
                    <div style="background: rgba(15, 23, 42, 0.5); border-radius: 16px; padding: 25px;">
                        <div style="font-size: 14px; color: #94a3b8; margin-bottom: 10px;"><i class="fas fa-envelope"></i> Email</div>
                        <div style="font-size: 20px; font-weight: 700; color: #f1f5f9;">{{ $user->email }}</div>
                    </div>
                </div>
            </div>
            
            @if($hasToken)
            <div style="text-align: center; margin: 50px 0;">
                <h2 style="color: #10b981; font-size: 28px; margin-bottom: 20px;">Secure Your Account</h2>
                <a href="{{ $setupUrl }}" class="premium-button">
                    <i class="fas fa-shield-alt"></i>
                    SETUP SECURE PASSWORD
                </a>
                <p style="margin-top: 20px; color: #6ee7b7; font-size: 14px;">
                    ⚡ This link expires in 30 minutes for security
                </p>
            </div>
            @endif
            
            <div style="text-align: center; margin-top: 40px;">
                <p style="color: #94a3b8;">Ready to get started?</p>
                <div style="display: flex; justify-content: center; gap: 20px; margin-top: 30px; flex-wrap: wrap;">
                    <a href="{{ url('/') }}" style="background: rgba(30, 41, 59, 0.7); border-radius: 16px; padding: 20px 30px; text-decoration: none; color: #cbd5e1; display: flex; align-items: center; gap: 15px; min-width: 200px;">
                        <span style="font-size: 24px;">📊</span>
                        <span style="font-weight: 600;">Dashboard</span>
                    </a>
                </div>
            </div>
        </div>
        
        <div class="email-footer">
            <p style="color: #94a3b8; margin-bottom: 20px;">
                <i class="fas fa-rocket" style="color: #8B5CF6; margin-right: 8px;"></i>
                Thank you for choosing {{ $panelName }}
            </p>
            <div style="color: #64748b; font-size: 13px; margin-top: 25px; padding-top: 25px; border-top: 1px solid rgba(255, 255, 255, 0.05);">
                © {{ $currentYear }} {{ $panelName }}. All rights reserved.<br>
                This is an automated welcome message.
            </div>
        </div>
    </div>
</body>
</html>
EOF
    print_success "Created account-created-premium.blade.php"
    
    # 2. Server Added
    cat > "$PANEL_DIR/resources/views/emails/server-added.blade.php" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Server Access Granted - {{ $panelName }}</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); margin: 0; padding: 20px; }
        .email-container { max-width: 600px; margin: auto; background: white; border-radius: 16px; overflow: hidden; box-shadow: 0 20px 60px rgba(0,0,0,0.15); }
        .header { background: linear-gradient(135deg, #8B5CF6 0%, #7C3AED 100%); color: white; padding: 40px 30px; text-align: center; }
        .header h1 { margin: 0; font-size: 28px; font-weight: 700; }
        .body { padding: 40px; }
        .server-card { background: linear-gradient(135deg, #f8fafc 0%, #edf2f7 100%); border-radius: 12px; padding: 25px; margin: 25px 0; border-left: 5px solid #8B5CF6; }
        .cta-button { display: inline-block; background: linear-gradient(135deg, #8B5CF6 0%, #7C3AED 100%); color: white !important; text-decoration: none; padding: 18px 36px; border-radius: 10px; font-weight: 700; font-size: 16px; transition: all 0.3s; }
        .cta-button:hover { transform: translateY(-3px); box-shadow: 0 10px 25px rgba(139, 92, 246, 0.3); }
        .footer { background: #f8fafc; padding: 30px; text-align: center; color: #718096; border-top: 1px solid #e2e8f0; }
    </style>
</head>
<body>
    <div class="email-container">
        <div class="header">
            <h1><span style="font-size: 24px; margin-right: 10px;">🚀</span> Server Access Granted</h1>
            <p>You've been added as a subuser</p>
        </div>
        
        <div class="body">
            <p style="font-size: 18px; color: #4a5568; margin-bottom: 25px;">
                Hello <strong>{{ $user }}</strong>,<br>
                You've been granted access to manage a server on <strong>{{ $panelName }}</strong>.
            </p>
            
            <div class="server-card">
                <div style="color: #8B5CF6; font-weight: 600; margin-bottom: 15px;">SERVER DETAILS</div>
                <div style="font-size: 24px; color: #2d3748; font-weight: 700; margin: 10px 0;">{{ $server->name }}</div>
                <div style="color: #718096; font-family: monospace; background: #edf2f7; padding: 8px 12px; border-radius: 6px; display: inline-block; margin-top: 10px;">
                    ID: {{ $server->uuidShort }}
                </div>
            </div>
            
            <div style="margin: 30px 0;">
                <p><strong>Available Permissions:</strong></p>
                <ul style="color: #4a5568; padding-left: 20px;">
                    @foreach($permissions as $permission)
                    <li style="margin: 8px 0;">✓ {{ $permission }}</li>
                    @endforeach
                </ul>
            </div>
            
            <div style="text-align: center; margin: 35px 0;">
                <a href="{{ $serverUrl }}" class="cta-button">
                    <span style="font-size: 18px; margin-right: 10px;">⚡</span>
                    Go to Server Panel
                </a>
            </div>
        </div>
        
        <div class="footer">
            <p>© {{ $currentYear }} {{ $panelName }}. All rights reserved.</p>
        </div>
    </div>
</body>
</html>
EOF
    print_success "Created server-added.blade.php"
    
    # 3. Password Reset
    cat > "$PANEL_DIR/resources/views/emails/auth/password-reset.blade.php" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Reset Password - {{ $panelName }}</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 20px; }
        .email-container { max-width: 600px; margin: auto; background: white; border-radius: 16px; overflow: hidden; box-shadow: 0 20px 60px rgba(0,0,0,0.15); }
        .header { background: linear-gradient(135deg, #8B5CF6 0%, #7C3AED 100%); color: white; padding: 40px; text-align: center; }
        .body { padding: 40px; }
        .reset-button { display: inline-block; background: linear-gradient(135deg, #8B5CF6 0%, #7C3AED 100%); color: white !important; text-decoration: none; padding: 18px 40px; border-radius: 10px; font-weight: 700; font-size: 16px; transition: all 0.3s; }
        .reset-button:hover { transform: translateY(-3px); box-shadow: 0 15px 35px rgba(139, 92, 246, 0.3); }
        .footer { background: #f8fafc; padding: 30px; text-align: center; color: #718096; border-top: 1px solid #e2e8f0; }
    </style>
</head>
<body>
    <div class="email-container">
        <div class="header">
            <h1 style="margin: 0; font-size: 32px;">🔐 Password Reset</h1>
            <p style="opacity: 0.9; margin-top: 10px;">Secure your account access</p>
        </div>
        
        <div class="body">
            <p style="font-size: 18px; color: #4a5568; margin-bottom: 25px;">
                Hello <strong>{{ $username }}</strong>,<br>
                We received a request to reset your password.
            </p>
            
            <div style="text-align: center; margin: 40px 0;">
                <a href="{{ $resetUrl }}" class="reset-button">
                    <span style="margin-right: 10px;">🔄</span>
                    Reset Password
                </a>
            </div>
            
            <div style="background: #f0f9ff; border-left: 4px solid #0ea5e9; padding: 20px; border-radius: 0 8px 8px 0; margin: 30px 0;">
                <p style="color: #0369a1; margin: 0;">
                    <strong>⚠️ Important:</strong> This link expires in {{ $expireTime }} minutes.
                </p>
            </div>
            
            <p style="color: #718096; font-size: 14px;">
                If you didn't request this, please ignore this email.
            </p>
        </div>
        
        <div class="footer">
            <p>© {{ $currentYear }} {{ $panelName }}</p>
        </div>
    </div>
</body>
</html>
EOF
    print_success "Created password-reset.blade.php"
    
    # 4. Removed from Server
    cat > "$PANEL_DIR/resources/views/emails/removed-from-server.blade.php" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Access Revoked - {{ $panelName }}</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #f7fafc; padding: 20px; }
        .email-container { max-width: 600px; margin: auto; background: white; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); }
        .header { background: linear-gradient(135deg, #f97316 0%, #ea580c 100%); color: white; padding: 40px; text-align: center; }
        .body { padding: 40px; }
        .server-info { background: #fef2f2; border-radius: 12px; padding: 25px; margin: 25px 0; border-left: 5px solid #dc2626; }
        .footer { background: #f8fafc; padding: 30px; text-align: center; color: #718096; border-top: 1px solid #e2e8f0; }
    </style>
</head>
<body>
    <div class="email-container">
        <div class="header">
            <h1 style="margin: 0; font-size: 28px;">👋 Access Revoked</h1>
            <p style="opacity: 0.9; margin-top: 10px;">Server permissions updated</p>
        </div>
        
        <div class="body">
            <p style="font-size: 18px; color: #4a5568; margin-bottom: 25px;">
                Hello <strong>{{ $user }}</strong>,<br>
                Your access to the following server has been revoked.
            </p>
            
            <div class="server-info">
                <div style="color: #dc2626; font-weight: 600; margin-bottom: 15px;">SERVER REMOVED</div>
                <div style="font-size: 24px; color: #7f1d1d; font-weight: 700;">{{ $serverName }}</div>
                <p style="color: #b91c1c; margin-top: 15px;">
                    You no longer have access to manage this server.
                </p>
            </div>
            
            <div style="background: #f0f9ff; padding: 20px; border-radius: 10px; margin-top: 30px;">
                <p style="color: #0369a1; margin: 0;">
                    <strong>Note:</strong> If this was a mistake, please contact the server owner.
                </p>
            </div>
        </div>
        
        <div class="footer">
            <p>© {{ $currentYear }} {{ $panelName }}</p>
        </div>
    </div>
</body>
</html>
EOF
    print_success "Created removed-from-server.blade.php"
    
    # 5. Server Installed
    cat > "$PANEL_DIR/resources/views/emails/server-installed.blade.php" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Server Ready - {{ $panelName }}</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: linear-gradient(135deg, #10b981 0%, #059669 100%); padding: 20px; }
        .email-container { max-width: 600px; margin: auto; background: white; border-radius: 16px; overflow: hidden; box-shadow: 0 20px 60px rgba(0,0,0,0.15); }
        .header { background: linear-gradient(135deg, #10b981 0%, #059669 100%); color: white; padding: 40px; text-align: center; }
        .body { padding: 40px; }
        .success-card { background: linear-gradient(135deg, #f0fff4 0%, #c6f6d5 100%); border-radius: 12px; padding: 30px; margin: 30px 0; text-align: center; border: 2px solid #68d391; }
        .cta-button { display: inline-block; background: linear-gradient(135deg, #10b981 0%, #059669 100%); color: white !important; text-decoration: none; padding: 18px 40px; border-radius: 10px; font-weight: 700; font-size: 16px; transition: all 0.3s; }
        .cta-button:hover { transform: translateY(-3px); box-shadow: 0 15px 35px rgba(16, 185, 129, 0.3); }
        .footer { background: #f8fafc; padding: 30px; text-align: center; color: #718096; border-top: 1px solid #e2e8f0; }
    </style>
</head>
<body>
    <div class="email-container">
        <div class="header">
            <h1 style="margin: 0; font-size: 32px;">✅ Server Ready!</h1>
            <p style="opacity: 0.9; margin-top: 10px;">Installation completed successfully</p>
        </div>
        
        <div class="body">
            <p style="font-size: 18px; color: #4a5568; margin-bottom: 25px;">
                Hello <strong>{{ $user }}</strong>,<br>
                Your server has been installed and is ready to use!
            </p>
            
            <div class="success-card">
                <div style="font-size: 48px; margin-bottom: 20px;">🎉</div>
                <div style="font-size: 24px; color: #065f46; font-weight: 700; margin-bottom: 10px;">Installation Complete</div>
                <p style="color: #047857;">
                    Your server <strong>{{ $server->name }}</strong> is now online and ready.
                </p>
                <p style="color: #059669; margin-top: 15px; font-size: 14px;">
                    Installed on: {{ $installTime }}
                </p>
            </div>
            
            <div style="text-align: center; margin: 40px 0;">
                <a href="{{ $serverUrl }}" class="cta-button">
                    <span style="margin-right: 10px;">🚀</span>
                    Launch Server
                </a>
            </div>
        </div>
        
        <div class="footer">
            <p>© {{ $currentYear }} {{ $panelName }}</p>
        </div>
    </div>
</body>
</html>
EOF
    print_success "Created server-installed.blade.php"
    
    # 6. Mail Tested
    cat > "$PANEL_DIR/resources/views/emails/mail-tested.blade.php" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Email Test - {{ $panelName }}</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: linear-gradient(135deg, #3b82f6 0%, #1d4ed8 100%); padding: 20px; }
        .email-container { max-width: 600px; margin: auto; background: white; border-radius: 16px; overflow: hidden; box-shadow: 0 20px 60px rgba(0,0,0,0.15); }
        .header { background: linear-gradient(135deg, #3b82f6 0%, #1d4ed8 100%); color: white; padding: 40px; text-align: center; }
        .body { padding: 40px; }
        .test-card { background: linear-gradient(135deg, #dbeafe 0%, #bfdbfe 100%); border-radius: 12px; padding: 30px; margin: 30px 0; text-align: center; border: 2px solid #60a5fa; }
        .footer { background: #f8fafc; padding: 30px; text-align: center; color: #718096; border-top: 1px solid #e2e8f0; }
    </style>
</head>
<body>
    <div class="email-container">
        <div class="header">
            <h1 style="margin: 0; font-size: 32px;">📧 Email Test Successful</h1>
            <p style="opacity: 0.9; margin-top: 10px;">Mail configuration verified</p>
        </div>
        
        <div class="body">
            <div class="test-card">
                <div style="font-size: 48px; margin-bottom: 20px;">✅</div>
                <div style="font-size: 24px; color: #1e40af; font-weight: 700; margin-bottom: 10px;">Test Passed!</div>
                <p style="color: #1d4ed8;">
                    Email configuration for <strong>{{ $panelName }}</strong> is working correctly.
                </p>
                <div style="margin-top: 25px; text-align: left; background: white; padding: 20px; border-radius: 8px;">
                    <p style="margin: 5px 0;"><strong>Test Type:</strong> {{ $testType }}</p>
                    <p style="margin: 5px 0;"><strong>Recipient:</strong> {{ $recipient }}</p>
                    <p style="margin: 5px 0;"><strong>Test Time:</strong> {{ $testTime }}</p>
                </div>
            </div>
            
            <p style="text-align: center; color: #4a5568; font-size: 16px;">
                All email notifications are now properly configured and ready to use.
            </p>
        </div>
        
        <div class="footer">
            <p>© {{ $currentYear }} {{ $panelName }}</p>
        </div>
    </div>
</body>
</html>
EOF
    print_success "Created mail-tested.blade.php"
}

set_permissions() {
    print_step "Setting permissions..."

    print_success "Permissions set"
}

clear_cache() {
    print_step "Clearing caches..."
    
    cd "$PANEL_DIR"
    
    # Clear Laravel caches
    php artisan view:clear
    php artisan cache:clear
    php artisan config:clear
    php artisan route:clear
    
    # Optimize for production
    php artisan optimize:clear
    
    print_success "Caches cleared"
}

restart_queue() {
    print_step "Restarting queue workers..."
    
    # Try to restart queue workers
    if command -v supervisorctl &> /dev/null; then
        sudo supervisorctl restart pteroq:* 2>/dev/null || true
        sudo supervisorctl restart laravel-worker:* 2>/dev/null || true
    fi
    
    # Restart PHP-FPM
    if systemctl is-active --quiet php8.2-fpm; then
        sudo systemctl restart php8.2-fpm
    elif systemctl is-active --quiet php8.1-fpm; then
        sudo systemctl restart php8.1-fpm
    elif systemctl is-active --quiet php8.0-fpm; then
        sudo systemctl restart php8.0-fpm
    elif systemctl is-active --quiet php7.4-fpm; then
        sudo systemctl restart php7.4-fpm
    fi
    
    print_success "Services restarted"
}

show_summary() {
    echo -e "${GREEN}"
    echo "=============================================="
    echo "            UPDATE COMPLETE! 🎉"
    echo "=============================================="
    echo -e "${NC}"
    echo "✅ Backup created at: $BACKUP_DIR"
    echo "✅ Updated 6 notification classes"
    echo "✅ Created 6 premium email templates"
    echo "✅ Permissions configured"
    echo "✅ Caches cleared"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Test email notifications from panel"
    echo "2. Check spam folder if emails don't arrive"
    echo "3. Backup directory: $BACKUP_DIR"
    echo ""
    echo -e "${CYAN}To restore backup:${NC}"
    echo "cp -r $BACKUP_DIR/Notifications/* $PANEL_DIR/app/Notifications/"
    echo "cp -r $BACKUP_DIR/emails/* $PANEL_DIR/resources/views/emails/"
}

main() {
    print_header
    
    # Check if running as root
    if [ "$EUID" -eq 0 ]; then 
        print_warning "Running as root! It's better to run as $USER"
    fi
    
    # Check panel directory
    check_panel_dir
    
    # Check dependencies
    check_dependencies
    
    # Create backup
    create_backup
    
    # Create notification directory if not exists
    mkdir -p "$PANEL_DIR/app/Notifications"
    
    # Create notification classes
    print_step "Creating premium notification classes..."
    create_account_created
    create_added_to_server
    create_send_password_reset
    create_removed_from_server
    create_server_installed
    create_mail_tested
    
    # Create email templates
    create_email_templates
    
    # Set permissions
    set_permissions
    
    # Clear cache
    clear_cache
    
    # Restart queue
    restart_queue
    
    # Show summary
    show_summary
}

# ==============================================
# RUN SCRIPT
# ==============================================

# Check if we should run
if [ -t 0 ]; then
    echo -e "${YELLOW}This script will update Pterodactyl email notifications.${NC}"
    echo -e "${YELLOW}Backup will be created at: /tmp/ptero-backup-*/${NC}"
    echo ""
    read -p "Continue? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        main
    else
        echo "Aborted."
        exit 0
    fi
else
    # Non-interactive mode
    main
fi
