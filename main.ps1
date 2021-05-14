#[CmdletBinding()]
#param($Interval = 50000, [switch]$RightClick, [switch]$NoMove)
#Для запуска скрипта с параметрами раскоментировать верние две строки и закоментировать три нижних

$Interval = 50000
$RightClick = $true
$NoMove = $false

#Узнаем разрешение монитора
$screenSize = Get-WmiObject -Class Win32_DesktopMonitor | Select-Object ScreenWidth,ScreenHeight

[Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null

$DebugViewWindow_TypeDef = @'
[DllImport("user32.dll")]
public static extern IntPtr FindWindow(string ClassName, string Title);
[DllImport("user32.dll")]
public static extern IntPtr GetForegroundWindow();
[DllImport("user32.dll")]
public static extern bool SetCursorPos(int X, int Y);
[DllImport("user32.dll")]
public static extern bool GetCursorPos(out System.Drawing.Point pt);

[DllImport("user32.dll", CharSet = CharSet.Auto, CallingConvention = CallingConvention.StdCall)]
public static extern void mouse_event(long dwFlags, long dx, long dy, long cButtons, long dwExtraInfo);

private const int MOUSEEVENTF_LEFTDOWN = 0x02;
private const int MOUSEEVENTF_LEFTUP = 0x04;
private const int MOUSEEVENTF_RIGHTDOWN = 0x08;
private const int MOUSEEVENTF_RIGHTUP = 0x10;

public static void LeftClick(){
    mouse_event(MOUSEEVENTF_LEFTDOWN | MOUSEEVENTF_LEFTUP, 0, 0, 0, 0);
}

public static void RightClick(){
    mouse_event(MOUSEEVENTF_RIGHTDOWN | MOUSEEVENTF_RIGHTUP, 0, 0, 0, 0);
}
'@

Add-Type -MemberDefinition $DebugViewWindow_TypeDef -Namespace AutoClicker -Name Temp -ReferencedAssemblies System.Drawing

$pt = New-Object System.Drawing.Point
if ([AutoClicker.Temp]::GetCursorPos([ref]$pt)) {
    Write-host "Нажимаем ПКМ в точке $($pt.X), $($pt.Y) каждые ${Interval}мс, пока не нажмут Ctrl^C или не нажмут кнопку " -NoNewline
    Write-Host -ForegroundColor Cyan "Пуск " -NoNewline
    while($true) {
        $start = [AutoClicker.Temp]::FindWindow("ImmersiveLauncher", "Start menu")
        $fg = [AutoClicker.Temp]::GetForegroundWindow()

        if ($start -eq $fg) {
            Write-Host "Нажали Пуск. Завершаем работу скрипта"
            return
        }

        if (!$NoMove) {
            #Устанавливаем курсор в случайную точку экрана
            $curPosX = Get-Random -Maximum $screenSize.ScreenWidth -Minimum 1
            $curPosY = Get-Random -Maximum $screenSize.ScreenHeight -Minimum 1
            [AutoClicker.Temp]::SetCursorPos($curPosX, $curPosY) | Out-Null

        }

        if ($RightClick) {
            [AutoClicker.Temp]::RightClick()
        } else {
            [AutoClicker.Temp]::LeftClick()
        }
        sleep -Milliseconds $Interval
    }
}
