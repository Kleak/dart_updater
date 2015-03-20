part of Updater;

String getSystem() {
	if (Platform.isWindows) return "windows";
	if (Platform.isLinux) return "linux";
	if (Platform.isMacOS) return "macos";
	return null;
}

String getArchitecture() {
	if (Platform.version.contains("x64")) {
		return "x64";
	} else {
		return "ia32";
	}
	return null;
}

String getDownloadPath() {
	if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
		return Platform.environment["HOMEDRIVE"] + Platform.environment["HOMEPATH"] + Platform.pathSeparator + "Downloads" + Platform.pathSeparator;
	}
	return null;
}