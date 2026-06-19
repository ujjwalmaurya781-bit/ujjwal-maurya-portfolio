# Simple PowerShell HTTP Server for local development
$port = 8000
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")

try {
    $listener.Start()
    Write-Host "`n===============================================" -ForegroundColor Cyan
    Write-Host " UJJWAL MAURYA PORTFOLIO DEV SERVER" -ForegroundColor Green -Bold
    Write-Host " Running on: http://localhost:$port/" -ForegroundColor Yellow
    Write-Host " Press Ctrl+C in this terminal to stop." -ForegroundColor White
    Write-Host "===============================================`n" -ForegroundColor Cyan

    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        
        try {
            # Parse URL Path
            $urlPath = [System.Uri]::UnescapeDataString($request.RawUrl.Split('?')[0])

            # API: List Images in a folder
            if ($urlPath -eq "/api/list-images") {
                $folder = $request.QueryString["folder"]
                if ($null -eq $folder) {
                    $response.StatusCode = 400
                    $errBytes = [System.Text.Encoding]::UTF8.GetBytes("Missing folder parameter")
                    $response.Headers.Add("Access-Control-Allow-Origin", "*")
                    $response.ContentType = "text/plain"
                    $response.ContentLength64 = $errBytes.Length
                    if ($request.HttpMethod -ne "HEAD") {
                        $response.OutputStream.Write($errBytes, 0, $errBytes.Length)
                    }
                    $response.OutputStream.Close()
                    continue
                }
                
                $cleanedFolder = $folder.Replace("/", "\").TrimStart('\')
                $fullFolder = Join-Path $PSScriptRoot $cleanedFolder
                
                # Security check to prevent directory traversal outside workspace
                if (-not $fullFolder.ToLower().StartsWith($PSScriptRoot.ToLower())) {
                    $response.StatusCode = 403
                    $errBytes = [System.Text.Encoding]::UTF8.GetBytes("Forbidden directory access")
                    $response.Headers.Add("Access-Control-Allow-Origin", "*")
                    $response.ContentType = "text/plain"
                    $response.ContentLength64 = $errBytes.Length
                    if ($request.HttpMethod -ne "HEAD") {
                        $response.OutputStream.Write($errBytes, 0, $errBytes.Length)
                    }
                    $response.OutputStream.Close()
                    continue
                }
                
                if (Test-Path $fullFolder -PathType Container) {
                    $files = Get-ChildItem -Path $fullFolder -File | Where-Object {
                        $_.Extension -match "\.(png|jpg|jpeg|gif|svg|webp)$"
                    } | ForEach-Object {
                        $relPath = $_.FullName.Substring($PSScriptRoot.Length).Replace("\", "/").TrimStart('/')
                        $relPath
                    }
                    
                    $json = ConvertTo-Json @($files)
                    $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
                    
                    $response.Headers.Add("Access-Control-Allow-Origin", "*")
                    $response.Headers.Add("Cache-Control", "no-cache, no-store, must-revalidate")
                    $response.ContentType = "application/json; charset=utf-8"
                    $response.ContentLength64 = $bytes.Length
                    if ($request.HttpMethod -ne "HEAD") {
                        $response.OutputStream.Write($bytes, 0, $bytes.Length)
                    }
                }
                else {
                    $response.StatusCode = 404
                    $errBytes = [System.Text.Encoding]::UTF8.GetBytes("Folder not found")
                    $response.Headers.Add("Access-Control-Allow-Origin", "*")
                    $response.ContentType = "text/plain"
                    $response.ContentLength64 = $errBytes.Length
                    if ($request.HttpMethod -ne "HEAD") {
                        $response.OutputStream.Write($errBytes, 0, $errBytes.Length)
                    }
                }
                $response.OutputStream.Close()
                continue
            }
            
            # API: List subdirectories in a folder
            if ($urlPath -eq "/api/list-subdirs") {
                $folder = $request.QueryString["folder"]
                if ($null -eq $folder) {
                    $response.StatusCode = 400
                    $errBytes = [System.Text.Encoding]::UTF8.GetBytes("Missing folder parameter")
                    $response.Headers.Add("Access-Control-Allow-Origin", "*")
                    $response.ContentType = "text/plain"
                    $response.ContentLength64 = $errBytes.Length
                    if ($request.HttpMethod -ne "HEAD") {
                        $response.OutputStream.Write($errBytes, 0, $errBytes.Length)
                    }
                    $response.OutputStream.Close()
                    continue
                }
                
                $cleanedFolder = $folder.Replace("/", "\").TrimStart('\')
                $fullFolder = Join-Path $PSScriptRoot $cleanedFolder
                
                # Security check to prevent directory traversal outside workspace
                if (-not $fullFolder.ToLower().StartsWith($PSScriptRoot.ToLower())) {
                    $response.StatusCode = 403
                    $errBytes = [System.Text.Encoding]::UTF8.GetBytes("Forbidden directory access")
                    $response.Headers.Add("Access-Control-Allow-Origin", "*")
                    $response.ContentType = "text/plain"
                    $response.ContentLength64 = $errBytes.Length
                    if ($request.HttpMethod -ne "HEAD") {
                        $response.OutputStream.Write($errBytes, 0, $errBytes.Length)
                    }
                    $response.OutputStream.Close()
                    continue
                }
                
                if (Test-Path $fullFolder -PathType Container) {
                    $subdirs = Get-ChildItem -Path $fullFolder -Directory | ForEach-Object { $_.Name }
                    $json = ConvertTo-Json @($subdirs)
                    $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
                    
                    $response.Headers.Add("Access-Control-Allow-Origin", "*")
                    $response.Headers.Add("Cache-Control", "no-cache, no-store, must-revalidate")
                    $response.ContentType = "application/json; charset=utf-8"
                    $response.ContentLength64 = $bytes.Length
                    if ($request.HttpMethod -ne "HEAD") {
                        $response.OutputStream.Write($bytes, 0, $bytes.Length)
                    }
                }
                else {
                    $response.StatusCode = 404
                    $errBytes = [System.Text.Encoding]::UTF8.GetBytes("Folder not found")
                    $response.Headers.Add("Access-Control-Allow-Origin", "*")
                    $response.ContentType = "text/plain"
                    $response.ContentLength64 = $errBytes.Length
                    if ($request.HttpMethod -ne "HEAD") {
                        $response.OutputStream.Write($errBytes, 0, $errBytes.Length)
                    }
                }
                $response.OutputStream.Close()
                continue
            }
            
            # API: Upload image to a folder
            if ($urlPath -eq "/api/upload" -and $request.HttpMethod -eq "POST") {
                $folder = $request.QueryString["folder"]
                $filename = $request.QueryString["filename"]
                
                if ($null -eq $folder -or $null -eq $filename) {
                    $response.StatusCode = 400
                    $errBytes = [System.Text.Encoding]::UTF8.GetBytes("Missing folder or filename parameters")
                    $response.Headers.Add("Access-Control-Allow-Origin", "*")
                    $response.ContentType = "text/plain"
                    $response.ContentLength64 = $errBytes.Length
                    if ($request.HttpMethod -ne "HEAD") {
                        $response.OutputStream.Write($errBytes, 0, $errBytes.Length)
                    }
                    $response.OutputStream.Close()
                    continue
                }
                
                $cleanedFolder = $folder.Replace("/", "\").TrimStart('\')
                $fullFolder = Join-Path $PSScriptRoot $cleanedFolder
                
                # Security check to prevent directory traversal outside workspace
                if (-not $fullFolder.ToLower().StartsWith($PSScriptRoot.ToLower())) {
                    $response.StatusCode = 403
                    $errBytes = [System.Text.Encoding]::UTF8.GetBytes("Forbidden directory access")
                    $response.Headers.Add("Access-Control-Allow-Origin", "*")
                    $response.ContentType = "text/plain"
                    $response.ContentLength64 = $errBytes.Length
                    if ($request.HttpMethod -ne "HEAD") {
                        $response.OutputStream.Write($errBytes, 0, $errBytes.Length)
                    }
                    $response.OutputStream.Close()
                    continue
                }
                
                if (Test-Path $fullFolder -PathType Container) {
                    $destPath = Join-Path $fullFolder $filename
                    
                    $inputStream = $request.InputStream
                    $buffer = New-Object Byte[] $request.ContentLength64
                    $read = 0
                    $offset = 0
                    while (($read = $inputStream.Read($buffer, $offset, $buffer.Length - $offset)) -gt 0) {
                        $offset += $read
                    }
                    
                    [System.IO.File]::WriteAllBytes($destPath, $buffer)
                    
                    $response.Headers.Add("Access-Control-Allow-Origin", "*")
                    $response.StatusCode = 200
                    $successBytes = [System.Text.Encoding]::UTF8.GetBytes("Uploaded successfully")
                    $response.ContentType = "text/plain"
                    $response.ContentLength64 = $successBytes.Length
                    if ($request.HttpMethod -ne "HEAD") {
                        $response.OutputStream.Write($successBytes, 0, $successBytes.Length)
                    }
                }
                else {
                    $response.StatusCode = 404
                    $errBytes = [System.Text.Encoding]::UTF8.GetBytes("Folder not found")
                    $response.Headers.Add("Access-Control-Allow-Origin", "*")
                    $response.ContentType = "text/plain"
                    $response.ContentLength64 = $errBytes.Length
                    if ($request.HttpMethod -ne "HEAD") {
                        $response.OutputStream.Write($errBytes, 0, $errBytes.Length)
                    }
                }
                $response.OutputStream.Close()
                continue
            }

            if ($urlPath -eq "/") {
                $urlPath = "/index.html"
            }
            
            # Build local file path
            # Normalize slashes and clean path traversal attempts
            $cleanedPath = $urlPath.Replace("/", "\").TrimStart('\')
            $localPath = Join-Path $PSScriptRoot $cleanedPath
            
            # Fallback to public/ directory for static assets
            if (!(Test-Path $localPath -PathType Leaf)) {
                $publicPath = Join-Path $PSScriptRoot "public\$cleanedPath"
                if (Test-Path $publicPath -PathType Leaf) {
                    $localPath = $publicPath
                }
            }
            
            if (Test-Path $localPath -PathType Leaf) {
                $bytes = [System.IO.File]::ReadAllBytes($localPath)
                
                # Determine correct MIME Type
                $ext = [System.IO.Path]::GetExtension($localPath).ToLower()
                $contentType = "text/plain"
                
                switch ($ext) {
                    ".html" { $contentType = "text/html; charset=utf-8" }
                    ".css" { $contentType = "text/css; charset=utf-8" }
                    ".js" { $contentType = "application/javascript; charset=utf-8" }
                    ".json" { $contentType = "application/json; charset=utf-8" }
                    ".png" { $contentType = "image/png" }
                    ".jpg" { $contentType = "image/jpeg" }
                    ".jpeg" { $contentType = "image/jpeg" }
                    ".gif" { $contentType = "image/gif" }
                    ".svg" { $contentType = "image/svg+xml" }
                    ".webp" { $contentType = "image/webp" }
                    ".ico" { $contentType = "image/x-icon" }
                    ".pdf" { $contentType = "application/pdf" }
                }
                
                # CORS and Caching Headers
                $response.Headers.Add("Access-Control-Allow-Origin", "*")
                $response.Headers.Add("Cache-Control", "no-cache, no-store, must-revalidate")
                $response.ContentType = $contentType
                $response.ContentLength64 = $bytes.Length
                
                # Write to stream
                if ($request.HttpMethod -ne "HEAD") {
                    $response.OutputStream.Write($bytes, 0, $bytes.Length)
                }
            }
            else {
                # File Not Found
                Write-Host "404 Not Found: $urlPath" -ForegroundColor Red
                $response.StatusCode = 404
                $errBytes = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found: $urlPath")
                $response.ContentType = "text/plain"
                $response.ContentLength64 = $errBytes.Length
                if ($request.HttpMethod -ne "HEAD") {
                    $response.OutputStream.Write($errBytes, 0, $errBytes.Length)
                }
            }
            
            $response.OutputStream.Close()
        }
        catch {
            Write-Host "Error handling request: $_" -ForegroundColor Red
            try {
                if ($null -ne $response) {
                    $response.Close()
                }
            } catch {}
        }
    }
}
catch {
    Write-Host "Server error: $_" -ForegroundColor Red
}
finally {
    if ($listener -ne $null) {
        $listener.Close()
    }
}
