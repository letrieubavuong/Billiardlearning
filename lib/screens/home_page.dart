import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../data/note_repository.dart';
import '../models/note_model.dart';
import 'co_ban_page.dart';
import 'bo_so_page.dart';
import 'gom_bi_page.dart';
import 'ghi_chu_page.dart';
import 'note_editor_page.dart';
import 'diagram_builder_page.dart';
import 'shot_detail_builder_page.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../widgets/youtube_player_widget.dart';
import '../models/theme_manager.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, this.repository = const SqliteNoteRepository()});

  final NoteRepository repository;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  final GlobalKey<CoBanPageState> _coBanKey = GlobalKey<CoBanPageState>();
  final GlobalKey<BoSoPageState> _boSoKey = GlobalKey<BoSoPageState>();
  final GlobalKey<GomBiPageState> _gomBiKey = GlobalKey<GomBiPageState>();
  final GlobalKey<GhiChuPageState> _ghiChuKey = GlobalKey<GhiChuPageState>();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      CoBanPage(key: _coBanKey, repository: widget.repository),
      BoSoPage(key: _boSoKey, repository: widget.repository),
      GomBiPage(key: _gomBiKey, repository: widget.repository),
      GhiChuPage(key: _ghiChuKey, repository: widget.repository),
    ];
  }

  static const List<String> _titles = <String>[
    'Kỹ thuật cơ bản',
    'Hệ thống bộ số',
    'Kỹ thuật gom bi',
    'Sổ tay ghi chú',
  ];

  static const List<Color> _appBarColors = [
    Colors.black12,
    Colors.black12,
    Colors.black12,
    Colors.black12,
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showQuickActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[950],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'TẠO MỚI NHANH',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 15),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.cyan,
                  child: Icon(Icons.add, color: Colors.white),
                ),
                title: const Text(
                  'Thêm bộ số cá nhân',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Tạo bài viết ghi chú bida tùy chỉnh của riêng bạn',
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NoteEditorPage(),
                    ),
                  );
                  if (result != null && result is Note) {
                    setState(() {
                      _selectedIndex = 1; // Chuyển sang tab Bộ số
                    });
                    _boSoKey.currentState?.addNewSystemWithNote(result);
                  }
                },
              ),
              const Divider(color: Colors.white12),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.sports_esports, color: Colors.white),
                ),
                title: const Text(
                  'Tạo thế bi nhanh',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Phác thảo sơ đồ vị trí bóng trên bàn bida',
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DiagramBuilderPage(),
                    ),
                  );
                },
              ),
              const Divider(color: Colors.white12),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.orange,
                  child: Icon(Icons.track_changes, color: Colors.white),
                ),
                title: const Text(
                  'Chi tiết cú đánh',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Mô phỏng mặt bi chạm, độ dày và hướng ép-phê',
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ShotDetailBuilderPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _onFabPressed() {
    switch (_selectedIndex) {
      case 0:
        _coBanKey.currentState?.addNewNote();
        break;
      case 1:
        _boSoKey.currentState?.addNewSystem();
        break;
      case 2:
        _gomBiKey.currentState?.addNewNote();
        break;
      case 3:
        _ghiChuKey.currentState?.addNewNote();
        break;
    }
  }

  Widget _buildTabItem(
    int index,
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
  ) {
    final bool isSelected = _selectedIndex == index;
    final activeTheme = ThemeManager.currentTheme.value;
    final Color color = isSelected
        ? activeTheme.accentColor
        : Theme.of(context).colorScheme.onSurface.withOpacity(0.5);
    return Expanded(
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () => _onItemTapped(index),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? activeIcon : inactiveIcon,
                color: color,
                size: 24,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _backupDatabase() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (!mounted) return;
      if (selectedDirectory != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final targetPath =
            "$selectedDirectory/libre_billiard_backup_$timestamp.db";
        await widget.repository.backup(targetPath);
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(content: Text('Sao lưu thành công tại:\n$targetPath')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Lỗi sao lưu: $e')));
    }
  }

  Future<void> _restoreDatabase() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['db'],
      );
      if (!mounted) return;
      if (result != null && result.files.single.path != null) {
        final sourcePath = result.files.single.path!;

        final confirm = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Khôi phục cơ sở dữ liệu'),
            content: const Text(
              'Tất cả dữ liệu hiện tại sẽ bị đè bằng dữ liệu sao lưu này. Bạn có muốn tiếp tục không?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text(
                  'Khôi phục',
                  style: TextStyle(color: Colors.orangeAccent),
                ),
              ),
            ],
          ),
        );
        if (!mounted) return;

        if (confirm == true) {
          await widget.repository.restore(sourcePath);
          if (!mounted) return;
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Khôi phục cơ sở dữ liệu thành công!'),
            ),
          );
          // Reload all pages
          _coBanKey.currentState?.loadUserNotes();
          _boSoKey.currentState?.loadUserSystems();
          _gomBiKey.currentState?.loadUserNotes();
          _ghiChuKey.currentState?.loadNotes();
        }
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Lỗi khôi phục: $e')));
    }
  }

  void _showResetConfirmationDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đặt lại mặc định'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa tất cả thay đổi và khôi phục toàn bộ bài viết mẫu ban đầu không? Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final messenger = ScaffoldMessenger.of(context);

              try {
                await widget.repository.resetAllDefaults();
                if (!mounted) return;

                // Reload all pages
                _coBanKey.currentState?.loadUserNotes();
                _boSoKey.currentState?.loadUserSystems();
                _gomBiKey.currentState?.loadUserNotes();
                _ghiChuKey.currentState?.loadNotes();

                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Đã đặt lại dữ liệu mẫu thành công!'),
                  ),
                );
              } catch (_) {
                if (!mounted) return;
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Không thể đặt lại dữ liệu. Không có dữ liệu nào bị thay đổi.',
                    ),
                  ),
                );
              }
            },
            child: const Text(
              'Đặt lại',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutAppDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Image.asset(
              'assets/images/billiard_icon.png',
              width: 32,
              height: 32,
            ),
            const SizedBox(width: 10),
            const Text('Billiard Libre'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ứng dụng hướng dẫn kỹ thuật bida Libre và ghi chú chuyên nghiệp.',
            ),
            SizedBox(height: 10),
            Text(
              'Phiên bản: 2.0.0',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Phát triển bởi: LÊ TRIỆU BÁ VƯƠNG'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showThemeSelectionDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return ValueListenableBuilder<BilliardTheme>(
          valueListenable: ThemeManager.currentTheme,
          builder: (context, activeTheme, child) {
            return AlertDialog(
              backgroundColor: activeTheme.backgroundColor,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Thay đổi giao diện',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: ThemeManager.themes.map((theme) {
                    final bool isSelected = activeTheme.id == theme.id;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? theme.accentColor
                              : Colors.white10,
                          width: isSelected ? 2.0 : 1.0,
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.primaryColor,
                          radius: 12,
                        ),
                        title: Text(
                          theme.name,
                          style: TextStyle(
                            color: theme.brightness == Brightness.dark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle, color: theme.accentColor)
                            : null,
                        onTap: () {
                          ThemeManager.setTheme(theme);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    'Đóng',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color currentColor = _appBarColors[_selectedIndex];

    return ValueListenableBuilder<YoutubePlayerController?>(
      valueListenable: FullScreenPlayerManager.activeController,
      builder: (context, activeController, child) {
        return Stack(
          children: [
            Scaffold(
              appBar: AppBar(
                flexibleSpace: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [currentColor.withOpacity(0.8), currentColor],
                    ),
                  ),
                ),
                title: Text(
                  _titles[_selectedIndex],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Colors.white,
                  ),
                ),
                centerTitle: true,
                elevation: 10,
                shadowColor: currentColor.withOpacity(0.5),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                ),
              ),
              drawer: Drawer(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    DrawerHeader(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.cyan.withOpacity(0.8),
                            Colors.blueGrey[900]!,
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white,
                            backgroundImage: const AssetImage(
                              'assets/images/billiard_icon.png',
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Billiard Libre',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const Text(
                            'Phiên bản 2.0.0',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'QUẢN LÝ DỮ LIỆU',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.backup,
                        color: Colors.cyanAccent,
                      ),
                      title: const Text('Sao lưu dữ liệu'),
                      subtitle: const Text(
                        'Lưu trữ cấu hình và ghi chú cá nhân',
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _backupDatabase();
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.restore,
                        color: Colors.orangeAccent,
                      ),
                      title: const Text('Khôi phục dữ liệu'),
                      subtitle: const Text('Khôi phục từ tệp sao lưu đã chọn'),
                      onTap: () {
                        Navigator.pop(context);
                        _restoreDatabase();
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.refresh,
                        color: Colors.redAccent,
                      ),
                      title: const Text('Đặt lại mặc định'),
                      subtitle: const Text(
                        'Xóa thay đổi, tải lại bài viết mẫu',
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _showResetConfirmationDialog();
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.palette,
                        color: Colors.purpleAccent,
                      ),
                      title: const Text('Giao diện & Chủ đề'),
                      subtitle: const Text(
                        'Thay đổi chủ đề màu sắc của ứng dụng',
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _showThemeSelectionDialog();
                      },
                    ),
                    const Divider(color: Colors.white10),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Text(
                        'THÔNG TIN',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.info_outline,
                        color: Colors.blueAccent,
                      ),
                      title: const Text('Thông tin ứng dụng'),
                      onTap: () {
                        Navigator.pop(context);
                        _showAboutAppDialog();
                      },
                    ),
                  ],
                ),
              ),
              body: _pages[_selectedIndex],
              bottomNavigationBar: SafeArea(
                top: false,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  height: 64,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(
                          Theme.of(context).brightness == Brightness.dark
                              ? 0.4
                              : 0.1,
                        ),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.08),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildTabItem(0, Icons.star, Icons.star_border, 'Cơ bản'),
                      _buildTabItem(
                        1,
                        Icons.calculate,
                        Icons.calculate_outlined,
                        'Bộ số',
                      ),

                      // Integrated Add Button (Clean, space-saving, and premium)
                      GestureDetector(
                        onTap: _onFabPressed,
                        onLongPress: () => _showQuickActionMenu(context),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.cyanAccent, Colors.blueAccent],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.cyanAccent.withOpacity(0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),

                      _buildTabItem(2, Icons.api, Icons.api_outlined, 'Gom bi'),
                      _buildTabItem(
                        3,
                        Icons.note_alt,
                        Icons.note_alt_outlined,
                        'Ghi chú',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (activeController != null)
              Positioned.fill(
                child: Container(
                  color: Colors.black,
                  child: YoutubePlayerBuilder(
                    onExitFullScreen: () {
                      SystemChrome.setPreferredOrientations(
                        DeviceOrientation.values,
                      );
                    },
                    player: YoutubePlayer(
                      key: ObjectKey(activeController),
                      controller: activeController,
                      showVideoProgressIndicator: true,
                      progressIndicatorColor: Colors.cyanAccent,
                      progressColors: const ProgressBarColors(
                        playedColor: Colors.cyanAccent,
                        handleColor: Colors.cyanAccent,
                      ),
                    ),
                    builder: (context, player) {
                      return Center(child: player);
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
