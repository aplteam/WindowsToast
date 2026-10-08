param([Parameter(Mandatory = $true)][string]$From)
# Fires a Windows toast notification for a Dyalog APL session that is waiting for input.
# Called by Notify.aplf. It passes a UTF-8 file holding one item per line:
#   1  title
#   2  body
#   3  icon: path to an .exe or .ico (may be empty)
#   4  wav : path to a .wav, or 'none' for silence (may be empty, see $wav below)
# The file is deleted as soon as it has been read.
$ErrorActionPreference = 'Stop'

$lines = @(Get-Content -LiteralPath $From -Encoding UTF8)
Remove-Item -LiteralPath $From -Force -ErrorAction SilentlyContinue

$title = 'Dyalog APL'
if ($lines.Count -ge 1 -and $lines[0]) { $title = $lines[0] }
$body = 'Waiting for your input'
if ($lines.Count -ge 2 -and $lines[1]) { $body = $lines[1] }
$icon = ''
if ($lines.Count -ge 3) { $icon = $lines[2] }
# The sound. Any .wav will do, 'none' stays silent.
$wav = 'C:\Windows\Media\Windows Notify Messaging.wav'
if ($lines.Count -ge 4 -and $lines[3]) { $wav = $lines[3] }

[void][Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
$tpl = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02)
$n = $tpl.GetElementsByTagName('text')
[void]$n.Item(0).AppendChild($tpl.CreateTextNode($title))
[void]$n.Item(1).AppendChild($tpl.CreateTextNode($body))

# The session is blocked until the question is answered, so the banner stays up until it is
# dismissed ('reminder'). For a banner that goes away by itself after ~25 seconds, drop the
# 'scenario' line and keep 'duration'.
$root = $tpl.GetElementsByTagName('toast').Item(0)
$root.SetAttribute('scenario', 'reminder')
$root.SetAttribute('duration', 'long')
$audio = $tpl.CreateElement('audio')
$audio.SetAttribute('silent', 'true')   # the sound is played at the bottom, see there
[void]$root.AppendChild($audio)

# Toasts need a registered AppUserModelId, or Windows drops them silently. Registering our own
# makes them appear as "Dyalog APL" in Settings > System > Notifications, where they can be
# switched off or muted independently of everything else.
$appId = 'Dyalog.APL.CommTools'
$key = "HKCU:\SOFTWARE\Classes\AppUserModelId\$appId"
if (-not (Test-Path $key)) { New-Item -Path $key -Force | Out-Null }
New-ItemProperty -Path $key -Name DisplayName -Value 'Dyalog APL' -PropertyType String -Force | Out-Null
if ($icon -and (Test-Path -LiteralPath $icon)) {
  # IconUri wants an image file. Windows will not take an icon resource out of an .exe: it
  # accepts the registry value without complaint and then shows no icon at all, so extract
  # the icon into a .png first. The interpreter's timestamp is part of the name, so an
  # upgraded Dyalog gets a fresh extraction rather than the icon of the version before it.
  if ([IO.Path]::GetExtension($icon) -eq '.exe') {
    $png = Join-Path $env:TEMP ('dyalog-toast-icon-' + (Get-Item -LiteralPath $icon).LastWriteTime.Ticks + '.png')
    if (-not (Test-Path -LiteralPath $png)) {
      Add-Type -AssemblyName System.Drawing
      [System.Drawing.Icon]::ExtractAssociatedIcon($icon).ToBitmap().Save($png, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    $icon = $png
  }
  New-ItemProperty -Path $key -Name IconUri -Value $icon -PropertyType String -Force | Out-Null
}
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId).Show([Windows.UI.Notifications.ToastNotification]::new($tpl))

# Notification sounds are switched off globally on this machine
# (NOC_GLOBAL_SETTING_ALLOW_NOTIFICATION_SOUND = 0), so the toast's own <audio> element never
# plays anything. Play the sound here instead.
try {
  if ($wav -ne 'none') {
    if (Test-Path -LiteralPath $wav) { (New-Object Media.SoundPlayer $wav).PlaySync() }
    else { [console]::Beep(880, 200) }
  }
} catch { }
