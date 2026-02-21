# fritz-workstation: For Use on All NVIDIA Hardware Up to RTX 4090

A GPU-accelerated Linux desktop container providing a full XFCE4 
desktop environment accessible via browser (NoVNC), designed for 
AI/ML workloads on cloud GPU instances (RunPod, Vast.ai, 
Paperspace, etc.).

GPU acceleration is provided via the NVIDIA Container Toolkit 
pre-installed on the host by the cloud provider. No host configuration 
is required on your part — just deploy and connect.


Don't forget your launch files!

Since you are rebuilding this image, you will need the supervisord.conf and entrypoint.sh files in the same directory as your Dockerfile for the image to boot successfully. Here is the exact code for those so you can copy/paste them:

1. supervisord.conf
This controls all your background services and ensures they restart if they crash.

[supervisord]
nodaemon=true
user=root

[program:sshd]
command=/usr/sbin/sshd -D
autostart=true
autorestart=true

[program:vnc]
command=su - fritz -c "vncserver :0 -geometry %(ENV_RESOLUTION)s -depth 24 -localhost no -SecurityTypes None"
autostart=true
autorestart=true

[program:novnc]
command=su - fritz -c "websockify --web=/usr/share/novnc/ 6080 localhost:5900"
autostart=true
autorestart=true

[program:pulseaudio]
command=su - fritz -c "pulseaudio --start --exit-idle-time=-1"
autostart=true
autorestart=true

[program:audio-share]
command=su - fritz -c "audio-share-server"
autostart=true
autorestart=true

2. entrypoint.sh
This initializes the environment, sets up SSH keys, and hands off control to Supervisor.

#!/bin/bash
set -e

# Setup SSH directory for root
mkdir -p /var/run/sshd

# Ensure fritz owns their home directory
chown -R fritz:fritz /home/fritz

# Start Supervisor to manage all background services
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf

Make sure to run chmod +x entrypoint.sh on your local machine before building the Docker image so it is executable! 


---

## Connecting From Your Local Machine

You do not need to install any special software to use this container.
Everything runs through your web browser. The sections below explain
how to get the best experience on both Windows and Linux.

---

### The Quick Version (Works on Any OS)

1. Deploy your pod and wait for it to show **Running**
2. In your pod's **Connect** menu, find the URL for port **6080**
3. Click it — your desktop appears instantly in the browser
4. That's it. Nothing to install.

> **Recommended browsers:** Chrome or Edge give the best performance.
> Firefox works but may feel slightly slower for screen updates.

---

### Connecting on Windows

#### Desktop (Browser — Recommended)

No installation required. Just open Chrome or Edge and go to the
NoVNC URL shown in your pod's Connect menu for port **6080**.

```
Example: https://abc123.proxy.runpod.net/6080
```

You will see the full Linux desktop in your browser tab. You can
resize the window and the desktop will adjust automatically.

**Tips for Windows users:**
- Use **F8** inside the NoVNC window to open the settings menu
  (fullscreen toggle, clipboard, etc.)
- To go **fullscreen**, press **F8 → Fullscreen**
- To send **Ctrl+Alt+Del** (which Windows would intercept), use the
  NoVNC menu instead of your keyboard

#### Copy & Paste Between Your PC and the Remote Desktop

NoVNC uses an intermediate clipboard because browsers restrict
direct clipboard access for security reasons. [web:167][web:169]

- **To paste text INTO the remote desktop:**
  Press **F8** to open the NoVNC menu → click **Clipboard** →
  paste your text into the box → it will appear in the remote
  desktop's clipboard, ready to paste with **Ctrl+V**

- **To copy text FROM the remote desktop:**
  Copy text normally inside the desktop (Ctrl+C), then press **F8**
  → **Clipboard** to see it, and copy it back to your local PC

> **Chrome users:** Chrome may ask for clipboard permission the
> first time. Click **Allow** when prompted.

#### Sound on Windows

Sound streams directly through your browser via the audio bridge
running on port **8081**.

1. Find the URL for port **8081** in your pod's Connect menu
2. Open it in a **separate browser tab** (keep it open in background)
3. Click **Play** if prompted
4. Audio from the remote desktop will now play through your
   Windows speakers or headphones

> Make sure your browser tab for port 8081 is **not muted**.
> Check the speaker icon on the browser tab itself — Chrome
> sometimes auto-mutes new tabs.

#### SSH on Windows (Optional — for advanced use)

SSH lets you type commands directly into the container without
using the desktop. It's useful for running Python scripts,
managing files, or using Conda.

1. Download and install **PuTTY** (free):
   https://www.putty.org
2. Open PuTTY
3. In **Host Name**, enter the hostname shown in your pod's
   Connect menu
4. In **Port**, enter the external port mapped to **22**
   (shown in your Connect menu — it will NOT be 22 itself)
5. Click **Open**
6. Login as: `fritz`
7. Password: `qwerty` (change this after first login!)

Alternatively, if you have Windows 10/11 with the built-in
OpenSSH client, open **PowerShell** and type:
```powershell
ssh fritz@<hostname> -p <port-number>
```

---

### Connecting on Linux

#### Desktop (Browser — Recommended)

Same as Windows — open Chrome or Firefox and navigate to the
NoVNC URL for port **6080** from your pod's Connect menu.

#### Copy & Paste on Linux

Works the same way as Windows via the F8 NoVNC clipboard menu.
[web:167][web:169]

Linux bonus: if you use **middle-click paste** (the Linux
clipboard), this will work naturally inside the remote desktop
without needing the F8 menu.

#### Sound on Linux

Same as Windows — open the URL for port **8081** in a separate
browser tab and press Play. Audio will stream through your
local speakers.

If you prefer a native audio stream instead of browser-based,
you can pipe it through PulseAudio directly. Open a terminal
on your local Linux machine and run:

```bash
# Stream audio natively (optional, advanced users only)
pacat --server=tcp:<your-pod-hostname>:<port-8081> \
  --playback --rate=44100 --channels=2 --format=s16le
```

#### SSH on Linux

Open any terminal and run:
```bash
ssh fritz@<hostname> -p <port-number>
# Password: qwerty
```

Where `<hostname>` and `<port-number>` come from your pod's
Connect menu (the port mapped to internal port 22).

To avoid typing the password every time, copy your SSH key:
```bash
ssh-copy-id -p <port-number> fritz@<hostname>
```

---

### Port Reference (Quick Cheat Sheet)

| What you want to do              | Port  | How to access                  |
|----------------------------------|-------|--------------------------------|
| See the desktop                  | 6080  | Browser (NoVNC)                |
| Hear audio                       | 8081  | Browser tab (keep open)        |
| Run terminal commands            | 22    | SSH (PuTTY on Windows/terminal)|
| Use ComfyUI (AI image tool)      | 8188  | Browser                        |
| Use Gradio / Stable Diffusion UI | 7860  | Browser                        |
| Use Jupyter Notebook             | 8888  | Browser                        |
| Direct VNC (advanced)            | 5900  | VNC client app                 |

All URLs and port numbers are found in your pod's
**Connect** menu after it starts. You do not need to remember
any IP addresses — the platform generates the URLs for you.

---

### Troubleshooting Common Issues

**The desktop looks blurry or pixelated**
Open the NoVNC menu (F8) → set **Scaling Mode** to
**Remote Resizing**. This tells the remote desktop to match
your browser window size exactly.

**I can hear no sound**
Make sure the browser tab for port 8081 is open and not muted.
Check the small speaker icon on that tab in your browser.

**Copy/paste is not working**
Use the F8 clipboard method described above. Direct
clipboard access between your PC and the remote desktop
requires going through the NoVNC clipboard panel. [web:167]

**The browser asks me to allow clipboard access**
Click **Allow**. This is Chrome asking for permission to
sync the clipboard — it is safe to allow for this use case.

**SSH says "connection refused"**
Make sure you are using the *external* port shown in your
Connect menu, not port 22 directly. Cloud platforms remap
SSH to a high-numbered port for security.

