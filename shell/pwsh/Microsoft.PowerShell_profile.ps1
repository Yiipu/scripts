$saying = @{content = "𝒥𝒶𝓂 𝒶 𝑀𝒶𝓃 𝑜𝒻 𝐹𝑜𝓇𝓉𝓊𝓃𝑒, 𝒶𝓃𝒹 𝒥 𝓂𝓊𝓈𝓉 𝓈𝑒𝑒𝓀 𝓂𝓎 𝐹𝑜𝓇𝓉𝓊𝓃𝑒"; source = "𝐻𝑒𝓃𝓇𝓎 Æ𝓋𝑒𝓇𝒾𝑒𝓈, 𝟣𝟫𝟫𝟦" }
Write-Host "`n$($saying.content)`n`n`t`t`t`t-$($saying.source)`n"

function Set-LocationFromLnk {

	[CmdletBinding()]
    param (
        [string]$lnkPath
    )

    if (-not (Test-Path $lnkPath)) {
        Write-Error "The specified .lnk file does not exist."
        return
    }

    $shortcut = Get-Item $lnkPath
    $sh = New-Object -ComObject WScript.Shell
    $targetPath = $sh.CreateShortcut($shortcut).TargetPath

    if (-not (Test-Path $targetPath -PathType Container)) {
        Write-Error "The target path of the .lnk file does not exist."
        return
    }

    Set-Location $targetPath
    Write-Output "Changed directory to: $targetPath"
}
Set-Alias -Name cdlnk -Value Set-LocationFromLnk

function Compress-HighBitrateVideos {
    param (
        [string]$DirectoryPath
    )

    if (-Not (Test-Path $DirectoryPath)) {
        Write-Host "❌ 路径无效: $DirectoryPath"
        return
    }

    $threshold = 20000000 # 20,000 kbps in bits
    $videoExtensions = @("*.mp4", "*.mkv", "*.mov")
    $originalFilesToDelete = @()

    function Get-DurationSeconds($file) {
        $durationStr = ffprobe -v error -select_streams v:0 -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$file"
        return [double]::Parse($durationStr)
    }

    foreach ($ext in $videoExtensions) {
        Get-ChildItem -Path $DirectoryPath -Filter $ext | ForEach-Object {
            $file = $_.FullName
            $bitrate = ffprobe -v error -select_streams v:0 -show_entries stream=bit_rate -of default=noprint_wrappers=1:nokey=1 "$file"

            if ([int]$bitrate -gt $threshold) {
                $output = "$($file).compressed.mp4"
                $totalDuration = Get-DurationSeconds $file
                Write-Host "`n🎬 Compressing: $file"
                Write-Host "   Bitrate: $bitrate bps"

                $startInfo = New-Object System.Diagnostics.ProcessStartInfo
                $startInfo.FileName = "ffmpeg"
				$startInfo.Arguments = "-i `"$file`" -c:v h264_nvenc -preset fast -acodec aac -b:a 128k `"$output`" -progress pipe:1 -nostats -loglevel error"

                $startInfo.RedirectStandardOutput = $true
                $startInfo.UseShellExecute = $false
                $startInfo.CreateNoWindow = $true

                $proc = New-Object System.Diagnostics.Process
                $proc.StartInfo = $startInfo
                $proc.Start() | Out-Null

                while (!$proc.HasExited) {
                    $line = $proc.StandardOutput.ReadLine()
                    if ($line -match "^out_time_ms=(\d+)$") {
                        $elapsedMs = [double]$matches[1]
                        $elapsedSec = $elapsedMs / 1000000
                        $progress = [math]::Round(($elapsedSec / $totalDuration) * 100)
                        Write-Host ("Progress: {0}%" -f $progress).PadRight(20) -NoNewline
                        Write-Host "`r" -NoNewline
                    }
                }

                Write-Host "`n✅ Done: $output"
                $originalFilesToDelete += $file
            }
        }
    }

    if ($originalFilesToDelete.Count -gt 0) {
        $answer = Read-Host "`n是否删除原始文件？(y/n)"
        if ($answer -eq "y") {
            foreach ($f in $originalFilesToDelete) {
                Remove-Item "$f" -Force
                Write-Host "🗑️ Deleted: $f"
            }
        } else {
            Write-Host "❎ 保留原始文件。"
        }
    } else {
        Write-Host "`n✔ 没有发现需要压缩的视频。"
    }
}

Import-Module PoShFuck
