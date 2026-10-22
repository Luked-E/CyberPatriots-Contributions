# Keep selected index in view
        if ($selectedIndex -lt $viewStart) {
            $viewStart = $selectedIndex
        #} elseif ($selectedIndex -ge ($viewStart + $maxVisible - 1)) {
            #$viewStart = $selectedIndex - $maxVisible + 2
        } elseif ($selectedIndex -ge ($viewStart + $(if($selectedIndex -ge 3) {$maxVisible - 1} else {$maxVisible}) )) {
            $viewStart = $selectedIndex - $(if($selectedIndex -ge 3) {$maxVisible - 1} else {$maxVisible}) + 1
        }

        if (($viewStart -gt 0) -and ($viewStart + $maxVisible - 1) -lt ($MenuItems.Length - 1)) {
            $viewEnd = [Math]::Min($MenuItems.Length - 1, $viewStart + $maxVisible - 1) -1
        } else { 
            $viewEnd = [Math]::Min($MenuItems.Length - 1, $viewStart + $maxVisible - 1)
        }

        Show-Header $Subtitle
        if ($ColumnHeader) {
            Write-Host "       $ColumnHeader" -ForegroundColor DarkYellow
            Write-Host "       $('-' * ($ColumnHeader.Length))" -ForegroundColor DarkGray
        }

        # Pagination upward indicator
        if ($viewStart -gt 0) {
            Write-Host "  ...  [▲ $($viewStart) more items above]" -ForegroundColor DarkCyan
        }

        for ($i = $viewStart; $i -le $viewEnd; $i++) {
            if ($i -eq $selectedIndex) {
                Write-Host "  -->  " -ForegroundColor Yellow -NoNewline
                Write-Host "$($MenuItems[$i])" -ForegroundColor Black -BackgroundColor Yellow
            } else {
                Write-Host "       $($MenuItems[$i])" -ForegroundColor Gray
            }
        }

        # Pagination downward indicator
        if ([Math]::Min($MenuItems.Length - 1, $viewStart + $maxVisible - 1) -lt ($MenuItems.Length - 1)) {
            $remaining = ($MenuItems.Length - 1) - $viewEnd
            Write-Host "  ...  [▼ $remaining more items below]" -ForegroundColor DarkCyan
        }

        Write-Host ""
        Write-Host "$HelpText" -ForegroundColor DarkCyan
