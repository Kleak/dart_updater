// Copyright (c) 2015, Kevin Segaud. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

part of dart_updater;

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