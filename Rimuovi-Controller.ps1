# Rimuovi-Controller.ps1
# Equivale a premere "Rimuovi" sul dispositivo in Impostazioni > Bluetooth e dispositivi.
# Cambia il nome qui sotto se il tuo dispositivo si chiama diversamente.
param(
    [string]$NomeDispositivo = "Wireless Controller"
)

Add-Type -AssemblyName System.Runtime.WindowsRuntime

# Carica i tipi WinRT necessari
[void][Windows.Devices.Enumeration.DeviceInformation, Windows.Devices.Enumeration, ContentType = WindowsRuntime]
[void][Windows.Devices.Enumeration.DeviceInformationCollection, Windows.Devices.Enumeration, ContentType = WindowsRuntime]
[void][Windows.Devices.Enumeration.DeviceUnpairingResult, Windows.Devices.Enumeration, ContentType = WindowsRuntime]
[void][Windows.Devices.Bluetooth.BluetoothDevice, Windows.Devices.Bluetooth, ContentType = WindowsRuntime]
[void][Windows.Devices.Bluetooth.BluetoothLEDevice, Windows.Devices.Bluetooth, ContentType = WindowsRuntime]

# Helper per attendere le operazioni asincrone WinRT
$asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
    $_.Name -eq 'AsTask' -and
    $_.GetParameters().Count -eq 1 -and
    $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1'
})[0]

function Await($operazione, [Type]$tipoRisultato) {
    $task = $asTaskGeneric.MakeGenericMethod($tipoRisultato).Invoke($null, @($operazione))
    [void]$task.Wait(-1)
    return $task.Result
}

# Cerca tra i dispositivi Bluetooth già associati (classici e LE)
$selettori = @(
    [Windows.Devices.Bluetooth.BluetoothDevice]::GetDeviceSelectorFromPairingState($true),
    [Windows.Devices.Bluetooth.BluetoothLEDevice]::GetDeviceSelectorFromPairingState($true)
)

$trovati = @()
foreach ($sel in $selettori) {
    $lista = Await ([Windows.Devices.Enumeration.DeviceInformation]::FindAllAsync($sel)) ([Windows.Devices.Enumeration.DeviceInformationCollection])
    foreach ($d in $lista) {
        if ($d.Name -eq $NomeDispositivo) { $trovati += $d }
    }
}

if ($trovati.Count -eq 0) {
    Write-Host "Nessun dispositivo associato chiamato '$NomeDispositivo' trovato." -ForegroundColor Yellow
    exit 1
}

foreach ($dev in $trovati) {
    Write-Host "Rimuovo: $($dev.Name) ..."
    $risultato = Await ($dev.Pairing.UnpairAsync()) ([Windows.Devices.Enumeration.DeviceUnpairingResult])
    Write-Host "Esito: $($risultato.Status)" -ForegroundColor Green
}
