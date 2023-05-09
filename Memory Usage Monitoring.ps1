# Set the threshold for memory usage in percentage
$threshold = 60

# Set the path to the EmptyStandbyList.exe file
$emptyStandbyListPath = "$env:USERPROFILE\Desktop\EmptyStandbyList.exe"

# Set the path to the log file
$logFilePath = "$env:USERPROFILE\Desktop\log.txt"

# Set the email address and SMTP server settings
$fromAddress = "sender-email"
$toAddress = "receiver-email"
$mailRelayServer = "yourrelayserver"
$mailRelayPort = "yourrelayserverport"

# Define a function to check memory usage and run the command
function Check-MemoryUsage {

    # Get the current memory usage in percentage
    $memoryUsage = (Get-Counter "\Memory\% Committed Bytes In Use").CounterSamples.CookedValue

    $memoryUsageFormatted = "{0:N2} %" -f $memoryUsage
    Write-Host $memoryUsageFormatted

    # Show the current memory usage in the console every 3 minutes
    if ((Get-Date).Minute % 3 -eq 0 -and (Get-Date).Second -eq 0) {

        Write-Host "Current memory usage: $memoryUsageFormatted"

    }


    if ($memoryUsage -gt $threshold) {
    
        # If the memory usage is above the threshold, run the command prompt as an administrator and execute the command
        Write-Host "Memory usage is above the threshold. Running command prompt as an administrator and executing command: $emptyStandbyListPath workingsets"
        Start-Process cmd.exe -ArgumentList "/c $emptyStandbyListPath workingsets" -Verb runAs
        
        # Wait for the command to finish
        Write-Host "Waiting 1 minute for the command to finish..."
        Start-Sleep -Seconds 60
         
   
    }

    else {

        # Log the current memory usage, date, and time to the log file every 1 minutes if the memory usage is below the threshold
        if ((Get-Date).Minute % 1 -eq 0 -and (Get-Date).Second -eq 0) {

            $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $memoryUsage%"

            Add-Content -Path $logFilePath -Value $logMessage

            Write-Host "Memory usage is below the threshold. Logged the current memory usage, date, and time to $logFilePath $logMessage"

            # Send an email with the log file as an attachment
            $message = New-Object System.Net.Mail.MailMessage $fromAddress, $toAddress
            $message.Subject = "Memory usage log"
            $message.Body = "Please find attached the log file."
            $attachment = New-Object System.Net.Mail.Attachment($logFilePath)
            $message.Attachments.Add($attachment)
            $smtpClient = New-Object System.Net.Mail.SmtpClient($mailRelayServer, $mailRelayPort)
            $smtpClient.Send($message)

            Write-Host "Email send successfully."
            $attachment.Dispose()
            $message.Dispose()
        }

    }

}


# Define a function to handle errors and restart the script
function Handle-Error {

    # Display the error message
    Write-Host "Error: $($Error[0].Exception.Message)"

    # Wait for 10 seconds before restarting the script
    Write-Host "Restarting the script in 10 seconds..."

    Start-Sleep -Seconds 10


    # Restart the script
    & $MyInvocation.MyCommand.Path

}


# Set the error action to continue and register the error handler
$ErrorActionPreference = "Continue"

$ErrorAction = { Handle-Error }


# Call the function to start monitoring the memory usage and running the command
Write-Host "Starting memory usage monitoring..."

while ($true) {

    Check-MemoryUsage

}




