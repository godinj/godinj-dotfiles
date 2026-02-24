<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.godinj.file-receive-listener</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>${HOME}/.local/bin/file-receive-listener.sh</string>
  </array>
  <key>EnvironmentVariables</key>
  <dict>
    <key>MACHINE_RECEIVE_DIR</key>
    <string>${MACHINE_RECEIVE_DIR}</string>
  </dict>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>StandardOutPath</key>
  <string>/tmp/file-receive-listener.out</string>
  <key>StandardErrorPath</key>
  <string>/tmp/file-receive-listener.err</string>
</dict>
</plist>
