Function Expand-File {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$infile,

        [string]$outfile = ($infile -replace '\.gz$', '')
    )

    try {
        # Validate input file
        if (-not (Test-Path -Path $infile)) {
            throw "Input file '$infile' does not exist."
        }

        # Open input and output file streams
        $in = New-Object System.IO.FileStream $infile, ([IO.FileMode]::Open), ([IO.FileAccess]::Read), ([IO.FileShare]::Read)
        $output = New-Object System.IO.FileStream $outfile, ([IO.FileMode]::Create), ([IO.FileAccess]::Write), ([IO.FileShare]::None)
        $gzipStream = New-Object System.IO.Compression.GzipStream $in, ([IO.Compression.CompressionMode]::Decompress)

        # Buffer for reading data
        $buffer = New-Object byte[](1024)
        while ($true) {
            $read = $gzipStream.Read($buffer, 0, $buffer.Length)
            if ($read -le 0) { break }
            $output.Write($buffer, 0, $read)
        }
    }
    catch {
        Write-Error "An error occurred: $_"
    }
    finally {
        # Ensure streams are closed
        if ($gzipStream) { $gzipStream.Close() }
        if ($output) { $output.Close() }
        if ($in) { $in.Close() }
    }

    # Remove the input file
    Remove-Item -Path $infile -ErrorAction SilentlyContinue
}
