part of dart_updater;

Future<String> getLastVersionAndRevisionInfo(String channel) async {
	//  Get the json info on the last version
	//  https://storage.googleapis.com/dart-archive/channels/dev/release/latest/VERSION
	Completer completer = new Completer();
	String url_json = "https://storage.googleapis.com/dart-archive/channels/$channel/release/latest/VERSION";
	HttpClient hc = new HttpClient();
	HttpClientRequest hcreq = await hc.getUrl(Uri.parse(url_json));
	HttpClientResponse hcres = await hcreq.close();
	List<int> alldata = <int>[];
	hcres.listen((List<int> data) {
		alldata.addAll(data);
	}, onDone: () {
		completer.complete(JSON.decode(new String.fromCharCodes(alldata)));
	});
	return completer.future;
}

Future<File> downloadPackage(String url, String file_name) async {
	Completer completer = new Completer();
	String download_location = getDownloadPath();
	if (download_location == null) {
		completer.completeError("fail get download location");
	}
	stdout.write("Downloading...\n");
	HttpClient hc = new HttpClient();
	HttpClientRequest hcreq = await hc.getUrl(Uri.parse(url));
	HttpClientResponse hcres = await hcreq.close();
	File download_file = new File(download_location + Platform.pathSeparator + file_name);
	if (!download_file.existsSync()) {
		download_file.createSync();
	} else {
		download_file.writeAsString("");
	}
	int size = int.parse(hcres.headers[HttpHeaders.CONTENT_LENGTH][0], onError: (e) => -1);
	if (size == -1) {
		completer.completeError("int.parse failed");
	}
	int actual_size = 0;
	int pour = actual_size * 100 ~/ size;
	stdout.write("$pour%\n");
	hcres.listen((List<int> data) {
		actual_size += data.length;
		int old_pour = pour;
		pour = actual_size * 100 ~/ size;
		if (old_pour != pour) {
			stdout.write("$pour%\n");
		}
		download_file.writeAsBytesSync(data, mode: FileMode.APPEND);
	}, onDone: () {
		stdout.write("Download finish\n");
		completer.complete(download_file);
	});
	return completer.future;
}