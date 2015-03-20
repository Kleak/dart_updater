// Copyright (c) 2015, Kevin Segaud. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:convert';
import 'dart:async';

import 'package:args/args.dart';
import 'package:archive/archive.dart';
import 'package:Updater/Updater.dart';

main(List<String> args) async {
	List<String> allowed_update = ["editor", "sdk", "dartium", "all"];
	List<String> allowed_channel = ["stable", "dev"];
	Map<String, String> allowed_update_help = <String, String>{};
	allowed_update_help["all"] = "Update all the dart package (Editor, Sdk, Dartium)";
	allowed_update_help["editor"] = "Same as all";
	allowed_update_help["sdk"] = "Update the dart sdk";
	allowed_update_help["dartium"] = "Update Dartium";
	Map<String, String> allowed_channel_help = <String, String>{};
	allowed_channel_help["stable"] = "use the stable channel";
	allowed_channel_help["dev"] = "use the dev channel";

	ArgParser parser = new ArgParser();
	parser
		..addOption("update", abbr: "u", defaultsTo: "all", allowed: allowed_update, help: "What you want to update (default all)", allowedHelp: allowed_update_help)
		..addOption("channel", abbr: "c", defaultsTo: "stable", allowed: allowed_channel, help: "Set the channel (default stable)", allowedHelp: allowed_channel_help);

	try {
		ArgResults result = parser.parse(args);

		if (!Platform.environment.containsKey("DARTSDK")) {
			stdout.write("Please add the path of your dart sdk inside your env variable.");
			return;
		}

		//  https://storage.googleapis.com/dart-archive/channels/stable/release/latest/editor/darteditor-windows-x64.zip
		//  https://storage.googleapis.com/dart-archive/channels/stable/release/latest/sdk/dartsdk-windows-x64-release.zip
		//  https://storage.googleapis.com/dart-archive/channels/stable/release/latest/dartium/dartium-windows-ia32-release.zip
		String url = "https://storage.googleapis.com/dart-archive/channels/";
		if (result["channel"] == "stable") {
			url += "stable/";
		} else if (result["channel"] == "dev") {
			url += "dev/";
		}
		url += "release/latest/";
		String system = getSystem();
		if (system == null) {
			stderr.write("Your platform is not supported.");
			return;
		}
		String archi = getArchitecture();
		if (system == null) {
			stderr.write("Your architecture is not supported.");
			return;
		}
		String file_name = null;
		List<String> path_dir_list = Platform.environment["DARTSDK"].split(Platform.pathSeparator);
		if (path_dir_list.length < 5) {
			stderr.write("Directory not found, DARTSDK path is: $path_dir_list");
			return;
		}
		String path_out = null;
		if (result["update"] == "editor" || result["update"] == "all") {
			file_name = "darteditor-" + system + "-" + archi + ".zip";
			url += "editor/" + file_name;
			path_dir_list.removeAt(path_dir_list.length - 2);
			path_dir_list.removeAt(path_dir_list.length - 2);
			path_dir_list.removeAt(path_dir_list.length - 2);
			path_out = path_dir_list.join(Platform.pathSeparator);
		} else if (result["update"] == "dartium") {
			url += "dartium/dartium-" + system + "-" + archi + "-release.zip";
			stdout.write("Sorry but for the momment we are nto able to update dartium only.");
		} else if (result["update"] == "sdk") {
			url += "sdk/dartsdk-" + system + "-" + archi + "-release.zip";
			path_dir_list.removeAt(path_dir_list.length - 2);
			path_dir_list.removeAt(path_dir_list.length - 2);
			path_out = path_dir_list.join(Platform.pathSeparator);
		} else {
			print(parser.usage);
			return;
		}

		Map json = await getLastVersionAndRevisionInfo(result["channel"]);
		int last_revision = int.parse(json["revision"], onError: (e) => -1);

		String parent_directory = ".." + Platform.pathSeparator;
		File version_file = new File(Platform.environment["DARTSDK"] + parent_directory + "version");
		File revision_file = new File(Platform.environment["DARTSDK"] + parent_directory + "revision");

		if (!version_file.existsSync() && !revision_file.existsSync()) {
			stderr.write("Version or Revision file is missing.");
			return;
		}

		String last_version = json["version"].split("-")[0];
		List<String> last_version_list = last_version.split(".");
		int last_major = int.parse(last_version_list[0], onError: (e) => -1);
		int last_minor = int.parse(last_version_list[1], onError: (e) => -1);
		int last_build = int.parse(last_version_list[2], onError: (e) => -1);

		String your_version = version_file.readAsLinesSync()[0];
		your_version = your_version.split("-")[0];
		List<String> your_version_list = your_version.split(".");
		int your_major = int.parse(your_version_list[0], onError: (e) => -1);
		int your_minor = int.parse(your_version_list[1], onError: (e) => -1);
		int your_build = int.parse(your_version_list[2], onError: (e) => -1);

		if (your_major == -1 || your_minor == -1 || your_build == -1) {
			stderr.write("Version is not correct.");
			return;
		}

		int your_revision = int.parse(revision_file.readAsLinesSync()[0], onError: (e) => -1);

		if ((last_major <= your_major && last_minor <= your_minor && last_build <= your_build)
					&& last_revision <= your_revision) {
			stdout.write("Your version is up-to-date.");
			return;
		}

		File zipper_file = await downloadPackage(url, file_name);
		String download_location = getDownloadPath();
		unZip(zipper_file, download_location);
		stdout.write("Update finish, enjoy !");
	} on FormatException catch (e) {
		print(parser.usage);
		return;
	} catch(e) {
		print(e);
	}
}
