import 'dart:io';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';
import 'utils.dart';
import 'constants.dart';

class Configuration {
  String msixAssetsPath = '';
  String appName;
  String publisherName;
  String identityName;
  String msixVersion = '1.0.0.0';
  String appDescription;
  String certificateSubject;
  String buildFilesFolder =
      '${Directory.current.path}/build/windows/runner/Release';
  String certificatePath;
  String certificatePassword;
  String displayName;
  String architecture = 'x64';
  String logoPath;
  String startMenuIconPath;
  String tileIconPath;
  String iconsBackgroundColor = '#ffffff';
  bool isUsingTestCertificate = false;
  String defaultsIconsFolderPath() => '$msixAssetsPath/icons';
  String vcLibsFolderPath() => '$msixAssetsPath/VCLibs';
  String msixToolkitPath() => '$msixAssetsPath/MSIX-Toolkit';

  Future<void> getConfigValues() async {
    stdout.write(white('getting config values..    '));

    await _getAssetsFolderPath();

    var pubspec = await _getPubspec();

    appName = pubspec['name'].toString();
    appDescription = pubspec['description'].toString();
    if (!isNullOrStringNull(pubspec['msix_config'].toString())) {
      displayName = pubspec['msix_config']['display_name'].toString();
      publisherName = pubspec['msix_config']['publisher_name'].toString();
      identityName = pubspec['msix_config']['identity_name'].toString();
      msixVersion = pubspec['msix_config']['msix_version'].toString();
      certificateSubject =
          pubspec['msix_config']['certificate_subject'].toString();
      certificatePath = pubspec['msix_config']['certificate_path'].toString();
      certificatePassword =
          pubspec['msix_config']['certificate_password'].toString();
      logoPath = pubspec['msix_config']['logo_path'].toString();
      startMenuIconPath =
          pubspec['msix_config']['start_menu_icon_path'].toString();
      tileIconPath = pubspec['msix_config']['tile_icon_path'].toString();
      iconsBackgroundColor =
          pubspec['msix_config']['icons_background_color'].toString();
      architecture = pubspec['msix_config']['architecture'].toString();
    }
    print(green('done!'));
  }

  /// Get the assets folder path from the .packages file
  Future<void> _getAssetsFolderPath() async {
    List<String> packages =
        (await File('${Directory.current.path}/.packages').readAsString())
            .split('\n');

    msixAssetsPath = packages
            .firstWhere((package) => package.contains('msix:'))
            .replaceAll('msix:', '')
            .replaceAll('file:///', '') +
        'assets';
  }

  /// Get pubspec.yaml content
  dynamic _getPubspec() async {
    var pubspecFile = File("pubspec.yaml");
    var pubspecString = await pubspecFile.readAsString();
    var pubspec = loadYaml(pubspecString);
    return pubspec;
  }

  /// Validate the configuration values and set default values
  Future<void> validateConfigValues() async {
    stdout.write(white('validate config values..    '));

    if (isNullOrStringNull(appName))
      throw (red('App name is empty, check \'appName\' at pubspec.yaml'));

    if (isNullOrStringNull(appDescription)) appDescription = appName;
    if (isNullOrStringNull(displayName)) displayName = appName;
    if (isNullOrStringNull(identityName)) identityName = 'com.flutter.$appName';
    if (isNullOrStringNull(publisherName)) publisherName = identityName;

    if (!await Directory(buildFilesFolder).exists())
      throw (red(
          'Build files not found as $buildFilesFolder, first run "flutter build windows" then try again'));

    if (!RegExp(r'^(\*|\d+(\.\d+){3,3}(\.\*)?)$').hasMatch(msixVersion))
      throw (red('Msix version can be only in this format: "1.0.0.0"'));

    /// If no certificate was chosen then use test certificate
    if (isNullOrStringNull(certificatePath)) {
      print('');
      print(white('No certificate was specified, using test certificate'));
      certificatePath = '$msixAssetsPath/test_certificate.pfx';
      certificatePassword = '1234';
      certificateSubject = defaultCertificateSubject;
      isUsingTestCertificate = true;
    } else if (!await File(certificatePath).exists())
      throw (red(
          'The file certificate not found in: $certificatePath, check "msix_config: certificate_path" at pubspec.yaml'));
    else if (isNullOrStringNull(certificateSubject)) {
      print(red(
          'Certificate subject is empty, check "msix_config: certificate_subject" at pubspec.yaml'));
      print(yellow('see what certificate-subject value is:'));
      print(yellow(
          'https://drive.google.com/file/d/1oAsnrp2Kf-jZ_kaRjyF5llQ0YZy1IwNe/view?usp=sharing'));
      exit(0);
    } else if (extension(certificatePath) == '.pfx' &&
        isNullOrStringNull(certificatePassword))
      throw (red(
          'Certificate password is empty, check "msix_config: certificate_password" at pubspec.yaml'));

    if (!['x86', 'x64'].contains(architecture))
      throw (red(
          'Architecture can be "x86" or "x64", check "msix_config: architecture" at pubspec.yaml'));

    if (!iconsBackgroundColor.contains('#'))
      iconsBackgroundColor = '#$iconsBackgroundColor';
    if (!RegExp(r'^#(?:[0-9a-fA-F]{3}){1,2}$').hasMatch(iconsBackgroundColor))
      throw (red(
          'Icons background color can be only in this format: "#ffffff"'));

    print(green('done!'));
  }
}