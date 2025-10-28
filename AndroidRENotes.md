# Android RE Crash Course

## Notes about Android Security
- Sandboxing is insufficient at stopping attacks. 
- Root or non-apk binary attacks are extremely rare in Android.

## Names for Android "attack vectors"
- Phishing:       impersonating a legitimate company or resource to coerce information from someone.
- Toll Fraud:         signing up the user to services without explicit consent.
- Maskware:         looks like one thing but does something completely different.
- A11Y RATs:         literally as described.
- Proxy Trojans:     implant network traffic used for pivoting (P2P)
- Pig Butchering:     slow, methodical scam used to gain investments from a victim
- Click Fraud:         auto clicker, often used to gain PPC (pay per click) traffic
- SMS Fraud:         proxying SMS messages through a pre-owned number
- Adware:             spamming ads

## The basics of Android Ecosystem:
### Entrypoints (Lifecycle)
	- Activity 
		Equivalent to "Main" (OnCreate()). Initiates code in an Activity instance. 
		This is similar to creating a new thread, and allows apps to spin-up new activites in others.
		There is an interface/abstraction to the Activity Manager/service (Activity Thread).

	- Application 
		Similar to Activity (needs clarification).

	- Services 
		Background services/application component. Foreground, Background or Bound.
		Might include Networking/IPC, I/O, Music Player, Notifs/Toasts, etc. These run in the main thread of it's hosting process, unless specified.
		Similar to a new thread, but not the same thing (need further clarification?)

	- Content Providers 
		An interface/abstraction used to access app data, encapsulating the data,
		and providing mechanisms for defining data security. 

		A number of other classes rely on the `ContentProvider` class:
			- AbstractThreadedSyncAdapter
			- CursorAdapter
			- CursorLoader

		In addition, you need your own content provider in the folowing cases:
			- To implement custom search suggestions in your app.
			- To expose your application data to widgets.
			- To copy/paste complex data or files from you app to others.

	- Broadcast Receivers 
		System and app level IPC. These are full Objects, not encoded datatypes. They are called "Intent".
		An intent is an abstract description of an operation to be performed:

```java
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;

public class IntentInspector {
    public static void main(String[] args) {
        // Create a simulated broadcast-style Intent
        Intent intent = new Intent();
        intent.setAction("android.intent.action.BOOT_COMPLETED");
        intent.setData(Uri.parse("package:com.example.app"));
        intent.setType("application/vnd.android.package-archive");
        intent.setPackage("com.example");
        intent.setFlags(Intent.FLAG_RECEIVER_REGISTERED_ONLY | Intent.FLAG_ACTIVITY_NEW_TASK);

        // Add extras (key/value pairs)
        Bundle extras = new Bundle();
        extras.putString("EXTRA_REASON", "device_rebooted");
        extras.putLong("EXTRA_TIMESTAMP", System.currentTimeMillis());
        extras.putInt("EXTRA_USER", 0);
        intent.putExtras(extras);

        // Print full object structure
        System.out.println("=== Intent Object ===");
        System.out.println(intent.toString());

        System.out.println("\n=== Extras ===");
        for (String key : intent.getExtras().keySet()) {
            System.out.println(key + " -> " + intent.getExtras().get(key));
        }

        // Optional: Inspect raw Parcel contents
        android.os.Parcel p = android.os.Parcel.obtain();
        intent.writeToParcel(p, 0);
        byte[] raw = p.marshall();
        System.out.println("\n=== Raw Parcel Bytes (hex) ===");
        for (byte b : raw) System.out.printf("%02X ", b);
        p.recycle();
    }
}
```

### Common Frameworks
	- XML View (Legacy) - XML Resource Layouts within an application.
	- Jetpack Compose - Standalone library for building native UI.
	- React Native - JS React in Android. Compiled into Hermes Bytecode (difficult).
	- Cordova - Statically served website framework.
	- Unity - C# Game Development engine, AOT compiled to IL2CPP.
	- Flutter - Built using Dart, AOT compiled to native code.

### Permission Model
	Android apps don't have many OOB privileges and must request them.
	Some permissions are more dangerous than others:
		- BIND_ACCESSIBILITY_SERVICE
		- READ_SMS, SEND_SMS, CALL_PHONE
		- BIND_NOTIFICATION_LISTENER
		- REQUEST_INSTALL_PACKAGES

## The Sandbox
### Application Sandbox
	- /data/data/package.name.app
	- Each app is launched as it's own user ID.
	- Each app has it's own storage.
	- Almost all IPC is done through Binder
	- SELinux is another access control level above the standard Linux permission model.
	Essentially an App-domain (might be called "Untrusted App") using categories for permission.

### System Server (uid=1000)
	- Collection of services running as uid 1000 within the sandbox
	- e.g. TelephonyMan, LocationMan, PackageMan and many more~!

### Zygote
	- Essentially what is used to fork new apps. Contains preloaded system libs, often used to talk
	to the system server-stuff over Binder.

## Example - Call to a System Server Service:
app code <--> zygote code <--> binder (kernel space in /dev/binder) <--> service code + zygote (will check ACL)

## Build Process
- Controlled by Gradle. A similar build system akin to Make/CMake/Ninja
- Typically done through Android Studio for ease of use.
- Can include compiler plugins (i.e. Jetpack Compose)
- Code is compiled to .classes (kotlinc, javac, etc) 
- Code is Dexed using D8 (previously dx), an IL known as "Dalvik Executable Format"
- Optional R8 minifier/inlining/lambda-groups

- Binary-pack AndroidManifest.xml and resources.asrc 
	- Describes activities, permissions, name and other app information to run.
	- Resources.asrc contains layout, string xml resources

- Packaged into a signed zip file known as APK 

## Code Specifics
- Mainly RE the compiled .dex files (Dalvik bytecode format) but can be converted back to .class/SMALI
- Java uses a stack-based vm 
- Dalvik uses a register-based vm

## Common Evasion Techniques
- Data encoding (base64):
	common signature:
```
		android.util.Base64() or minified json format
```

- Encryption (AES, DES, XOR(custom), XTEA(custom), ROR)
	common signature (AES): 
```
		.getInstance("..."), 
		.generateKey(), 
		.doFinal(...)
```

- Reflection (reference java class/method by string name)
	common signature: 
```
		.java.lang.reflect(...)
		.java.lang.Class(...)
```

- JNI/NDK (Call native code from Java)
	common signature:
```
		.registerNatives(...)
```

- Dynamic Code Loading (DCL) over C2 traffic
	common signature:
```
		.newInstance of a ClassLoader
```

- Packing - Similar to DCL but embeded into the app's code
- Execution Guardrail Techniques (similar to sandbox detection in Windows)
	- Locale 
	- SIM Info
	- Geo IP Cloaking
	- Time Delay
	- Device Arch Detection (x86 is a common emulator arch)
	- Device Model Detection
	- Anti-Frida
	- Anti-Root

## Analysis and Detection for Common Methods
```
Encoding: 			android.util.Base64 						-> hook .decode(...)
Encryption: 		javax.crypto.cipher 						-> hook .doFinal(...)
Reflection: 		java.lang.reflect/class 					-> hook .newInstance(...), .forName(...)
Native CE: 			JNI Exports 								-> hook .registerNatives(...)
Dynamic Loading: 	DCL, (Dex|Path)ClassLoader 					-> hook .newInstance of ClassLoader
SIM Info Detect: 	TelephonyManager READ_PHONE_STATE 			-> hook .getCountryNetworkIso 
```

## Common Tools
static: JADX, Cyberchef, Python (Kotlin for Android APIs), AVD/Android Studio, Text and Hex Editors

dynamic: mitmproxy, burp buite, httpToolkit, rooted devices as production builds(KernelSU), Frida, IDA Pro, VirusTotal, YARA/SNORT rules

## Key Notes
- Avoiding diving "deep" immediately, instead go "wide" and look for common techniques/signatures (Low Hanging Fruit)

## Check out 
- LaurieWeird
- Android Malware Handbook
- developer.android.com (Documentation)
- cs.android.com (AOSP)






