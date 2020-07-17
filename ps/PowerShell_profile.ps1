$OutputEncoding = [System.Text.Encoding]::UTF8

function help
{
    get-help $args[0] | out-host -paging
}

function man
{
    get-help $args[0] | out-host -paging
}

function mkdir
{
    new-item -type directory -path $args
}

function md
{
    new-item -type directory -path $args
}

function isPwdRoot
{
	return $pwd.path -eq $(Split-Path $pwd -Qualifier) + "\"
}

function promptParentDir
{
	# Get the parent part for the prompt
	# If we are in a root foler, this just gives the drive letter.
	if (isPwdRoot) {
		return $pwd.path.TrimEnd(':\')
	} else {
		return $(Split-Path $(Split-Path $pwd -Parent) -Leaf).TrimEnd(':\')
	}
}

function promptCurDir
{
	# If we are in the root folder, keep this empty
	if (isPwdRoot) {
		return "";
	} else {
		return "/" + $(Split-Path $pwd -Leaf);
	}
}

function global:prompt {  # Multiple Write-Host commands with color
	Write-Host("λ ") -nonewline -foregroundcolor Magenta
  Write-Host($(promptParentDir) + $(promptCurDir)) -nonewline -foregroundcolor Blue
  return " ∴ "
}
