import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

/// Registers Taskflare.App so Windows toast notifications show the correct
/// app name and icon next to it.
///
/// Uses two mechanisms that together reliably produce the header icon:
///   1. Registry key  HKCU\Software\Classes\AppUserModelId\Taskflare.App
///   2. Start Menu shortcut with System.AppUserModel.ID set (required for icon)
///
/// The bundled PNG (lib/assets/icon.png) is wrapped in an ICO container and
/// written to %LOCALAPPDATA%\Taskflare\taskflare.ico on first run.
class WindowsInitializer {
  static const appId = 'Taskflare.App';
  static const _displayName = 'Taskflare';

  static String get _base =>
      Platform.environment['LOCALAPPDATA'] ??
      '${Platform.environment['USERPROFILE']}\\AppData\\Local';

  static String get iconPath => '$_base\\Taskflare\\taskflare.ico';

  static String get _shortcutPath =>
      '${Platform.environment['APPDATA']}'
      '\\Microsoft\\Windows\\Start Menu\\Programs\\$_displayName.lnk';

  /// Ensures the app is registered with icon. Silently no-ops on failure.
  static Future<void> ensureRegistered() async {
    try {
      final ico = iconPath;
      await _ensureIconExists(ico);
      if (!await _isRegistered()) await _register(ico);
    } catch (_) {}
  }

  /// True only if registry key exists, shortcut exists, and ICO file is present.
  static Future<bool> _isRegistered() async {
    final reg = await Process.run('reg', [
      'query',
      'HKCU\\Software\\Classes\\AppUserModelId\\$appId',
    ]);
    if (reg.exitCode != 0) return false;
    if (!File(iconPath).existsSync()) return false;
    return File(_shortcutPath).existsSync();
  }

  static Future<void> _register(String ico) async {
    final key = 'HKCU\\Software\\Classes\\AppUserModelId\\$appId';
    await Process.run('reg', ['add', key, '/f']);
    await Process.run('reg', ['add', key, '/v', 'DisplayName', '/t', 'REG_SZ', '/d', _displayName, '/f']);
    await Process.run('reg', ['add', key, '/v', 'IconUri', '/t', 'REG_SZ', '/d', ico, '/f']);
    await _createStartMenuShortcut(ico);
  }

  // Creates a Start Menu shortcut with the AppUserModelID property set.
  // This is what Windows actually uses to resolve the notification header icon.
  static Future<void> _createStartMenuShortcut(String ico) async {
    final dartExe = Platform.resolvedExecutable;
    final lnk = _shortcutPath.replaceAll('\\', '\\\\');
    final icoEscaped = ico.replaceAll('\\', '\\\\');
    final dartEscaped = dartExe.replaceAll('\\', '\\\\');

    final script = r'''
Add-Type -Language CSharp -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Runtime.InteropServices.ComTypes;

[ComImport, Guid("000214F9-0000-0000-C000-000000000046"),
 InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
public interface IShellLink {
  void GetPath([Out, MarshalAs(UnmanagedType.LPWStr)] System.Text.StringBuilder f, int c, IntPtr p, int g);
  void GetIDList(out IntPtr p); void SetIDList(IntPtr p);
  void GetDescription([Out, MarshalAs(UnmanagedType.LPWStr)] System.Text.StringBuilder f, int c);
  void SetDescription([MarshalAs(UnmanagedType.LPWStr)] string s);
  void GetWorkingDirectory([Out, MarshalAs(UnmanagedType.LPWStr)] System.Text.StringBuilder f, int c);
  void SetWorkingDirectory([MarshalAs(UnmanagedType.LPWStr)] string s);
  void GetArguments([Out, MarshalAs(UnmanagedType.LPWStr)] System.Text.StringBuilder f, int c);
  void SetArguments([MarshalAs(UnmanagedType.LPWStr)] string s);
  void GetHotkey(out short h); void SetHotkey(short h);
  void GetShowCmd(out int i); void SetShowCmd(int i);
  void GetIconLocation([Out, MarshalAs(UnmanagedType.LPWStr)] System.Text.StringBuilder f, int c, out int i);
  void SetIconLocation([MarshalAs(UnmanagedType.LPWStr)] string s, int i);
  void SetRelativePath([MarshalAs(UnmanagedType.LPWStr)] string s, int r);
  void Resolve(IntPtr h, int f); void SetPath([MarshalAs(UnmanagedType.LPWStr)] string s);
}

[ComImport, Guid("886D8EEB-8CF2-4446-8D02-CDBA1DBDCF99"),
 InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
public interface IPropertyStore {
  void GetCount(out uint c);
  void GetAt(uint i, out PropertyKey k);
  void GetValue(ref PropertyKey k, out PropVariant v);
  [PreserveSig] int SetValue(ref PropertyKey k, ref PropVariant v);
  [PreserveSig] int Commit();
}

[StructLayout(LayoutKind.Sequential)] public struct PropertyKey { public Guid f; public uint p; }

[StructLayout(LayoutKind.Explicit)] public struct PropVariant {
  [FieldOffset(0)] public ushort vt;
  [FieldOffset(8)] public IntPtr ptr;
}

public class Shortcut {
  private static readonly Guid CLSID_ShellLink = new Guid("00021401-0000-0000-C000-000000000046");
  private static readonly PropertyKey PKEY_AppUserModel_ID = new PropertyKey {
    f = new Guid("9F4C2855-9F79-4B39-A8D0-E1D42DE1D5F3"), p = 5
  };
  public static void Create(string lnk, string target, string icon, string appId) {
    var type = Type.GetTypeFromCLSID(CLSID_ShellLink);
    var inst = Activator.CreateInstance(type);
    var sl = (IShellLink)inst;
    sl.SetPath(target);
    sl.SetIconLocation(icon, 0);
    var ps = (IPropertyStore)inst;
    var pv = new PropVariant { vt = 31 }; // VT_LPWSTR
    pv.ptr = Marshal.StringToCoTaskMemUni(appId);
    var key = PKEY_AppUserModel_ID;
    ps.SetValue(ref key, ref pv);
    Marshal.FreeCoTaskMem(pv.ptr);
    ps.Commit();
    var pf = (IPersistFile)inst;
    pf.Save(lnk, true);
  }
}
"@
''' +
        '[Shortcut]::Create("$lnk", "$dartEscaped", "$icoEscaped", "$appId")'
            .replaceAll(r'$lnk', lnk)
            .replaceAll(r'$dartEscaped', dartEscaped)
            .replaceAll(r'$icoEscaped', icoEscaped)
            .replaceAll(r'$appId', appId);

    await Process.run('powershell', ['-NoProfile', '-Command', script]);
  }

  static Future<void> _ensureIconExists(String path) async {
    final file = File(path);
    if (file.existsSync()) return;
    await file.parent.create(recursive: true);
    final png = await _readBundledIcon();
    if (png != null) await file.writeAsBytes(_pngToIco(png));
  }

  // Wraps a PNG in a Vista+ ICO container (Windows supports PNG-inside-ICO).
  static Uint8List _pngToIco(Uint8List png) {
    final buf = BytesBuilder();
    void u16(int v) => buf.add([v & 0xFF, (v >> 8) & 0xFF]);
    void u32(int v) =>
        buf.add([v & 0xFF, (v >> 8) & 0xFF, (v >> 16) & 0xFF, (v >> 24) & 0xFF]);

    u16(0); u16(1); u16(1); // ICONDIR: reserved, type=ICO, count=1

    // ICONDIRENTRY
    buf.addByte(0);        // width:  0 = 256
    buf.addByte(0);        // height: 0 = 256
    buf.addByte(0);        // color count
    buf.addByte(0);        // reserved
    u16(1);                // planes
    u16(32);               // bit count
    u32(png.length);       // size of image data
    u32(22);               // offset = 6 (ICONDIR) + 16 (ICONDIRENTRY)

    buf.add(png);
    return buf.takeBytes();
  }

  static Future<Uint8List?> _readBundledIcon() async {
    final uri = await Isolate.resolvePackageUri(
      Uri.parse('package:taskflare/assets/icon.png'),
    );
    if (uri == null) return null;
    final file = File.fromUri(uri);
    if (!file.existsSync()) return null;
    return file.readAsBytes();
  }
}
