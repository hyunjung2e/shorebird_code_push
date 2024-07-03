import 'package:fimber/fimber.dart';
import 'package:flutter/material.dart';
import 'package:restart_app/restart_app.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

final _shorebirdCodePush = ShorebirdCodePush();

Future<void> main() async {
  Fimber.plantTree(DebugTree());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shorebird',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.yellow), useMaterial3: true),
      home: const MyHomePage(title: 'Shorebird 코드 푸시 테스트'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({required this.title, super.key});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _isShorebirdAvailable = _shorebirdCodePush.isShorebirdAvailable();
  int? _currentPatchVersion;
  bool _isCheckingForUpdate = false;

  @override
  void initState() {
    super.initState();
    _shorebirdCodePush.currentPatchNumber().then((currentPatchVersion) {
      if (!mounted) return;
      setState(() => _currentPatchVersion = currentPatchVersion);
    });
  }

  Future<void> _checkForUpdate() async {
    setState(() => _isCheckingForUpdate = true);
    final isUpdateAvailable = await _shorebirdCodePush.isNewPatchAvailableForDownload();
    if (!mounted) return;
    setState(() => _isCheckingForUpdate = false);

    if (isUpdateAvailable) {
      _showUpdateAvailableBanner();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('최신 버전입니다.')));
    }
  }

  void _showDownloadingBanner() {
    ScaffoldMessenger.of(context).showMaterialBanner(
      const MaterialBanner(
        content: Text('다운로드 중..'),
        actions: [
          SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2)),
        ],
      ),
    );
  }

  void _showUpdateAvailableBanner() {
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        content: const Text('업데이트가 필요합니다.'),
        actions: [
          TextButton(
            onPressed: () async {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
              await _downloadUpdate();
              if (!mounted) return;
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
            },
            child: const Text('다운로드'),
          ),
        ],
      ),
    );
  }

  void _showRestartBanner() {
    ScaffoldMessenger.of(context).showMaterialBanner(
      const MaterialBanner(
        content: Text('패치가 완료되었습니다.'),
        actions: [
          TextButton(
            // Restart the app for the new patch to take effect.
            onPressed: Restart.restartApp,
            child: Text('앱 재시작'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadUpdate() async {
    _showDownloadingBanner();

    await Future.wait([
      _shorebirdCodePush.downloadUpdateIfAvailable(),
      // Add an artificial delay so the banner has enough time to animate in.
      Future<void>.delayed(const Duration(milliseconds: 250)),
    ]);

    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
    _showRestartBanner();
  }

  @override
  Widget build(BuildContext context) {
    Fimber.d('_isShorebirdAvailable 여부는? $_isShorebirdAvailable'); // false
    Fimber.d('_currentPatchVersion 정보는? $_currentPatchVersion'); // null
    Fimber.d('_isCheckingForUpdate 여부는? $_isCheckingForUpdate'); // 업데이트 여부 체크중

    final theme = Theme.of(context);
    final heading = _currentPatchVersion != null ? '$_currentPatchVersion' : '설치된 버전이 없습니다.';
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('현재 패치 버전:'),
            Text(heading, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 20),
            if (!_isShorebirdAvailable) Text('Shorebird 엔진이 꺼진 상태입니다.', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.error)),
            if (_isShorebirdAvailable)
              ElevatedButton(
                onPressed: _isCheckingForUpdate ? null : _checkForUpdate,
                child: _isCheckingForUpdate ? const _LoadingIndicator() : const Text('업데이트 확인하기'),
              ),
          ],
        ),
      ),
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2));
  }
}
