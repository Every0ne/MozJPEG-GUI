#pragma compile( LegalCopyright, 'MIT Licence' )
#pragma compile( ProductName, 'MozJPEG GUI' )
#pragma compile( ProductVersion, '1.0.0' )
#pragma compile( FileVersion, '1.0.0' )
#pragma compile( Icon, '.\MozJPEG GUI.ico' )

#pragma compile( ExecLevel, asInvoker )
#pragma compile( UPX, true )
#pragma compile( Compression, 9 )
#pragma compile( Compatibility, vista )
#pragma compile( x64, true )

#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <GUIListBox.au3>
#include <SliderConstants.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <Array.au3>
#include <String.au3>
#include <File.au3>

Opt( 'TrayIconHide', 1 )
Opt( 'GUIOnEventMode', 1 )

$AppWindow = GUICreate( 'MozJPEG GUI', 257, 257, 192, 124, -1, $WS_EX_ACCEPTFILES )
GUISetOnEvent( $GUI_EVENT_DROPPED, 'DropHandle' )
GUISetOnEvent( $GUI_EVENT_CLOSE, 'AppWindowClose' )

global $quality = 90
global $DropZoneLabelTxt = 'Drop files here'
global $thisDir = SlashPath( @ScriptDir )

global $Progressive = GUICtrlCreateCheckbox( 'Progressive', 16, 8, 113, 25 )
GUICtrlSetState( -1, $GUI_CHECKED )

global $Grayscale = GUICtrlCreateCheckbox( 'Grayscale', 136, 8, 113, 25 )

global $QualitySlider = GUICtrlCreateSlider( 8, 40, 200, 32 )
GUICtrlSetOnEvent( $QualitySlider, 'QualitySliderChange')
GUICtrlSetLimit( $QualitySlider, 100, 0 )
GUICtrlSetData( $QualitySlider, $quality )

global $QualityInput = GUICtrlCreateInput( 'QualityInput', 208, 40, 40, 24, BitOR( $GUI_SS_DEFAULT_INPUT,$ES_CENTER,$ES_NUMBER ) )
GUICtrlSetFont( $QualityInput, 10, 400, 0, 'MS Sans Serif' )
GUICtrlSetLimit( $QualityInput, 3 )
GUICtrlSetData( $QualityInput, $quality )
GUICtrlSetOnEvent( $QualityInput, 'QualityInputChange' )

global $DropZone = GUICtrlCreateInput( '', 6, 80, 244, 98, BitOR( $SS_CENTER, $ES_MULTILINE, $WS_DISABLED ), 0 )
GUICtrlSetState( $DropZone, $GUI_DROPACCEPTED )

Global $DropZoneLabel = GUICtrlCreateLabel( $DropZoneLabelTxt, 88, 120, 91, 20, BitOR( $SS_CENTER, $SS_CENTERIMAGE ) )
GUICtrlSetFont( -1, 11, 400, 0, 'MS Sans Serif' )

global $Output = GUICtrlCreateList( '', 0, 185, 256, 71 )
GUICtrlSetOnEvent( $Output, 'OutputClick' )

GUISetState(@SW_SHOW)

While 1
	Sleep(100)
WEnd

Func AppWindowClose()
	Exit
EndFunc

Func OutputClick()
	GUICtrlSetData( $Output, '' )
EndFunc

Func sanitizeRange( $nr )
	if $nr > 100 then
		return 100
	elseif $nr < 0 then
		return 0
	else
		return $nr
	endif
EndFunc

Func QualityInputChange()
	local $newQuality = Int( GUICtrlRead( $QualityInput ) )

	if IsInt( $newQuality ) then
		$quality = sanitizeRange( $newQuality )
		GUICtrlSetData( $QualityInput, $quality )
		GUICtrlSetData( $QualitySlider, $quality )
	else
		return
	endif
EndFunc

Func QualitySliderChange()
	local $newQuality = GUICtrlRead( $QualitySlider )
	$quality = $newQuality
	GUICtrlSetData( $QualityInput, $quality )
EndFunc

Func IsDir( $path )
	Return StringInStr( FileGetAttrib( $path ), 'D' ) > 0
EndFunc

Func IsAllowedFile( $path )
	return StringRegExp( PathInfo( $path )[4], '(?i)(jpe?g|jpg|bmp|png|tga)' )
EndFunc

Func PathInfo( $path )
	local $drive
	local $dir
	local $filename
	local $ext
	local $pathInfo = _PathSplit( $path, $drive, $dir, $filename, $ext )
	return $pathInfo
EndFunc

Func SlashPath( $path, $delim = '\' )
    If StringRight( $path, 1 ) <> $delim Then
        $path &= $delim
    EndIf
    Return( $path )
EndFunc

; The main function where most of the work happens.
Func DropHandle( $hWnd, $msgID, $wParam, $lParam )
	local $filesStr = GUICtrlRead( $DropZone )
	local $paths = _StringExplode( $filesStr, '|' )
	local $files[0]
	local $run = 'cjpeg.exe -quality ' & $quality & ' -optimize -progressive -grayscale -dct float -nojfif '

	If GUICtrlRead( $Progressive ) <> 1 Then
		$run = StringReplace( $run, ' -progressive', '' )
	EndIf

	If GUICtrlRead( $Grayscale ) <> 1 Then
		$run = StringReplace( $run, ' -grayscale', '' )
	EndIf

	$run = $thisDir & $run

	; Reset field state
	GUICtrlSetData( $DropZone, '' )
	GUICtrlSetData( $DropZoneLabel, $DropZoneLabelTxt )
	GUICtrlSetData( $Output, '' )
	
	For $path In $paths
		If IsDir( $path ) or not IsAllowedFile( $path ) then
			ContinueLoop
		Else
			_ArrayAdd( $files, $path )
		EndIf
	Next

	GUICtrlSetData( $Output, _ArrayToString( $files, '|' ) )

	For $file in $files
		$p = PathInfo( $file )
		Run( @ComSpec & " /c " & $run & '"' & $file & '"' & ' > ' & '"' & $p[1] & $p[2] & 'moz-' & $quality & '-' & $p[3] & '.jpg"' )
	Next
EndFunc
