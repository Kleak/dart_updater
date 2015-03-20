part of dart_updater;

void unZip(File file, String out_path) {
	stdout.write("Starting unzip...\n");
	List<int> bytes = file.readAsBytesSync();
	Archive archive = new ZipDecoder().decodeBytes(bytes);
	int total_file = archive.length;
	int actual_file = 0;
	for (ArchiveFile file in archive) {
		String filename = file.name;
		filename = filename.replaceAll("/", Platform.pathSeparator);
		List<int> data = file.content;

		actual_file++;
		if (!filename.endsWith(Platform.pathSeparator)) {
			new File(out_path + filename)
				..createSync(recursive: true)
				..writeAsBytesSync(data);
		}
		stdout.write("$actual_file/$total_file\n");
	}
	stdout.write("unzip finish\n");
}
