param (
    [string]$sourceFolderPath,
    [string]$replicaFolderPath,
    [string]$logFilePath
)

# Function to log messages to the console and a log file
function Log-Message {
    param (
        [string]$message,
        [string]$logFilePath,
        [string]$operationType
    )
    $formattedMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - [$operationType] $message"
    Write-Output $formattedMessage
    Add-Content -Path $logFilePath -Value $formattedMessage
}

# Check if source folder exists
if (-not (Test-Path $sourceFolderPath -PathType Container)) {
    Log-Message "Source folder does not exist." $logFilePath "Error"
    exit
}

# Check if replica folder exists, create if not
if (-not (Test-Path $replicaFolderPath -PathType Container)) {
    New-Item -Path $replicaFolderPath -ItemType Directory | Out-Null
    Log-Message "Replica folder created." $logFilePath "Info"
}

# Synchronize folders 
try {
    $sourceFiles = Get-ChildItem -Path $sourceFolderPath -Recurse
    foreach ($file in $sourceFiles) {
        $relativePath = $file.FullName.Replace($sourceFolderPath, "")
        $replicaFilePath = Join-Path -Path $replicaFolderPath -ChildPath $relativePath

        if (-not (Test-Path $replicaFilePath) -or $file.LastWriteTime -gt (Get-Item $replicaFilePath).LastWriteTime) {
            Copy-Item -Path $file.FullName -Destination $replicaFilePath -Force
            Log-Message "Copied file: $relativePath" $logFilePath "Copied"
        }
        else {
            Log-Message "Updated file: $relativePath" $logFilePath "Updated"
        }
    }

	# Remove files from replica folder that don't exist in the source folder
    $replicaFiles = Get-ChildItem -Path $replicaFolderPath -Recurse
    foreach ($file in $replicaFiles) {
        $relativePath = $file.FullName.Replace($replicaFolderPath, "")
        $sourceFilePath = Join-Path -Path $sourceFolderPath -ChildPath $relativePath

        if (-not (Test-Path $sourceFilePath) -or $file.LastWriteTime -gt (Get-Item $sourceFilePath).LastWriteTime) {
            Remove-Item -Path $file.FullName -Force
            Log-Message "Removed file: $relativePath" $logFilePath "Removed"
        }
    }

    Log-Message "Synchronization completed successfully." $logFilePath "Info"
}
catch {
    Log-Message "Error occurred: $_" $logFilePath "Error"
}
