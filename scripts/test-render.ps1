Param(
    [string]$OpenScadPath,
    [string[]]$ScadScriptFolders = @(
            (Get-Item $MyInvocation.MyCommand.Source).Directory.Parent.FullName
            ),
    [switch]$saveResults,
    [string]$outputScriptFolder = 'test_results',
    [switch]$CompareMeshes,
    [string]$PythonPath
)

if ($CompareMeshes -and [string]::IsNullOrWhiteSpace($PythonPath)) {
    throw "-CompareMeshes requires -PythonPath pointing to a Python 3.9+ executable."
}

if (-not $OpenScadPath) {

    # Try PATH first
    $cmd = Get-Command 'openscad.exe' -ErrorAction SilentlyContinue

    if ($cmd) {
        $OpenScadPath = $cmd.Source
    }
    else {
        # Common Windows install paths
        $candidates = @(
            $OpenScadPath,
            $env:OPENSCAD_PATH,
            "C:\tools\OpenSCAD\openscad.exe",
            "C:\Program Files\OpenSCAD\openscad.exe",
            "C:\Program Files (x86)\OpenSCAD\openscad.exe"
        )

        foreach ($path in $candidates) {
            if (![string]::IsNullOrEmpty($path) -and (Test-Path -Path $path)) {
                $OpenScadPath = $path
                break
            }
        }
    }
}

if (-not $OpenScadPath) {
    throw "OpenSCAD not found. Set OPENSCAD_PATH or pass -OpenScadPath"
}

function Start-ProcessWithOutputs
{
    param (
        [Parameter(Mandatory=$false)] [string]$commandTitle,
        [Parameter(Mandatory=$true)] [string]$commandPath,
        [Parameter(Mandatory=$false)] [string[]]$ArgumentList
    )

    $StandardOutputSourceIdentifier = "StandardOutput$([Guid]::NewGuid())"
    $StandardErrorSourceIdentifier = "StandardError$([Guid]::NewGuid())"
    $messagedata = new-object psobject -property @{
       StandardOutput= New-Object -TypeName System.Text.StringBuilder
       StandardError = New-Object -TypeName System.Text.StringBuilder}

    $pinfo = New-object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = $commandPath
    $pinfo.CreateNoWindow = $true
    $pinfo.UseShellExecute = $false
    $pinfo.RedirectStandardOutput = $true
    $pinfo.RedirectStandardError = $true
    $pinfo.Arguments = $ArgumentList

    $Process = New-Object System.Diagnostics.Process
    $Process.StartInfo = $pinfo

    $ProcessOutputEventAction = {
        if (![string]::IsNullOrEmpty($EventArgs.Data)){
            $Event.MessageData.StandardOutput.AppendLine($EventArgs.Data)
        }
    }

    $ProcessErrorEventAction = {
        if (![string]::IsNullOrEmpty($EventArgs.Data)){
            $Event.MessageData.StandardError.AppendLine($EventArgs.Data)
        }
    }

    $OutputDataReceivedEvent = Register-ObjectEvent -SourceIdentifier $StandardOutputSourceIdentifier -InputObject $Process -EventName "OutputDataReceived" -Action $ProcessOutputEventAction -messagedata $messagedata
    $ErrorDataReceivedEvent = Register-ObjectEvent -SourceIdentifier $StandardErrorSourceIdentifier -InputObject $Process -EventName "ErrorDataReceived" -Action $ProcessErrorEventAction -messagedata $messagedata

    $executionTime = Measure-Command {
        $Process.Start() | Out-Null
        $Process.BeginErrorReadLine()
        $Process.BeginOutputReadLine()
        $Process.WaitForExit()
    }

    Start-Sleep -Milliseconds 200

    Unregister-Event -SourceIdentifier $StandardOutputSourceIdentifier
    Unregister-Event -SourceIdentifier $StandardErrorSourceIdentifier

    return [pscustomobject]@{
        commandTitle = $commandTitle
        ExitCode = $Process.ExitCode;
        stdout = $messagedata.StandardOutput.ToString();
        stderr = $messagedata.StandardError.ToString();
        ExitTime = $Process.ExitTime;
        StartTime = $Process.StartTime;
        executionTime = $executionTime
    }
}

function Test-OpenSCAD(
        $TargetFile,
        [bool]$saveResults = $false,
        $cmdArgsInput = '',
        $saveAppend = '',
        [string]$expectedErrorPattern = '')
{
    $scadScriptPath = $TargetFile.FullName

    Write-Host "`r`nTesting '$($scadScriptPath)' input_args:'$($cmdArgsInput)'"

    $cmdArgs = ''
    if($saveResults) {
        $cmdArgs += " -o `"$(Join-Path $outputScriptFolderPath $TargetFile.BaseName)$($saveAppend).stl`""
    }
    else {
        $cmdArgs += " -o NUL"
    }

    $cmdArgs += $cmdArgsInput
    $cmdArgs += " --export-format binstl"
    $cmdArgs += " --enable textmetrics"
    $cmdArgs += " --backend Manifold"

    $cmdArgs += " $($scadScriptPath)"
    Write-Host  $cmdArgs
    $executionResult = (Start-ProcessWithOutputs -commandPath $script:OpenScadPath -ArgumentList $cmdArgs)

    write-host "openscad executionTime: $($executionResult.executionTime)"

    $isExpectedFailure = -not [string]::IsNullOrWhiteSpace($expectedErrorPattern)
    $isParserOrIncludeFailure = $executionResult.stderr -match "(?im)(parser error|syntax error|can't open include file|can't open library|unable to open file)"
    $hasAssertionError = $executionResult.stderr -match "(?im)^error:\s*assertion\b"

    if ($isExpectedFailure) {
        $hasExpectedError = $executionResult.stderr -match $expectedErrorPattern
        if ($hasExpectedError -and $hasAssertionError -and -not $isParserOrIncludeFailure -and $executionResult.stderr -notmatch '(?im)^warning:') {
            write-Host "Expected assertion failure observed." -ForegroundColor Green
            return $true
        }
        Write-Warning "Expected assertion failure did not match criteria in $($TargetFile.Name)"
        Write-Warning "ExitCode: $($executionResult.ExitCode)"
        Write-Warning "stderr: $($executionResult.stderr)"
        return $false
    }

    # Check for warnings/errors
    if ($executionResult.stderr -match '(?im)^(warning|error):' -or $executionResult.ExitCode -ne 0) {
        Write-Warning "OpenSCAD warnings/errors in $($TargetFile.Name)"
        write-warning "stderr: $($executionResult.stderr)"
        return $false
    } else {
        write-Host "ExitCode: $($executionResult.ExitCode)" -ForegroundColor Green
        #write-Host "stderr: $($executionResult.stderr)"
        return $true
    }
}

$ErrorActionPreference = "Stop"

$repositoryRoot = (Get-Item $MyInvocation.MyCommand.Source).Directory.Parent.FullName
$oneidaTestsFolder = Join-Path $repositoryRoot "scripts/tests"
if (-not ($ScadScriptFolders -contains $oneidaTestsFolder)) {
    $ScadScriptFolders += $oneidaTestsFolder
}

$oneidaExpectedFailureCases = @(
    @{ case = "invalid_nominal_13"; pattern = "Unsupported Oneida nominal diameter" },
    @{ case = "invalid_nominal_15"; pattern = "Unsupported Oneida nominal diameter" },
    @{ case = "invalid_nominal_17"; pattern = "Unsupported Oneida nominal diameter" },
    @{ case = "invalid_nominal_fractional"; pattern = "Unsupported Oneida nominal diameter" },
    @{ case = "invalid_nominal_type"; pattern = "Oneida nominal diameter must be a positive number" },
    @{ case = "invalid_fit_type"; pattern = "Oneida fit adjustment must be a number" },
    @{ case = "below_min_length"; pattern = "length must be at least" },
    @{ case = "bore_invalid"; pattern = "positive bore" },
    @{ case = "fit_shrinks_bore"; pattern = "positive bore" },
    @{ case = "factory_below_min_length"; pattern = "length must be 0 or at least" },
    @{ case = "factory_unsupported_nominal"; pattern = "Unsupported Oneida nominal diameter" }
)

$slowClampExpectedFailureCases = @(
    @{ case = "invalid_output_mode"; pattern = "outputMode must be one of" },
    @{ case = "invalid_output_end"; pattern = "outputEnd must be one of" },
    @{ case = "alignment_end3"; pattern = "Alignment ring output supports only end1 or end2" },
    @{ case = "legacy_conflict_with_slowclamp"; pattern = "conflicts with outputMode=slowclamp" },
    @{ case = "legacy_conflict_with_alignment_mode"; pattern = "conflicts with outputMode=alignment_ring" },
    @{ case = "selected_non_oneida_end2"; pattern = "SlowClamp output requires the selected output end to be Oneida" },
    @{ case = "legacy_invalid_selector"; pattern = "drawAlignmentRing must be one of: no, end1, end2" },
    @{ case = "adapter_selected_oneida_length_below_min"; pattern = "length must be 0 or at least" }
)

$rootSlowClampCases = @(
    @{ suffix = "slowclamp_end1"; args = " -D `"Output_Mode=`"`"slowclamp`"`"`" -D `"Output_End=`"`"end1`"`"`" -D `"End1_Style=`"`"hose`"`"`" -D `"End1_Specialised_Style=`"`"oneida`"`"`" -D `"End1_Oneida_Size=5`" -D `"End1_Oneida_Fit_Adjustment=0`" -D `"Transition_Bend_Pipe_Diameter=`"`"custom`"`"`" -D `"Transition_Custom_Bend_Pipe_Diameter=0`" -D `"End2_Style=`"`"not_a_real_style`"`"`"" },
    @{ suffix = "slowclamp_end2_nom6_fitpos"; args = " -D `"Output_Mode=`"`"slowclamp`"`"`" -D `"Output_End=`"`"end2`"`"`" -D `"End2_Style=`"`"hose`"`"`" -D `"End2_Specialised_Style=`"`"oneida`"`"`" -D `"End2_Oneida_Size=6`" -D `"End2_Oneida_Fit_Adjustment=0.5`" -D `"Transition_Bend_Pipe_Diameter=`"`"custom`"`"`" -D `"Transition_Custom_Bend_Pipe_Diameter=0`" -D `"End3_Style=`"`"not_a_real_style`"`"`"" },
    @{ suffix = "slowclamp_end3_nom5_fitneg"; args = " -D `"Output_Mode=`"`"slowclamp`"`"`" -D `"Output_End=`"`"end3`"`"`" -D `"End3_Style=`"`"hose`"`"`" -D `"End3_Specialised_Style=`"`"oneida`"`"`" -D `"End3_Oneida_Size=5`" -D `"End3_Oneida_Fit_Adjustment=-0.5`" -D `"Transition_Bend_Pipe_Diameter=`"`"custom`"`"`" -D `"Transition_Custom_Bend_Pipe_Diameter=0`" -D `"End2_Style=`"`"not_a_real_style`"`"`"" },
    @{ suffix = "slowclamp_end1_selected_len1_unselected_invalid"; args = " -D `"Output_Mode=`"`"slowclamp`"`"`" -D `"Output_End=`"`"end1`"`"`" -D `"End1_Style=`"`"hose`"`"`" -D `"End1_Specialised_Style=`"`"oneida`"`"`" -D `"End1_Oneida_Size=5`" -D `"End1_Length=[1,0]`" -D `"End2_Style=`"`"hose`"`"`" -D `"End2_Specialised_Style=`"`"oneida`"`"`" -D `"End2_Oneida_Size=6`" -D `"End2_Length=[1,0]`" -D `"End3_Style=`"`"hose`"`"`" -D `"End3_Specialised_Style=`"`"oneida`"`"`" -D `"End3_Oneida_Size=5`" -D `"End3_Length=[1,0]`" -D `"Transition_Bend_Pipe_Diameter=`"`"custom`"`"`" -D `"Transition_Custom_Bend_Pipe_Diameter=0`"" },
    @{ suffix = "slowclamp_end2_unselected_invalid_lengths"; args = " -D `"Output_Mode=`"`"slowclamp`"`"`" -D `"Output_End=`"`"end2`"`"`" -D `"End1_Style=`"`"hose`"`"`" -D `"End1_Specialised_Style=`"`"oneida`"`"`" -D `"End1_Oneida_Size=5`" -D `"End1_Length=[1,0]`" -D `"End2_Style=`"`"hose`"`"`" -D `"End2_Specialised_Style=`"`"oneida`"`"`" -D `"End2_Oneida_Size=6`" -D `"End2_Oneida_Fit_Adjustment=0.5`" -D `"End3_Style=`"`"hose`"`"`" -D `"End3_Specialised_Style=`"`"oneida`"`"`" -D `"End3_Oneida_Size=5`" -D `"End3_Length=[1,0]`" -D `"Transition_Bend_Pipe_Diameter=`"`"custom`"`"`" -D `"Transition_Custom_Bend_Pipe_Diameter=0`"" },
    @{ suffix = "slowclamp_end3_unselected_invalid_lengths"; args = " -D `"Output_Mode=`"`"slowclamp`"`"`" -D `"Output_End=`"`"end3`"`"`" -D `"End1_Style=`"`"hose`"`"`" -D `"End1_Specialised_Style=`"`"oneida`"`"`" -D `"End1_Oneida_Size=5`" -D `"End1_Length=[1,0]`" -D `"End2_Style=`"`"hose`"`"`" -D `"End2_Specialised_Style=`"`"oneida`"`"`" -D `"End2_Oneida_Size=6`" -D `"End2_Length=[1,0]`" -D `"End3_Style=`"`"hose`"`"`" -D `"End3_Specialised_Style=`"`"oneida`"`"`" -D `"End3_Oneida_Size=5`" -D `"End3_Oneida_Fit_Adjustment=-0.5`" -D `"Transition_Bend_Pipe_Diameter=`"`"custom`"`"`" -D `"Transition_Custom_Bend_Pipe_Diameter=0`"" },
    @{ suffix = "slowclamp_end1_extension_exit_160"; args = " -D `"Output_Mode=`"`"slowclamp`"`"`" -D `"Output_End=`"`"end1`"`"`" -D `"End1_Style=`"`"hose`"`"`" -D `"End1_Specialised_Style=`"`"oneida`"`"`" -D `"End1_Oneida_Size=5`" -D `"End1_Extension_Exit_Diameter=160`" -D `"Transition_Bend_Pipe_Diameter=`"`"custom`"`"`" -D `"Transition_Custom_Bend_Pipe_Diameter=0`" -D `"End2_Style=`"`"not_a_real_style`"`"`"" },
    @{ suffix = "slowclamp_end1_extension_slipring"; args = " -D `"Output_Mode=`"`"slowclamp`"`"`" -D `"Output_End=`"`"end1`"`"`" -D `"End1_Style=`"`"hose`"`"`" -D `"End1_Specialised_Style=`"`"oneida`"`"`" -D `"End1_Oneida_Size=5`" -D `"End1_Extension_Exit_Diameter=160`" -D `"End1_Extension_SlipRing=`"`"outer`"`"`" -D `"Transition_Bend_Pipe_Diameter=`"`"custom`"`"`" -D `"Transition_Custom_Bend_Pipe_Diameter=0`" -D `"End2_Style=`"`"not_a_real_style`"`"`"" },
    @{ suffix = "alignment_ring_end2"; args = " -D `"Output_Mode=`"`"alignment_ring`"`"`" -D `"Output_End=`"`"end2`"`"`" -D `"End2_Style=`"`"mag`"`"`"" },
    @{ suffix = "legacy_alignment_end1"; args = " -D `"Output_Mode=`"`"adapter`"`"`" -D `"Draw_Alignment_Ring=`"`"end1`"`"`" -D `"End1_Style=`"`"mag`"`"`"" }
)

$oneidaDemoRelativePaths = @(
    "demos/oneida_adapter.scad",
    "demos/oneida_fit_ring.scad",
    "demos/oneida_slow_clamp.scad"
)

$failed = $false
$ScadScriptFolders |ForEach-Object {
    $ScadScriptFolder = $_
    write-host "path: $ScadScriptFolder"
    $outputScriptFolderPath = Join-Path $ScadScriptFolder $outputScriptFolder
    if($saveResults) {
        if(!(Test-Path -Path $outputScriptFolderPath)) {
            New-Item -ItemType Directory -Path $outputScriptFolderPath -Force
        }
    }

    Get-ChildItem -LiteralPath $ScadScriptFolder -Filter *.scad | ForEach-Object {
    $TargetFile = $_
    if($TargetFile.BaseName -ieq 'oneida_expected_failures'){
        $oneidaExpectedFailureCases | ForEach-Object {
            $caseName = $_.case
            $input_args = " -D `"Case=`"`"$($caseName)`"`"`""
            $success = Test-OpenSCAD -TargetFile $TargetFile -saveResults $saveResults -cmdArgsInput $input_args -SaveAppend "_$($caseName)" -expectedErrorPattern $_.pattern
            if(!$success){
                $failed = $true
            }
        }
    }
    elseif($TargetFile.BaseName -ieq 'slow_clamp_output_expected_failures'){
        $slowClampExpectedFailureCases | ForEach-Object {
            $caseName = $_.case
            $input_args = " -D `"Case=`"`"$($caseName)`"`"`""
            $success = Test-OpenSCAD -TargetFile $TargetFile -saveResults $saveResults -cmdArgsInput $input_args -SaveAppend "_$($caseName)" -expectedErrorPattern $_.pattern
            if(!$success){
                $failed = $true
            }
        }
    }
    elseif($TargetFile.BaseName -ieq 'vacuum-hose-adapter'){

        $styles = @('mag', 'flange', 'hose', 'dyson', 'camlock', 'dw735', 'centec_female', 'centec_male', 'osvacm32', 'osvacm', 'osvacf32', 'osvacf', 'makita_male', 'bosch_sander', 'festoolcleanteclug', 'oneida')

        $styles | ForEach-Object {
            $style = $_
            $input_args  = " -D `"End1_Style=`"`"$($style)`"`"`""
            $success = Test-OpenSCAD -TargetFile $TargetFile -saveResults $saveResults -cmdArgsInput $input_args -SaveAppend $style
            if(!$success){
                $failed = $true
            }
        }

        $rootSlowClampCases | ForEach-Object {
            $input_args = $_.args
            $success = Test-OpenSCAD -TargetFile $TargetFile -saveResults $saveResults -cmdArgsInput $input_args -SaveAppend "_$($_.suffix)"
            if(!$success){
                $failed = $true
            }
        }
    } else {
        $success = Test-OpenSCAD -TargetFile $TargetFile -saveResults $saveResults
        if(!$success){
            $failed = $true
        }
    }
}}

$oneidaDemoRelativePaths | ForEach-Object {
    $demoFile = Get-Item -LiteralPath (Join-Path $repositoryRoot $_)
    if($saveResults) {
        $outputScriptFolderPath = Join-Path $demoFile.DirectoryName $outputScriptFolder
        New-Item -ItemType Directory -Path $outputScriptFolderPath -Force | Out-Null
    }
    $success = Test-OpenSCAD -TargetFile $demoFile -saveResults $saveResults
    if(!$success){
        $failed = $true
    }
}

if ($CompareMeshes) {
    $meshCompareScript = Join-Path $oneidaTestsFolder "slow_clamp_mesh_compare.py"
    $meshPython = (Get-Command $PythonPath -CommandType Application -ErrorAction Stop).Source
    Write-Host "`r`nRunning SlowClamp CGAL mesh compare..."
    $meshArgs = "`"$meshCompareScript`" --openscad-path `"$OpenScadPath`" --repository-root `"$repositoryRoot`""
    $meshResult = Start-ProcessWithOutputs -commandPath $meshPython -ArgumentList $meshArgs
    if ($meshResult.ExitCode -ne 0 -or $meshResult.stderr -match '(?im)^(warning|error|traceback):') {
        Write-Warning "SlowClamp mesh compare failed"
        Write-Warning "stderr: $($meshResult.stderr)"
        $failed = $true
    } else {
        Write-Host $meshResult.stdout
        Write-Host "SlowClamp CGAL mesh compare passed." -ForegroundColor Green
    }
}

if ($failed) {
    throw "OpenSCAD validation failed"
}

Write-Host "All OpenSCAD files passed."
