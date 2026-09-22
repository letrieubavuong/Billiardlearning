import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note_model.dart';
import '../widgets/billiard_diagram.dart';
import '../widgets/shot_details.dart';
import '../widgets/article_blocks.dart';
import 'diagram_builder_page.dart';
import 'shot_detail_builder_page.dart';
import 'effet_diagram_builder_page.dart';
import '../data/note_document_codec.dart';
import '../models/note_draft.dart';
import '../models/image_block_data.dart';
import '../widgets/note_image_block.dart';

class _BlockEditorSnapshot {
  const _BlockEditorSnapshot(this.types, this.contents);

  final List<BlockType> types;
  final List<String> contents;
}

class NoteEditorPage extends StatefulWidget {
  final Note? note;
  const NoteEditorPage({super.key, this.note});

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  late TextEditingController _titleController;
  late TextEditingController _subtitleController;
  final List<TextEditingController> _blockControllers = [];
  final List<BlockType> _blockTypes = [];
  final List<Key> _blockKeys = [];
  Timer? _draftTimer;
  DateTime? _draftSavedAt;
  String? _lastDraftJson;
  bool _submitted = false;
  late DateTime _draftDate;
  late String _initialSignature;
  bool _historyEnabled = false;
  bool _lastKnownDirty = false;
  final List<_BlockEditorSnapshot> _undoHistory = [];
  final List<_BlockEditorSnapshot> _redoHistory = [];
  final Set<Key> _collapsedBlockKeys = {};

  TextEditingController _newBlockController(String text) {
    final controller = TextEditingController(text: text);
    controller.addListener(_handleEditorTextChanged);
    return controller;
  }

  void _handleEditorTextChanged() {
    if (!_historyEnabled || !mounted) return;
    final dirty = _hasUnsavedChanges;
    if (dirty != _lastKnownDirty) {
      setState(() => _lastKnownDirty = dirty);
    }
  }

  String get _draftKey => 'note_draft_${widget.note?.id ?? 'new'}';
  BlockType? _clipboardType;
  String? _clipboardContent;

  void _copyBlock(int index) {
    setState(() {
      _clipboardType = _blockTypes[index];
      _clipboardContent = _blockControllers[index].text;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép khối nội dung!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _pasteBlock(int afterIndex) {
    if (_clipboardType == null) return;
    _recordBlockHistory();
    setState(() {
      final insertIndex = afterIndex + 1;
      _blockControllers.insert(
        insertIndex,
        _newBlockController(_clipboardContent ?? ''),
      );
      _blockTypes.insert(insertIndex, _clipboardType!);
      _blockKeys.insert(insertIndex, UniqueKey());
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã dán khối nội dung!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  _BlockEditorSnapshot _takeBlockSnapshot() => _BlockEditorSnapshot(
    List<BlockType>.of(_blockTypes),
    _blockControllers.map((controller) => controller.text).toList(),
  );

  void _recordBlockHistory() {
    if (!_historyEnabled) return;
    _undoHistory.add(_takeBlockSnapshot());
    if (_undoHistory.length > 50) _undoHistory.removeAt(0);
    _redoHistory.clear();
  }

  void _restoreBlockSnapshot(_BlockEditorSnapshot snapshot) {
    for (final controller in _blockControllers) {
      controller.dispose();
    }
    _blockControllers
      ..clear()
      ..addAll(snapshot.contents.map(_newBlockController));
    _blockTypes
      ..clear()
      ..addAll(snapshot.types);
    _blockKeys
      ..clear()
      ..addAll(List.generate(snapshot.types.length, (_) => UniqueKey()));
    _collapsedBlockKeys.clear();
  }

  void _undoBlockAction() {
    if (_undoHistory.isEmpty) return;
    final target = _undoHistory.removeLast();
    _redoHistory.add(_takeBlockSnapshot());
    setState(() => _restoreBlockSnapshot(target));
  }

  void _redoBlockAction() {
    if (_redoHistory.isEmpty) return;
    final target = _redoHistory.removeLast();
    _undoHistory.add(_takeBlockSnapshot());
    setState(() => _restoreBlockSnapshot(target));
  }

  Future<String> _persistPickedImage(XFile image) async {
    final documents = await getApplicationDocumentsDirectory();
    final imageDirectory = Directory(path.join(documents.path, 'note_images'));
    await imageDirectory.create(recursive: true);
    var extension = path.extension(image.path).toLowerCase();
    if (extension.isEmpty || extension.length > 8) extension = '.jpg';
    final destination = path.join(
      imageDirectory.path,
      'note_${DateTime.now().microsecondsSinceEpoch}$extension',
    );
    return (await File(image.path).copy(destination)).path;
  }

  Future<void> _addPickedImage(XFile image) async {
    final persistedPath = await _persistPickedImage(image);
    if (!mounted) return;
    _addBlock(BlockType.image);
    final index = _blockControllers.length - 1;
    _blockControllers[index].text = ImageBlockData(
      source: persistedPath,
    ).encode();
    await _editImageBlock(index);
  }

  Future<void> _editImageBlock(int index) async {
    final initial = ImageBlockData.decode(_blockControllers[index].text);
    final sourceController = TextEditingController(text: initial.source);
    final captionController = TextEditingController(text: initial.caption);
    final altTextController = TextEditingController(text: initial.altText);
    var fit = initial.fit;

    final result = await showDialog<ImageBlockData>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Chỉnh sửa hình ảnh'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: sourceController,
                  decoration: _dialogInputDecoration(
                    'Nguồn ảnh',
                    hintText: 'Đường dẫn hoặc https://...',
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await ImagePicker().pickImage(
                      source: ImageSource.gallery,
                    );
                    if (picked == null) return;
                    final persistedPath = await _persistPickedImage(picked);
                    sourceController.text = persistedPath;
                    setDialogState(() {});
                  },
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Thay ảnh từ thiết bị'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: captionController,
                  decoration: _dialogInputDecoration(
                    'Chú thích',
                    hintText: 'Nội dung hiển thị dưới ảnh',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: altTextController,
                  decoration: _dialogInputDecoration(
                    'Mô tả hình ảnh',
                    hintText: 'Dùng cho trình đọc màn hình',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: fit,
                  decoration: _dialogInputDecoration('Cách hiển thị'),
                  items: const [
                    DropdownMenuItem(
                      value: 'contain',
                      child: Text('Hiện toàn bộ ảnh'),
                    ),
                    DropdownMenuItem(
                      value: 'cover',
                      child: Text('Lấp đầy khung'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setDialogState(() => fit = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                final source = sourceController.text.trim();
                if (source.isEmpty) return;
                Navigator.pop(
                  context,
                  ImageBlockData(
                    source: source,
                    caption: captionController.text.trim(),
                    altText: altTextController.text.trim(),
                    fit: fit,
                  ),
                );
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );

    sourceController.dispose();
    captionController.dispose();
    altTextController.dispose();
    if (result != null && mounted) {
      setState(() => _blockControllers[index].text = result.encode());
    }
  }

  void _editBlock(int index) async {
    final type = _blockTypes[index];
    if (type == BlockType.image) {
      await _editImageBlock(index);
    } else if (type == BlockType.diagram) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              DiagramBuilderPage(initialData: _blockControllers[index].text),
        ),
      );
      if (result != null) {
        setState(() {
          _blockControllers[index].text = result;
        });
      }
    } else if (type == BlockType.effetDiagram) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EffetDiagramBuilderPage(
            initialData: _blockControllers[index].text,
          ),
        ),
      );
      if (result != null) {
        setState(() {
          _blockControllers[index].text = result;
        });
      }
    } else if (type == BlockType.shotDetail) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ShotDetailBuilderPage(initialData: _blockControllers[index].text),
        ),
      );
      if (result != null) {
        setState(() {
          _blockControllers[index].text = result;
        });
      }
    } else if (type == BlockType.section) {
      _editSectionBlock(index);
    } else if (type == BlockType.subSection) {
      _editSubSectionBlock(index);
    } else if (type == BlockType.headingText) {
      _editHeadingTextBlock(index);
    } else if (type == BlockType.dataTable) {
      _editDataTableBlock(index);
    } else if (type == BlockType.iconText) {
      _editIconTextBlock(index);
    } else if (type == BlockType.animatedText) {
      _editAnimatedTextBlock(index);
    }
  }

  List<Widget> _buildBlockActionButtons(int index) {
    final type = _blockTypes[index];
    final isEditable = type != BlockType.text && type != BlockType.item;
    final List<Widget> buttons = [];

    // Delete button
    buttons.add(
      Positioned(
        top: 5,
        right: 5,
        child: CircleAvatar(
          radius: 18,
          backgroundColor: Colors.black54,
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
            onPressed: () => _removeBlock(index),
          ),
        ),
      ),
    );

    // Drag handle
    buttons.add(
      Positioned(
        top: 5,
        right: 45,
        child: CircleAvatar(
          radius: 18,
          backgroundColor: Colors.black54,
          child: ReorderableDragStartListener(
            index: index,
            child: const Icon(Icons.drag_handle, color: Colors.white, size: 20),
          ),
        ),
      ),
    );

    // Copy button
    buttons.add(
      Positioned(
        top: 5,
        right: 85,
        child: CircleAvatar(
          radius: 18,
          backgroundColor: Colors.black54,
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.copy, color: Colors.white, size: 16),
            onPressed: () => _copyBlock(index),
          ),
        ),
      ),
    );

    double nextRight = 125;

    // Edit button (if editable)
    if (isEditable) {
      buttons.add(
        Positioned(
          top: 5,
          right: nextRight,
          child: CircleAvatar(
            radius: 18,
            backgroundColor: Colors.black54,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.edit, color: Colors.white, size: 16),
              onPressed: () => _editBlock(index),
            ),
          ),
        ),
      );
      nextRight += 40;
    }

    buttons.add(
      Positioned(
        top: 5,
        right: nextRight,
        child: CircleAvatar(
          radius: 18,
          backgroundColor: Colors.black54,
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(
              _collapsedBlockKeys.contains(_blockKeys[index])
                  ? Icons.expand_more
                  : Icons.expand_less,
              color: Colors.white,
              size: 18,
            ),
            tooltip: _collapsedBlockKeys.contains(_blockKeys[index])
                ? 'Mở rộng khối'
                : 'Thu gọn khối',
            onPressed: () {
              setState(() {
                final key = _blockKeys[index];
                if (!_collapsedBlockKeys.add(key)) {
                  _collapsedBlockKeys.remove(key);
                }
              });
            },
          ),
        ),
      ),
    );
    nextRight += 40;

    // Paste button (if clipboard is not empty)
    if (_clipboardType != null) {
      buttons.add(
        Positioned(
          top: 5,
          right: nextRight,
          child: CircleAvatar(
            radius: 18,
            backgroundColor: Colors.black54,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.paste, color: Colors.white, size: 16),
              onPressed: () => _pasteBlock(index),
            ),
          ),
        ),
      );
    }

    return buttons;
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _draftDate = widget.note?.date ?? DateTime.now();
    _subtitleController = TextEditingController(
      text: widget.note?.subtitle ?? '',
    );
    _titleController.addListener(_handleEditorTextChanged);
    _subtitleController.addListener(_handleEditorTextChanged);

    if (widget.note != null) {
      for (var block in widget.note!.blocks) {
        _blockControllers.add(_newBlockController(block.content));
        _blockTypes.add(block.type);
        _blockKeys.add(UniqueKey());
      }
    } else {
      // Mặc định có 1 block văn bản đầu tiên
      _addBlock(BlockType.text);
    }
    _initialSignature = _editorSignature();
    _lastKnownDirty = false;
    _historyEnabled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _offerDraftRestore());
    _draftTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _saveDraft(),
    );
  }

  Future<void> _offerDraftRestore() async {
    final prefs = await SharedPreferences.getInstance();
    final source = prefs.getString(_draftKey);
    if (!mounted || source == null || source.isEmpty) return;
    try {
      final draftNote = NoteDocumentCodec.decode(source);
      if (NoteDocumentCodec.encode(_currentDraft().toNote()) == source) return;
      final restore = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Khôi phục bản nháp?'),
          content: const Text(
            'Ứng dụng tìm thấy nội dung được tự động lưu trước đó.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Bỏ qua'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Khôi phục'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (restore == true) {
        _replaceEditorContent(draftNote);
        _lastDraftJson = source;
      } else {
        await prefs.remove(_draftKey);
      }
    } catch (_) {
      await prefs.remove(_draftKey);
    }
  }

  void _replaceEditorContent(Note note) {
    _recordBlockHistory();
    setState(() {
      _draftDate = note.date;
      _titleController.text = note.title;
      _subtitleController.text = note.subtitle;
      for (final controller in _blockControllers) {
        controller.dispose();
      }
      _blockControllers.clear();
      _blockTypes.clear();
      _blockKeys.clear();
      for (final block in note.blocks) {
        _blockControllers.add(_newBlockController(block.content));
        _blockTypes.add(block.type);
        _blockKeys.add(UniqueKey());
      }
    });
  }

  Future<void> _saveDraft() async {
    if (!mounted || _submitted) return;
    final draft = _currentDraft();
    if (draft.isEmpty) return;
    final source = NoteDocumentCodec.encode(draft.toNote());
    if (source == _lastDraftJson) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_draftKey, source);
    _lastDraftJson = source;
    if (!mounted) return;
    setState(() => _draftSavedAt = DateTime.now());
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
    _lastDraftJson = null;
  }

  void _addBlock(BlockType type, [String content = '']) {
    _recordBlockHistory();
    String initialContent = content;
    if (type == BlockType.item && content.isEmpty) {
      initialContent = '• ';
    }
    setState(() {
      _blockControllers.add(_newBlockController(initialContent));
      _blockTypes.add(type);
      _blockKeys.add(UniqueKey());
    });
  }

  void _removeBlock(int index) {
    _recordBlockHistory();
    setState(() {
      _blockControllers[index].dispose();
      _blockControllers.removeAt(index);
      _blockTypes.removeAt(index);
      _blockKeys.removeAt(index);
    });
  }

  // --- CÁC HÀM DIALOG TƯƠNG TÁC CHO CÁC KHỐI NÂNG CAO ---

  InputDecoration _dialogInputDecoration(String labelText, {String? hintText}) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      hintStyle: TextStyle(color: onSurface.withOpacity(0.3), fontSize: 13),
      filled: true,
      fillColor: onSurface.withOpacity(0.04),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: onSurface.withOpacity(0.08), width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.cyanAccent, width: 1.5),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void _editAnimatedTextBlock(int? index) {
    Map<String, dynamic> data = {};
    if (index != null && _blockControllers[index].text.isNotEmpty) {
      final content = _blockControllers[index].text;
      if (content.startsWith('{') && content.endsWith('}')) {
        try {
          data = jsonDecode(content);
        } catch (_) {}
      } else {
        data = {'text': content};
      }
    }

    final textController = TextEditingController(text: data['text'] ?? '');
    String selectedType = data['type'] ?? 'marquee';
    int selectedColorVal = data['colorVal'] ?? Colors.cyanAccent.value;
    double selectedFontSize = (data['fontSize'] as num?)?.toDouble() ?? 16.0;
    double selectedSpeed = (data['speed'] as num?)?.toDouble() ?? 1.0;

    final List<Map<String, dynamic>> colors = [
      {'name': 'Cyan (Xanh ngọc)', 'color': Colors.cyanAccent},
      {'name': 'Orange (Cam)', 'color': Colors.orangeAccent},
      {'name': 'Yellow (Vàng)', 'color': Colors.yellowAccent},
      {'name': 'Green (Xanh lá)', 'color': Colors.greenAccent},
      {'name': 'Pink (Hồng)', 'color': Colors.pinkAccent},
      {'name': 'Blue (Xanh dương)', 'color': Colors.blueAccent},
      {'name': 'Red (Đỏ)', 'color': Colors.redAccent},
      {'name': 'Purple (Tím)', 'color': Colors.purpleAccent},
      {'name': 'White (Trắng)', 'color': Colors.white},
    ];

    final List<Map<String, String>> animTypes = [
      {'value': 'marquee', 'name': 'Chữ chạy ngang (Marquee)'},
      {'value': 'typewriter', 'name': 'Đánh máy tự động (Typewriter)'},
      {'value': 'fade', 'name': 'Mờ tỏ nhịp điệu (Fade Pulse)'},
      {'value': 'scale', 'name': 'Phóng to thu nhỏ (Scale Pulse)'},
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).dialogBackgroundColor,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            index == null ? 'Thêm chữ chuyển động' : 'Sửa chữ chuyển động',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: textController,
                    decoration: _dialogInputDecoration(
                      'Nội dung hiển thị',
                      hintText: 'VD: Góc này cần đẩy lực trung bình...',
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: _dialogInputDecoration('Loại chuyển động'),
                    dropdownColor: Theme.of(context).cardColor,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    value: selectedType,
                    items: animTypes.map((type) {
                      return DropdownMenuItem<String>(
                        value: type['value'],
                        child: Text(
                          type['name']!,
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedType = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    decoration: _dialogInputDecoration('Màu chữ'),
                    dropdownColor: Theme.of(context).cardColor,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    value:
                        colors.any((c) => c['color'].value == selectedColorVal)
                        ? selectedColorVal
                        : colors[0]['color'].value,
                    items: colors.map((c) {
                      return DropdownMenuItem<int>(
                        value: c['color'].value,
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: c['color'],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              c['name'],
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedColorVal = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text(
                        'Cỡ chữ:',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      Expanded(
                        child: Slider(
                          min: 12.0,
                          max: 26.0,
                          divisions: 14,
                          label: selectedFontSize.toStringAsFixed(0),
                          value: selectedFontSize,
                          onChanged: (v) {
                            setDialogState(() {
                              selectedFontSize = v;
                            });
                          },
                        ),
                      ),
                      Text(
                        selectedFontSize.toStringAsFixed(0),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text(
                        'Tốc độ:',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      Expanded(
                        child: Slider(
                          min: 0.5,
                          max: 3.0,
                          divisions: 10,
                          label: '${selectedSpeed.toStringAsFixed(1)}x',
                          value: selectedSpeed,
                          onChanged: (v) {
                            setDialogState(() {
                              selectedSpeed = v;
                            });
                          },
                        ),
                      ),
                      Text(
                        '${selectedSpeed.toStringAsFixed(1)}x',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                final jsonStr = jsonEncode({
                  'text': textController.text,
                  'type': selectedType,
                  'colorVal': selectedColorVal,
                  'fontSize': selectedFontSize,
                  'speed': selectedSpeed,
                });
                if (index == null) {
                  _addBlock(BlockType.animatedText, jsonStr);
                } else {
                  setState(() {
                    _blockControllers[index].text = jsonStr;
                  });
                }
              },
              child: const Text(
                'Lưu',
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editFormulaBlock(int? index) {
    Map<String, dynamic> data = {};
    if (index != null && _blockControllers[index].text.isNotEmpty) {
      final content = _blockControllers[index].text;
      if (content.startsWith('{') && content.endsWith('}')) {
        try {
          data = jsonDecode(content);
        } catch (_) {}
      } else {
        data = {'text': content};
      }
    }

    final textController = TextEditingController(text: data['text'] ?? '');
    int selectedColorVal = data['colorVal'] ?? Colors.pinkAccent.value;
    int selectedTextColorVal = data['textColorVal'] ?? selectedColorVal;

    final List<Map<String, dynamic>> colors = [
      {'name': 'Pink (Hồng)', 'color': Colors.pinkAccent},
      {'name': 'Cyan (Xanh ngọc)', 'color': Colors.cyanAccent},
      {'name': 'Green (Xanh lá)', 'color': Colors.greenAccent},
      {'name': 'Orange (Cam)', 'color': Colors.orangeAccent},
      {'name': 'Yellow (Vàng)', 'color': Colors.yellowAccent},
      {'name': 'Blue (Xanh dương)', 'color': Colors.blueAccent},
      {'name': 'Red (Đỏ)', 'color': Colors.redAccent},
      {'name': 'Purple (Tím)', 'color': Colors.purpleAccent},
      {'name': 'White (Trắng)', 'color': Colors.white},
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).dialogBackgroundColor,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            index == null ? 'Thêm công thức' : 'Sửa công thức',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: textController,
                  decoration: _dialogInputDecoration(
                    'Công thức bida',
                    hintText: 'VD: TỔNG = GBC + VT CARDE - ĐT',
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  decoration: _dialogInputDecoration('Màu sắc viền & nền'),
                  dropdownColor: Theme.of(context).cardColor,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  value: colors.any((c) => c['color'].value == selectedColorVal)
                      ? selectedColorVal
                      : colors[0]['color'].value,
                  items: colors.map((c) {
                    return DropdownMenuItem<int>(
                      value: c['color'].value,
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: c['color'],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(c['name']),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() {
                        if (selectedTextColorVal == selectedColorVal) {
                          selectedTextColorVal = val;
                        }
                        selectedColorVal = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  decoration: _dialogInputDecoration('Màu chữ'),
                  dropdownColor: Theme.of(context).cardColor,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  value:
                      colors.any(
                        (c) => c['color'].value == selectedTextColorVal,
                      )
                      ? selectedTextColorVal
                      : selectedColorVal,
                  items: colors.map((c) {
                    return DropdownMenuItem<int>(
                      value: c['color'].value,
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: c['color'],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(c['name']),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() {
                        selectedTextColorVal = val;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                final jsonStr = jsonEncode({
                  'text': textController.text,
                  'colorVal': selectedColorVal,
                  'textColorVal': selectedTextColorVal,
                });
                if (index == null) {
                  _addBlock(BlockType.formula, jsonStr);
                } else {
                  setState(() {
                    _blockControllers[index].text = jsonStr;
                  });
                }
              },
              child: const Text(
                'Lưu',
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editSectionBlock(int? index) {
    Map<String, dynamic> data = {};
    if (index != null && _blockControllers[index].text.isNotEmpty) {
      try {
        data = jsonDecode(_blockControllers[index].text);
      } catch (e) {
        data = {};
      }
    }

    final numberController = TextEditingController(
      text: (data['number'] ?? 1).toString(),
    );
    final titleController = TextEditingController(text: data['title'] ?? '');
    final textController = TextEditingController(text: data['text'] ?? '');
    int selectedColorVal = data['colorVal'] ?? Colors.cyan.value;

    final List<Map<String, dynamic>> colors = [
      {'name': 'Cyan (Xanh ngọc)', 'color': Colors.cyan},
      {'name': 'Orange (Cam)', 'color': Colors.orange},
      {'name': 'Green (Xanh lá)', 'color': Colors.green},
      {'name': 'Blue (Xanh dương)', 'color': Colors.blue},
      {'name': 'Yellow (Vàng)', 'color': Colors.yellow},
      {'name': 'Red (Đỏ)', 'color': Colors.red},
      {'name': 'Purple (Tím)', 'color': Colors.purple},
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).dialogBackgroundColor,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            index == null ? 'Thêm Section' : 'Sửa Section',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: numberController,
                    decoration: _dialogInputDecoration(
                      'Số thứ tự chương (VD: 1, 2)',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: _dialogInputDecoration('Tiêu đề chương'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: textController,
                    decoration: _dialogInputDecoration('Nội dung (tùy chọn)'),
                    maxLines: null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    decoration: _dialogInputDecoration('Màu sắc tiêu đề'),
                    dropdownColor: Theme.of(context).cardColor,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    value:
                        colors.any((c) => c['color'].value == selectedColorVal)
                        ? selectedColorVal
                        : colors[0]['color'].value,
                    items: colors.map((c) {
                      return DropdownMenuItem<int>(
                        value: c['color'].value,
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: c['color'],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(c['name']),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedColorVal = val;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                final String result = jsonEncode({
                  'number': int.tryParse(numberController.text) ?? 1,
                  'title': titleController.text,
                  'text': textController.text,
                  'colorVal': selectedColorVal,
                });
                setState(() {
                  if (index == null) {
                    _addBlock(BlockType.section, result);
                  } else {
                    _blockControllers[index].text = result;
                  }
                });
                Navigator.pop(context);
              },
              child: Text(
                index == null ? 'Thêm' : 'Lưu',
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editSubSectionBlock(int? index) {
    Map<String, dynamic> data = {};
    if (index != null && _blockControllers[index].text.isNotEmpty) {
      try {
        data = jsonDecode(_blockControllers[index].text);
      } catch (e) {
        data = {};
      }
    }

    final titleController = TextEditingController(text: data['title'] ?? '');
    final textController = TextEditingController(text: data['text'] ?? '');
    int selectedColorVal = data['colorVal'] ?? Colors.blue.value;

    final List<Map<String, dynamic>> colors = [
      {'name': 'Blue (Xanh dương)', 'color': Colors.blue},
      {'name': 'Cyan (Xanh ngọc)', 'color': Colors.cyan},
      {'name': 'Orange (Cam)', 'color': Colors.orange},
      {'name': 'Green (Xanh lá)', 'color': Colors.green},
      {'name': 'Yellow (Vàng)', 'color': Colors.yellow},
      {'name': 'Red (Đỏ)', 'color': Colors.red},
      {'name': 'Purple (Tím)', 'color': Colors.purple},
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).dialogBackgroundColor,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            index == null ? 'Thêm SubSection' : 'Sửa SubSection',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: _dialogInputDecoration('Tiêu đề chương con'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: textController,
                    decoration: _dialogInputDecoration('Nội dung (tùy chọn)'),
                    maxLines: null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    decoration: _dialogInputDecoration('Màu sắc tiêu đề con'),
                    dropdownColor: Theme.of(context).cardColor,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    value:
                        colors.any((c) => c['color'].value == selectedColorVal)
                        ? selectedColorVal
                        : colors[0]['color'].value,
                    items: colors.map((c) {
                      return DropdownMenuItem<int>(
                        value: c['color'].value,
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: c['color'],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(c['name']),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedColorVal = val;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                final String result = jsonEncode({
                  'title': titleController.text,
                  'text': textController.text,
                  'colorVal': selectedColorVal,
                });
                setState(() {
                  if (index == null) {
                    _addBlock(BlockType.subSection, result);
                  } else {
                    _blockControllers[index].text = result;
                  }
                });
                Navigator.pop(context);
              },
              child: Text(
                index == null ? 'Thêm' : 'Lưu',
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editHeadingTextBlock(int? index) {
    Map<String, dynamic> data = {};
    if (index != null && _blockControllers[index].text.isNotEmpty) {
      try {
        data = jsonDecode(_blockControllers[index].text);
      } catch (e) {
        data = {};
      }
    }

    final headingController = TextEditingController(
      text: data['heading'] ?? '',
    );
    final textController = TextEditingController(text: data['text'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          index == null ? 'Thêm Tiêu đề + Đoạn văn' : 'Sửa Tiêu đề + Đoạn văn',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: headingController,
                  decoration: _dialogInputDecoration('Tiêu đề phụ (màu vàng)'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: textController,
                  decoration: _dialogInputDecoration('Nội dung đoạn văn'),
                  maxLines: null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              final String result = jsonEncode({
                'heading': headingController.text,
                'text': textController.text,
              });
              setState(() {
                if (index == null) {
                  _addBlock(BlockType.headingText, result);
                } else {
                  _blockControllers[index].text = result;
                }
              });
              Navigator.pop(context);
            },
            child: Text(index == null ? 'Thêm' : 'Lưu'),
          ),
        ],
      ),
    );
  }

  void _editDataTableBlock(int? index) {
    Map<String, dynamic> data = {};
    if (index != null && _blockControllers[index].text.isNotEmpty) {
      try {
        data = jsonDecode(_blockControllers[index].text);
      } catch (e) {
        data = {};
      }
    }

    List<dynamic> initialRows = data['data'] ?? [];
    String textVal = '';
    if (initialRows.isNotEmpty) {
      textVal = initialRows.map((row) => (row as List).join(' | ')).join('\n');
    } else {
      textVal =
          "TỔNG ĐỘ LỆCH | CHẠM | ÉP-PHÊ / KỸ THUẬT\n7 | 1/2 | 0.0 EF\n8 | 1/2 | 0.5 EF";
    }

    final textController = TextEditingController(text: textVal);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          index == null ? 'Thêm Bảng dữ liệu' : 'Sửa Bảng dữ liệu',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nhập dữ liệu bảng, phân tách các cột bằng ký tự | (Dòng đầu tiên là tiêu đề):',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: textController,
                  decoration: _dialogInputDecoration(
                    'Dữ liệu bảng (CSV dạng |)',
                    hintText: 'Cột 1 | Cột 2\nDòng 1 | Dòng 1',
                  ),
                  maxLines: 8,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              List<List<String>> parsedData = [];
              LineSplitter().convert(textController.text).forEach((line) {
                if (line.trim().isNotEmpty) {
                  parsedData.add(line.split('|').map((e) => e.trim()).toList());
                }
              });

              final String result = jsonEncode({'data': parsedData});

              setState(() {
                if (index == null) {
                  _addBlock(BlockType.dataTable, result);
                } else {
                  _blockControllers[index].text = result;
                }
              });
              Navigator.pop(context);
            },
            child: Text(
              index == null ? 'Thêm' : 'Lưu',
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editIconTextBlock(int? index) {
    Map<String, dynamic> data = {};
    if (index != null && _blockControllers[index].text.isNotEmpty) {
      try {
        data = jsonDecode(_blockControllers[index].text);
      } catch (e) {
        data = {};
      }
    }

    int selectedIconCode = data['iconCode'] ?? Icons.lightbulb.codePoint;
    int selectedColorVal = data['colorVal'] ?? Colors.amber.value;
    final textController = TextEditingController(text: data['text'] ?? '');

    final List<Map<String, dynamic>> icons = [
      {'name': '💡 Gợi ý', 'icon': Icons.lightbulb, 'color': Colors.amber},
      {'name': 'ℹ️ Thông tin', 'icon': Icons.info, 'color': Colors.blue},
      {'name': '⚠️ Lưu ý', 'icon': Icons.warning, 'color': Colors.orange},
      {'name': '⭐ Quan trọng', 'icon': Icons.star, 'color': Colors.redAccent},
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).dialogBackgroundColor,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                index == null ? 'Thêm Chú thích Icon' : 'Sửa Chú thích Icon',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<int>(
                        decoration: _dialogInputDecoration(
                          'Chọn Biểu tượng (Icon)',
                        ),
                        dropdownColor: Theme.of(context).cardColor,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        value: selectedIconCode,
                        items: icons.map((item) {
                          return DropdownMenuItem<int>(
                            value: item['icon'].codePoint,
                            child: Row(
                              children: [
                                Icon(item['icon'], color: item['color']),
                                const SizedBox(width: 8),
                                Text(
                                  item['name'],
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedIconCode = val;
                              selectedColorVal = icons
                                  .firstWhere(
                                    (element) =>
                                        element['icon'].codePoint == val,
                                  )['color']
                                  .value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: textController,
                        decoration: _dialogInputDecoration(
                          'Nội dung chú thích',
                        ),
                        maxLines: null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Hủy',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final String result = jsonEncode({
                      'iconCode': selectedIconCode,
                      'colorVal': selectedColorVal,
                      'text': textController.text,
                    });
                    setState(() {
                      if (index == null) {
                        _addBlock(BlockType.iconText, result);
                      } else {
                        _blockControllers[index].text = result;
                      }
                    });
                    Navigator.pop(context);
                  },
                  child: Text(
                    index == null ? 'Thêm' : 'Lưu',
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _editYoutubeBlock(int? index) {
    String initialUrl = '';
    String initialStart = '';
    String initialEnd = '';
    if (index != null && _blockControllers[index].text.isNotEmpty) {
      final content = _blockControllers[index].text;
      if (content.startsWith('{') && content.endsWith('}')) {
        try {
          final data = jsonDecode(content);
          initialUrl =
              'https://www.youtube.com/watch?v=${data['videoId'] ?? ''}';
          final startVal = data['startSeconds'];
          if (startVal != null) {
            final m = startVal ~/ 60;
            final s = startVal % 60;
            initialStart = m == 0 ? '$s' : '$m:${s.toString().padLeft(2, '0')}';
          }
          final endVal = data['endSeconds'];
          if (endVal != null) {
            final m = endVal ~/ 60;
            final s = endVal % 60;
            initialEnd = m == 0 ? '$s' : '$m:${s.toString().padLeft(2, '0')}';
          }
        } catch (_) {}
      } else {
        initialUrl = 'https://www.youtube.com/watch?v=$content';
      }
    }

    final urlController = TextEditingController(text: initialUrl);
    final startController = TextEditingController(text: initialStart);
    final endController = TextEditingController(text: initialEnd);

    int? parseTimeToSeconds(String text) {
      final trimmed = text.trim();
      if (trimmed.isEmpty) return null;
      if (trimmed.contains(':')) {
        final parts = trimmed.split(':');
        if (parts.length == 2) {
          final m = int.tryParse(parts[0]) ?? 0;
          final s = int.tryParse(parts[1]) ?? 0;
          return m * 60 + s;
        }
      }
      return int.tryParse(trimmed);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          index == null ? 'Chèn video Youtube' : 'Sửa video Youtube',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: urlController,
                  decoration: _dialogInputDecoration(
                    'URL hoặc ID video Youtube',
                    hintText: 'https://www.youtube.com/watch?v=...',
                  ),
                  maxLines: null,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Thời gian phát (Ví dụ: 90 hoặc 1:30):',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: startController,
                        decoration: _dialogInputDecoration(
                          'Từ (Bắt đầu)',
                          hintText: '0:00',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: endController,
                        decoration: _dialogInputDecoration(
                          'Đến (Kết thúc)',
                          hintText: 'Hết video',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              String url = urlController.text.trim();
              if (url.isNotEmpty) {
                String? parsedId = YoutubePlayer.convertUrlToId(url);
                String videoId = parsedId ?? url;

                if (videoId.isNotEmpty) {
                  final startSec = parseTimeToSeconds(startController.text);
                  final endSec = parseTimeToSeconds(endController.text);

                  final String blockText = (startSec != null || endSec != null)
                      ? jsonEncode({
                          'videoId': videoId,
                          'startSeconds': startSec,
                          'endSeconds': endSec,
                        })
                      : videoId;

                  setState(() {
                    if (index == null) {
                      _addBlock(BlockType.youtube, blockText);
                    } else {
                      _blockControllers[index].text = blockText;
                    }
                  });
                }
              }
              Navigator.pop(context);
            },
            child: Text(
              index == null ? 'Thêm' : 'Lưu',
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToClipboard() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final note = _currentDraft().toNote();

      final String jsonStr = NoteDocumentCodec.encode(note);
      await Clipboard.setData(ClipboardData(text: jsonStr));
      messenger.showSnackBar(
        const SnackBar(content: Text('Đã sao chép mã bài viết vào Clipboard!')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Lỗi xuất Clipboard: $e')));
    }
  }

  Future<void> _importFromClipboard() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data == null || data.text == null || data.text!.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Clipboard trống hoặc không có văn bản!'),
          ),
        );
        return;
      }

      final note = NoteDocumentCodec.decode(data.text!);
      {
        setState(() {
          _titleController.text = note.title;
          _subtitleController.text = note.subtitle;

          // Clear current blocks
          _blockControllers.clear();
          _blockTypes.clear();
          _blockKeys.clear();

          // Populate new blocks
          for (var block in note.blocks) {
            _addBlock(block.type, block.content);
          }
        });
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Đã nhập bài viết từ Clipboard thành công!'),
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Lỗi nhập Clipboard: $e\nHãy chắc chắn bạn đã sao chép đúng mã JSON bài viết.',
          ),
        ),
      );
    }
  }

  Future<void> _exportToFile() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final note = _currentDraft().toNote();

      final String jsonStr = NoteDocumentCodec.encode(note);
      String? outputPath;

      if (Platform.isWindows) {
        outputPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Lưu bài viết thành file',
          fileName:
              'bai_viet_${note.title.replaceAll(RegExp(r'[<>:"/\\|?* ]'), '_')}.txt',
          type: FileType.custom,
          allowedExtensions: ['txt'],
        );
        if (outputPath != null) {
          final file = File(outputPath);
          await file.writeAsString(jsonStr);
        }
      } else {
        // Android fallback to Download or Documents folder
        try {
          final dir = Directory('/storage/emulated/0/Download');
          if (await dir.exists()) {
            final sanitizedTitle = note.title.replaceAll(
              RegExp(r'[<>:"/\\|?* ]'),
              '_',
            );
            final file = File('${dir.path}/bai_viet_$sanitizedTitle.txt');
            await file.writeAsString(jsonStr);
            outputPath = file.path;
          } else {
            final dir = await getApplicationDocumentsDirectory();
            final sanitizedTitle = note.title.replaceAll(
              RegExp(r'[<>:"/\\|?* ]'),
              '_',
            );
            final file = File('${dir.path}/bai_viet_$sanitizedTitle.txt');
            await file.writeAsString(jsonStr);
            outputPath = file.path;
          }
        } catch (_) {
          final dir = await getApplicationDocumentsDirectory();
          final sanitizedTitle = note.title.replaceAll(
            RegExp(r'[<>:"/\\|?* ]'),
            '_',
          );
          final file = File('${dir.path}/bai_viet_$sanitizedTitle.txt');
          await file.writeAsString(jsonStr);
          outputPath = file.path;
        }
      }

      if (outputPath != null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Đã lưu bài viết thành file thành công tại: $outputPath',
            ),
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Lỗi xuất file: $e')));
    }
  }

  Future<void> _importFromFile() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'json', 'md'],
      );
      if (result == null || result.files.single.path == null) {
        return;
      }
      final file = File(result.files.single.path!);
      final String content = await file.readAsString();
      final note = NoteDocumentCodec.decode(content);
      {
        setState(() {
          _titleController.text = note.title;
          _subtitleController.text = note.subtitle;

          // Clear current blocks
          _blockControllers.clear();
          _blockTypes.clear();
          _blockKeys.clear();

          // Populate new blocks
          for (var block in note.blocks) {
            _addBlock(block.type, block.content);
          }
        });
        messenger.showSnackBar(
          const SnackBar(content: Text('Đã nhập bài viết từ file thành công!')),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Lỗi nhập file: $e\nHãy chắc chắn bạn chọn đúng file bài viết.',
          ),
        ),
      );
    }
  }

  NoteDraft _currentDraft() {
    final blocks = <NoteBlock>[];
    for (var i = 0; i < _blockControllers.length; i++) {
      final content = _blockControllers[i].text;
      if (content.isNotEmpty) {
        blocks.add(NoteBlock(content: content, type: _blockTypes[i]));
      }
    }
    return NoteDraft(
      id: widget.note?.id,
      title: _titleController.text,
      subtitle: _subtitleController.text,
      blocks: blocks,
      date: _draftDate,
      color: widget.note?.color ?? Colors.deepPurple,
    );
  }

  String _editorSignature() =>
      NoteDocumentCodec.encode(_currentDraft().toNote());

  bool get _hasUnsavedChanges => _editorSignature() != _initialSignature;

  Future<bool> _confirmLeaveEditor() async {
    if (_submitted || !_hasUnsavedChanges) return true;
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rời trình chỉnh sửa?'),
        content: const Text(
          'Các thay đổi chưa được lưu vào bài viết. Bản nháp tự động vẫn được giữ lại.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Tiếp tục chỉnh sửa'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Rời đi'),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  String _blockTypeLabel(BlockType type) {
    switch (type) {
      case BlockType.text:
        return 'Đoạn văn';
      case BlockType.item:
        return 'Danh sách';
      case BlockType.image:
        return 'Hình ảnh';
      case BlockType.diagram:
        return 'Sơ đồ bi';
      case BlockType.shotDetail:
        return 'Chi tiết cú đánh';
      case BlockType.section:
        return 'Tiêu đề lớn';
      case BlockType.subSection:
        return 'Tiêu đề nhỏ';
      case BlockType.headingText:
        return 'Tiêu đề và văn bản';
      case BlockType.dataTable:
        return 'Bảng dữ liệu';
      case BlockType.iconText:
        return 'Hộp chú thích';
      case BlockType.youtube:
        return 'Video YouTube';
      case BlockType.effetDiagram:
        return 'Biểu đồ Ép-phê';
      case BlockType.formula:
        return 'Công thức';
      case BlockType.animatedText:
        return 'Chữ động';
    }
  }

  Widget _buildCollapsedBlock(int index) {
    return Container(
      key: _blockKeys[index],
      height: 58,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 14, right: 245),
              child: Text(
                _blockTypeLabel(_blockTypes[index]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          ..._buildBlockActionButtons(index),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color currentColor = Colors.deepPurple;

    return PopScope<Object?>(
      canPop: _submitted || !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (!await _confirmLeaveEditor() || !mounted) return;
        setState(() => _submitted = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.pop(context, result);
        });
      },
      child: Scaffold(
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
            widget.note == null ? 'Ghi chú mới' : 'Sửa ghi chú',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            if (_draftSavedAt != null)
              Semantics(
                label: 'Bản nháp đã được tự động lưu',
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.cloud_done_outlined, color: Colors.white70),
                ),
              ),
            IconButton(
              onPressed: _undoHistory.isEmpty ? null : _undoBlockAction,
              icon: const Icon(Icons.undo, color: Colors.white),
              tooltip: 'Hoàn tác thao tác khối',
            ),
            IconButton(
              onPressed: _redoHistory.isEmpty ? null : _redoBlockAction,
              icon: const Icon(Icons.redo, color: Colors.white),
              tooltip: 'Làm lại thao tác khối',
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 26, color: Colors.white),
              tooltip: 'Nhập / Xuất bài viết',
              onSelected: (value) {
                if (value == 'import_clip') {
                  _importFromClipboard();
                } else if (value == 'export_clip') {
                  _exportToClipboard();
                } else if (value == 'import_file') {
                  _importFromFile();
                } else if (value == 'export_file') {
                  _exportToFile();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'import_clip',
                  child: Row(
                    children: [
                      Icon(Icons.content_paste, color: Colors.cyanAccent),
                      SizedBox(width: 8),
                      Text('Nhập từ Clipboard'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'export_clip',
                  child: Row(
                    children: [
                      Icon(Icons.copy, color: Colors.cyanAccent),
                      SizedBox(width: 8),
                      Text('Xuất ra Clipboard'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'import_file',
                  child: Row(
                    children: [
                      Icon(Icons.file_open, color: Colors.orangeAccent),
                      SizedBox(width: 8),
                      Text('Nhập từ File (.txt, .json, .md)'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'export_file',
                  child: Row(
                    children: [
                      Icon(Icons.save, color: Colors.orangeAccent),
                      SizedBox(width: 8),
                      Text('Xuất ra File (.txt)'),
                    ],
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.check, size: 30, color: Colors.white),
              onPressed: () {
                final draft = _currentDraft();
                setState(() => _submitted = true);
                unawaited(_clearDraft());
                final result = draft.isEmpty ? null : draft.toNote();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) Navigator.pop(context, result);
                });
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6.0,
                  vertical: 16.0,
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        hintText: 'Tiêu đề',
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextField(
                      controller: _subtitleController,
                      decoration: const InputDecoration(
                        hintText: 'Phụ đề (tùy chọn)',
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const Divider(),
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _blockControllers.length,
                      onReorder: (int oldIndex, int newIndex) {
                        _recordBlockHistory();
                        setState(() {
                          if (oldIndex < newIndex) {
                            newIndex -= 1;
                          }
                          final type = _blockTypes.removeAt(oldIndex);
                          _blockTypes.insert(newIndex, type);

                          final controller = _blockControllers.removeAt(
                            oldIndex,
                          );
                          _blockControllers.insert(newIndex, controller);

                          final key = _blockKeys.removeAt(oldIndex);
                          _blockKeys.insert(newIndex, key);
                        });
                      },
                      itemBuilder: (context, index) {
                        BlockType type = _blockTypes[index];

                        if (_collapsedBlockKeys.contains(_blockKeys[index])) {
                          return _buildCollapsedBlock(index);
                        }

                        if (type == BlockType.image) {
                          return Padding(
                            key: _blockKeys[index],
                            padding: EdgeInsets.zero,
                            child: Stack(
                              children: [
                                NoteImageBlock(
                                  data: ImageBlockData.decode(
                                    _blockControllers[index].text,
                                  ),
                                  previewHeight: 200,
                                  enableFullscreen: false,
                                ),
                                ..._buildBlockActionButtons(index),
                              ],
                            ),
                          );
                        }

                        if (type == BlockType.diagram) {
                          Map<String, dynamic> data;
                          try {
                            data = jsonDecode(_blockControllers[index].text);
                          } catch (e) {
                            data = {};
                          }
                          List<Ball> balls = [];
                          if (data.containsKey('white'))
                            balls.add(
                              Ball.at(
                                (data['white'][0] as num).toDouble(),
                                (data['white'][1] as num).toDouble(),
                                Colors.white,
                              ),
                            );
                          if (data.containsKey('yellow'))
                            balls.add(
                              Ball.at(
                                (data['yellow'][0] as num).toDouble(),
                                (data['yellow'][1] as num).toDouble(),
                                Colors.yellow,
                              ),
                            );
                          if (data.containsKey('red'))
                            balls.add(
                              Ball.at(
                                (data['red'][0] as num).toDouble(),
                                (data['red'][1] as num).toDouble(),
                                Colors.red,
                              ),
                            );
                          if (data.containsKey('ghosts')) {
                            var gh = data['ghosts'];
                            if (gh is List) {
                              for (var g in gh) {
                                balls.add(
                                  Ball.at(
                                    (g['x'] as num).toDouble(),
                                    (g['y'] as num).toDouble(),
                                    Color(g['color'] ?? Colors.white.value),
                                    isGhost: true,
                                    opacity: 0.5,
                                    type: BallType.values[g['type'] ?? 0],
                                    rotation:
                                        ((g['rotation'] ?? 0.0) as double) *
                                        math.pi /
                                        180.0,
                                    text: g['number']?.toString(),
                                  ),
                                );
                              }
                            }
                          }
                          TableViewType vType =
                              TableViewType.values[data['viewType'] ?? 0];
                          DiagramSystem sys =
                              DiagramSystem.values[data['system'] ?? 0];

                          List<BallPath> paths = [];
                          if (data.containsKey('paths')) {
                            var p = data['paths'];
                            if (p['white'] != null &&
                                (p['white'] as List).isNotEmpty) {
                              paths.add(
                                BallPath.diamonds(
                                  points: [
                                    Offset(
                                      (data['white'][0] as num).toDouble(),
                                      (data['white'][1] as num).toDouble(),
                                    ),
                                    ...(p['white'] as List).map(
                                      (e) => Offset(
                                        (e[0] as num).toDouble(),
                                        (e[1] as num).toDouble(),
                                      ),
                                    ),
                                  ],
                                  color: Colors.white70,
                                ),
                              );
                            }
                            if (p['yellow'] != null &&
                                (p['yellow'] as List).isNotEmpty) {
                              paths.add(
                                BallPath.diamonds(
                                  points: [
                                    Offset(
                                      (data['yellow'][0] as num).toDouble(),
                                      (data['yellow'][1] as num).toDouble(),
                                    ),
                                    ...(p['yellow'] as List).map(
                                      (e) => Offset(
                                        (e[0] as num).toDouble(),
                                        (e[1] as num).toDouble(),
                                      ),
                                    ),
                                  ],
                                  color: Colors.yellow,
                                ),
                              );
                            }
                            if (p['red'] != null &&
                                (p['red'] as List).isNotEmpty) {
                              paths.add(
                                BallPath.diamonds(
                                  points: [
                                    Offset(
                                      (data['red'][0] as num).toDouble(),
                                      (data['red'][1] as num).toDouble(),
                                    ),
                                    ...(p['red'] as List).map(
                                      (e) => Offset(
                                        (e[0] as num).toDouble(),
                                        (e[1] as num).toDouble(),
                                      ),
                                    ),
                                  ],
                                  color: Colors.redAccent,
                                ),
                              );
                            }
                            if (p['free'] != null &&
                                (p['free'] as List).isNotEmpty) {
                              for (var fp in p['free']) {
                                if (fp is List && fp.isNotEmpty) {
                                  paths.add(
                                    BallPath.diamonds(
                                      points: fp
                                          .map(
                                            (e) => Offset(
                                              (e[0] as num).toDouble(),
                                              (e[1] as num).toDouble(),
                                            ),
                                          )
                                          .toList(),
                                      color: Colors.cyanAccent,
                                    ),
                                  );
                                }
                              }
                            }
                          }

                          double labelFontSize =
                              (data['labelFontSize'] as num?)?.toDouble() ??
                              9.5;
                          List<BilliardLabel> labels = [];
                          if (data.containsKey('labels')) {
                            var lbls = data['labels'];
                            if (lbls is List) {
                              for (var l in lbls) {
                                labels.add(
                                  BilliardLabel.at(
                                    (l['x'] as num).toDouble(),
                                    (l['y'] as num).toDouble(),
                                    l['text'].toString(),
                                    color: Color(
                                      l['color'] ?? Colors.yellowAccent.value,
                                    ),
                                    fontSize: labelFontSize,
                                    rotation:
                                        ((l['rotation'] ?? 0.0) as num)
                                            .toDouble() *
                                        math.pi /
                                        180.0,
                                    role: l['role']?.toString(),
                                  ),
                                );
                              }
                            }
                          }

                          if (data.containsKey('cushionNumbers')) {
                            var cNums = data['cushionNumbers'];
                            if (cNums is List) {
                              for (var c in cNums) {
                                labels.add(
                                  BilliardLabel.at(
                                    (c['x'] as num).toDouble(),
                                    (c['y'] as num).toDouble(),
                                    c['text'].toString(),
                                    color: Color(
                                      c['color'] ?? Colors.yellowAccent.value,
                                    ),
                                    fontSize: labelFontSize,
                                    rotation:
                                        ((c['rotation'] ?? 0.0) as num)
                                            .toDouble() *
                                        math.pi /
                                        180.0,
                                    role: 'cushion',
                                  ),
                                );
                              }
                            }
                          }

                          return Padding(
                            key: _blockKeys[index],
                            padding: const EdgeInsets.only(bottom: 15),
                            child: Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[850],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.greenAccent.withOpacity(
                                        0.5,
                                      ),
                                    ),
                                  ),
                                  child: balls.isNotEmpty
                                      ? BilliardDiagram(
                                          viewType: vType,
                                          system: sys,
                                          isVertical: true,
                                          balls: balls,
                                          paths: paths,
                                          labels: labels,
                                        )
                                      : const Text(
                                          'Lỗi dữ liệu bi',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                ),
                                ..._buildBlockActionButtons(index),
                              ],
                            ),
                          );
                        }

                        if (type == BlockType.effetDiagram) {
                          dynamic blockData;
                          List<dynamic> spots = [];
                          try {
                            blockData = jsonDecode(
                              _blockControllers[index].text,
                            );
                            if (blockData is Map &&
                                blockData.containsKey('spots')) {
                              spots = blockData['spots'];
                            }
                          } catch (_) {}
                          return Padding(
                            key: _blockKeys[index],
                            padding: const EdgeInsets.only(bottom: 15),
                            child: Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[850],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.cyanAccent.withOpacity(0.5),
                                    ),
                                  ),
                                  child:
                                      (spots.isNotEmpty ||
                                          (blockData is Map &&
                                              blockData['showHitBall'] == true))
                                      ? ArticleBlocks.effetDiagram(
                                          blockData ?? spots,
                                        )
                                      : const Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 20,
                                          ),
                                          child: Text(
                                            'Biểu đồ Ép-phê trống',
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                ),
                                ..._buildBlockActionButtons(index),
                              ],
                            ),
                          );
                        }

                        if (type == BlockType.animatedText) {
                          Map<String, dynamic> data;
                          try {
                            data = jsonDecode(_blockControllers[index].text);
                          } catch (_) {
                            data = {
                              'text': _blockControllers[index].text,
                              'type': 'marquee',
                              'colorVal': Colors.cyanAccent.value,
                              'fontSize': 16.0,
                              'speed': 1.0,
                            };
                          }
                          final String text = data['text'] ?? '';
                          final String animType = data['type'] ?? 'marquee';
                          final Color color = Color(
                            data['colorVal'] ?? Colors.cyanAccent.value,
                          );
                          final double fontSize =
                              (data['fontSize'] as num?)?.toDouble() ?? 16.0;
                          final double speed =
                              (data['speed'] as num?)?.toDouble() ?? 1.0;

                          return Padding(
                            key: _blockKeys[index],
                            padding: const EdgeInsets.only(bottom: 15),
                            child: Stack(
                              children: [
                                ArticleBlocks.animatedText(
                                  text: text,
                                  type: animType,
                                  color: color,
                                  fontSize: fontSize,
                                  speed: speed,
                                ),
                                ..._buildBlockActionButtons(index),
                              ],
                            ),
                          );
                        }

                        if (type == BlockType.shotDetail) {
                          Map<String, dynamic> data;
                          try {
                            data = jsonDecode(_blockControllers[index].text);
                          } catch (e) {
                            data = {
                              "thickness": 0.5,
                              "effet": [0.0, 0.0],
                            };
                          }

                          return Padding(
                            key: _blockKeys[index],
                            padding: const EdgeInsets.only(bottom: 15),
                            child: Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[850],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.orangeAccent.withOpacity(
                                        0.5,
                                      ),
                                    ),
                                  ),
                                  child: ImpactIndicator(
                                    thickness: (data['thickness'] ?? 0.5)
                                        .toDouble(),
                                    effet: Offset(
                                      (data['effet']?[0] ?? 0.0).toDouble(),
                                      (data['effet']?[1] ?? 0.0).toDouble(),
                                    ),
                                    forceImagePath: data['forceImage']
                                        ?.toString(),
                                    cueAngle: (data['cueAngle'] ?? 0.0)
                                        .toDouble(),
                                    size: 70,
                                  ),
                                ),
                                ..._buildBlockActionButtons(index),
                              ],
                            ),
                          );
                        }

                        if (type == BlockType.section) {
                          Map<String, dynamic> data;
                          try {
                            data = jsonDecode(_blockControllers[index].text);
                          } catch (e) {
                            data = {};
                          }
                          int number = data['number'] ?? 1;
                          String title = data['title'] ?? '';
                          String text = data['text'] ?? '';
                          Color blockColor = data['colorVal'] != null
                              ? Color(data['colorVal'])
                              : Colors.cyan;
                          return Padding(
                            key: _blockKeys[index],
                            padding: const EdgeInsets.only(bottom: 15),
                            child: Stack(
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[850],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: blockColor.withOpacity(0.5),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 12,
                                            backgroundColor: blockColor,
                                            child: Text(
                                              '$number',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'SECTION: $title',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: blockColor,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (text.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          text,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                ..._buildBlockActionButtons(index),
                              ],
                            ),
                          );
                        }

                        if (type == BlockType.subSection) {
                          Map<String, dynamic> data;
                          try {
                            data = jsonDecode(_blockControllers[index].text);
                          } catch (e) {
                            data = {};
                          }
                          String title = data['title'] ?? '';
                          String text = data['text'] ?? '';
                          Color blockColor = data['colorVal'] != null
                              ? Color(data['colorVal'])
                              : Colors.blueAccent;
                          return Padding(
                            key: _blockKeys[index],
                            padding: const EdgeInsets.only(bottom: 15),
                            child: Stack(
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[850],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: blockColor.withOpacity(0.5),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'SUBSECTION: $title',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: blockColor,
                                          fontSize: 15,
                                        ),
                                      ),
                                      if (text.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          text,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                ..._buildBlockActionButtons(index),
                              ],
                            ),
                          );
                        }

                        if (type == BlockType.headingText) {
                          Map<String, dynamic> data;
                          try {
                            data = jsonDecode(_blockControllers[index].text);
                          } catch (e) {
                            data = {};
                          }
                          String heading = data['heading'] ?? '';
                          String text = data['text'] ?? '';
                          return Padding(
                            key: _blockKeys[index],
                            padding: const EdgeInsets.only(bottom: 15),
                            child: Stack(
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[850],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.yellow.withOpacity(0.5),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'TIÊU ĐỀ PHỤ: ${heading.toUpperCase()}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.yellow[400],
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        text,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ..._buildBlockActionButtons(index),
                              ],
                            ),
                          );
                        }

                        if (type == BlockType.dataTable) {
                          Map<String, dynamic> data;
                          try {
                            data = jsonDecode(_blockControllers[index].text);
                          } catch (e) {
                            data = {};
                          }
                          List<dynamic> rows = data['data'] ?? [];
                          return Padding(
                            key: _blockKeys[index],
                            padding: const EdgeInsets.only(bottom: 15),
                            child: Stack(
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[850],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.blueGrey.withOpacity(0.5),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'BẢNG DỮ LIỆU',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blueGrey,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      if (rows.isNotEmpty)
                                        Text(
                                          'Gồm ${rows.length} dòng dữ liệu.',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.white70,
                                          ),
                                        )
                                      else
                                        const Text(
                                          'Bảng rỗng',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.redAccent,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                ..._buildBlockActionButtons(index),
                              ],
                            ),
                          );
                        }

                        if (type == BlockType.iconText) {
                          Map<String, dynamic> data;
                          try {
                            data = jsonDecode(_blockControllers[index].text);
                          } catch (e) {
                            data = {};
                          }
                          int iconCode =
                              data['iconCode'] ?? Icons.lightbulb.codePoint;
                          int colorVal = data['colorVal'] ?? Colors.amber.value;
                          String text = data['text'] ?? '';
                          return Padding(
                            key: _blockKeys[index],
                            padding: const EdgeInsets.only(bottom: 15),
                            child: Stack(
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[850],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Color(colorVal).withOpacity(0.5),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            NoteIconHelper.getIcon(iconCode),
                                            color: Color(colorVal),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'CHÚ THÍCH ĐẶC BIỆT',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        text,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontStyle: FontStyle.italic,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ..._buildBlockActionButtons(index),
                              ],
                            ),
                          );
                        }

                        if (type == BlockType.youtube) {
                          String content = _blockControllers[index].text;
                          String videoId = content;
                          int? startSeconds;
                          int? endSeconds;
                          if (content.startsWith('{') &&
                              content.endsWith('}')) {
                            try {
                              final data = jsonDecode(content);
                              videoId = data['videoId'] ?? '';
                              startSeconds = data['startSeconds'];
                              endSeconds = data['endSeconds'];
                            } catch (_) {}
                          }

                          String timeRangeText = '';
                          if (startSeconds != null || endSeconds != null) {
                            final startText = startSeconds != null
                                ? '${startSeconds ~/ 60}:${(startSeconds % 60).toString().padLeft(2, '0')}'
                                : '0:00';
                            final endText = endSeconds != null
                                ? '${endSeconds ~/ 60}:${(endSeconds % 60).toString().padLeft(2, '0')}'
                                : 'hết';
                            timeRangeText =
                                ' (Phát từ $startText đến $endText)';
                          }

                          return Padding(
                            key: _blockKeys[index],
                            padding: const EdgeInsets.only(bottom: 15),
                            child: Stack(
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[850],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.red.withOpacity(0.5),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.play_circle_filled,
                                            color: Colors.red,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'VIDEO YOUTUBE$timeRangeText',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: Colors.grey,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      if (videoId.isNotEmpty) ...[
                                        Center(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.network(
                                              'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
                                              height: 180,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => Container(
                                                    height: 180,
                                                    color: Colors.black26,
                                                    child: const Center(
                                                      child: Icon(
                                                        Icons.broken_image,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Video ID: $videoId',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ] else ...[
                                        const Text(
                                          'Lỗi: Chưa có ID video',
                                          style: TextStyle(
                                            color: Colors.redAccent,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                ..._buildBlockActionButtons(index),
                              ],
                            ),
                          );
                        }

                        if (type == BlockType.formula) {
                          return Padding(
                            key: _blockKeys[index],
                            padding: const EdgeInsets.only(bottom: 15),
                            child: Stack(
                              children: [
                                ArticleBlocks.formula(
                                  _blockControllers[index].text,
                                  widget.note?.color ?? Colors.pinkAccent,
                                ),
                                ..._buildBlockActionButtons(index),
                              ],
                            ),
                          );
                        }

                        bool isItem = type == BlockType.item;
                        return Padding(
                          key: _blockKeys[index],
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ReorderableDragStartListener(
                                index: index,
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 4,
                                  ),
                                  child: Icon(
                                    Icons.drag_handle,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                ),
                              ),
                              Icon(
                                isItem
                                    ? Icons.fiber_manual_record
                                    : Icons.notes,
                                color: isItem ? Colors.deepPurple : Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _blockControllers[index],
                                  decoration: InputDecoration(
                                    hintText: isItem
                                        ? 'Nhập các ý chính...'
                                        : 'Nhập văn bản...',
                                    border: InputBorder.none,
                                  ),
                                  maxLines: null,
                                  onChanged: (val) {
                                    if (isItem) {
                                      if (val.isEmpty) {
                                        _blockControllers[index]
                                            .value = const TextEditingValue(
                                          text: '• ',
                                          selection: TextSelection.collapsed(
                                            offset: 2,
                                          ),
                                        );
                                        return;
                                      }

                                      List<String> lines = val.split('\n');
                                      bool modified = false;
                                      for (int i = 0; i < lines.length; i++) {
                                        if (lines[i].isNotEmpty &&
                                            !lines[i].startsWith('• ')) {
                                          lines[i] = '• ' + lines[i];
                                          modified = true;
                                        } else if (lines[i].isEmpty &&
                                            i > 0 &&
                                            lines[i - 1].isNotEmpty) {
                                          lines[i] = '• ';
                                          modified = true;
                                        }
                                      }
                                      if (modified) {
                                        String newText = lines.join('\n');
                                        int cursorOffset =
                                            _blockControllers[index]
                                                .selection
                                                .baseOffset;
                                        int addedOffset =
                                            newText.length - val.length;
                                        _blockControllers[index]
                                            .value = TextEditingValue(
                                          text: newText,
                                          selection: TextSelection.collapsed(
                                            offset: (cursorOffset + addedOffset)
                                                .clamp(0, newText.length),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  style: TextStyle(
                                    fontSize: isItem ? 16 : 15,
                                    fontWeight: isItem
                                        ? FontWeight.w500
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (_clipboardType != null)
                                IconButton(
                                  icon: const Icon(
                                    Icons.paste,
                                    size: 20,
                                    color: Colors.greenAccent,
                                  ),
                                  onPressed: () => _pasteBlock(index),
                                ),
                              IconButton(
                                icon: const Icon(
                                  Icons.copy,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                                onPressed: () => _copyBlock(index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.expand_less, size: 20),
                                tooltip: 'Thu gọn khối',
                                onPressed: () {
                                  setState(() {
                                    _collapsedBlockKeys.add(_blockKeys[index]);
                                  });
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                onPressed: () => _removeBlock(index),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            // Thanh công cụ thêm block ở dưới cùng (Thiết kế mới trực quan)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(
                  top: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Nút mở rộng bảng chọn tất cả các khối và nút dán khối
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _showAddBlockSheet(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 4,
                          ),
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text(
                            'Thêm khối',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (_clipboardType != null) ...[
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () =>
                                _pasteBlock(_blockControllers.length - 1),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 4,
                            ),
                            icon: const Icon(Icons.paste, size: 20),
                            label: const Text(
                              'Dán cuối',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    // Các phím tắt nhanh
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => _addBlock(BlockType.text),
                          icon: const Icon(Icons.notes, color: Colors.white70),
                          tooltip: 'Viết chữ',
                        ),
                        IconButton(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const DiagramBuilderPage(),
                              ),
                            );
                            if (result != null) {
                              _addBlock(BlockType.diagram);
                              _blockControllers.last.text = result;
                            }
                          },
                          icon: const Icon(
                            Icons.sports_esports,
                            color: Colors.greenAccent,
                          ),
                          tooltip: 'Tạo thế bi',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddBlockSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[950],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
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
              const SizedBox(height: 15),
              const Text(
                'CHỌN KHỐI NỘI DUNG CẦN THÊM',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 15),
              Expanded(
                child: ListView(
                  children: [
                    _buildBlockCategory('Nội dung cơ bản', [
                      _buildBlockItem(
                        icon: Icons.notes,
                        color: Colors.grey,
                        title: 'Đoạn văn (Text)',
                        desc: 'Văn bản mô tả thông thường',
                        onTap: () {
                          Navigator.pop(context);
                          _addBlock(BlockType.text);
                        },
                      ),
                      _buildBlockItem(
                        icon: Icons.playlist_add,
                        color: Colors.deepPurpleAccent,
                        title: 'Ý chính (List item)',
                        desc: 'Danh sách các ý chính có dấu gạch đầu dòng',
                        onTap: () {
                          Navigator.pop(context);
                          _addBlock(BlockType.item);
                        },
                      ),
                    ]),
                    _buildBlockCategory('Đồ họa & Cú đánh', [
                      _buildBlockItem(
                        icon: Icons.sports_esports,
                        color: Colors.greenAccent,
                        title: 'Phác thảo thế bi',
                        desc: 'Tạo vị trí các bi bida trên bàn chạy',
                        onTap: () async {
                          Navigator.pop(context);
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DiagramBuilderPage(),
                            ),
                          );
                          if (result != null) {
                            _addBlock(BlockType.diagram);
                            _blockControllers.last.text = result;
                          }
                        },
                      ),
                      _buildBlockItem(
                        icon: Icons.track_changes,
                        color: Colors.orangeAccent,
                        title: 'Chi tiết cú đánh',
                        desc: 'Độ dày chạm bi và hướng xoáy ép-phê',
                        onTap: () async {
                          Navigator.pop(context);
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ShotDetailBuilderPage(),
                            ),
                          );
                          if (result != null) {
                            _addBlock(BlockType.shotDetail);
                            _blockControllers.last.text = result;
                          }
                        },
                      ),
                      _buildBlockItem(
                        icon: Icons.circle_outlined,
                        color: Colors.cyanAccent,
                        title: 'Biểu đồ Ép-phê',
                        desc:
                            'Tạo sơ đồ đặt ép-phê với các số tùy chọn trên quả bi',
                        onTap: () async {
                          Navigator.pop(context);
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const EffetDiagramBuilderPage(),
                            ),
                          );
                          if (result != null) {
                            _addBlock(BlockType.effetDiagram);
                            _blockControllers.last.text = result;
                          }
                        },
                      ),
                    ]),
                    _buildBlockCategory('Định dạng nâng cao', [
                      _buildBlockItem(
                        icon: Icons.looks_one,
                        color: Colors.cyanAccent,
                        title: 'Tiêu đề lớn (Section)',
                        desc:
                            'Phần chương lớn chia bố cục bài viết (VD: 1. Tư thế đứng)',
                        onTap: () {
                          Navigator.pop(context);
                          _editSectionBlock(null);
                        },
                      ),
                      _buildBlockItem(
                        icon: Icons.looks_two,
                        color: Colors.blueAccent,
                        title: 'Tiêu đề nhỏ (SubSection)',
                        desc:
                            'Chương phụ chia nhỏ trong Section (VD: 1.1 Cầm cơ)',
                        onTap: () {
                          Navigator.pop(context);
                          _editSubSectionBlock(null);
                        },
                      ),
                      _buildBlockItem(
                        icon: Icons.title,
                        color: Colors.yellowAccent,
                        title: 'Tiêu đề phụ + Đoạn văn',
                        desc: 'Khối văn bản đi kèm tiêu đề phụ màu nổi bật',
                        onTap: () {
                          Navigator.pop(context);
                          _editHeadingTextBlock(null);
                        },
                      ),
                      _buildBlockItem(
                        icon: Icons.table_chart,
                        color: Colors.lightBlueAccent,
                        title: 'Bảng dữ liệu',
                        desc: 'Bảng thông số góc chạy, ép-phê định dạng lưới',
                        onTap: () {
                          Navigator.pop(context);
                          _editDataTableBlock(null);
                        },
                      ),
                      _buildBlockItem(
                        icon: Icons.lightbulb_outline,
                        color: Colors.amberAccent,
                        title: 'Hộp chú thích (Lưu ý)',
                        desc: 'Ghi chú đặc biệt (Gợi ý, Lưu ý, Cảnh báo...)',
                        onTap: () {
                          Navigator.pop(context);
                          _editIconTextBlock(null);
                        },
                      ),
                      _buildBlockItem(
                        icon: Icons.functions,
                        color: Colors.pinkAccent,
                        title: 'Khối công thức',
                        desc:
                            'Khung bao công thức đánh bôi đậm canh giữa (VD: TỔNG = ...)',
                        onTap: () {
                          Navigator.pop(context);
                          _editFormulaBlock(null);
                        },
                      ),
                    ]),
                    _buildBlockCategory('Đa phương tiện', [
                      _buildBlockItem(
                        icon: Icons.add_photo_alternate_outlined,
                        color: Colors.green,
                        title: 'Hình ảnh từ thiết bị',
                        desc: 'Chọn hình ảnh có sẵn trong thư viện máy',
                        onTap: () async {
                          Navigator.pop(context);
                          final ImagePicker picker = ImagePicker();
                          final XFile? image = await picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (image != null) {
                            await _addPickedImage(image);
                          }
                        },
                      ),
                      _buildBlockItem(
                        icon: Icons.link,
                        color: Colors.teal,
                        title: 'Hình ảnh từ link (URL)',
                        desc: 'Chèn link ảnh từ nguồn internet',
                        onTap: () {
                          Navigator.pop(context);
                          showDialog(
                            context: context,
                            builder: (context) {
                              final urlController = TextEditingController();
                              return AlertDialog(
                                backgroundColor: const Color(0xFF0F172A),
                                insetPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 24,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                title: const Text(
                                  'Thêm ảnh từ URL',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                content: SizedBox(
                                  width: MediaQuery.of(context).size.width,
                                  child: TextField(
                                    controller: urlController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: _dialogInputDecoration(
                                      'URL hình ảnh',
                                      hintText: 'https://...',
                                    ),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text(
                                      'Hủy',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      if (urlController.text.isNotEmpty) {
                                        _addBlock(BlockType.image);
                                        _blockControllers.last.text =
                                            ImageBlockData(
                                              source: urlController.text.trim(),
                                            ).encode();
                                      }
                                      Navigator.pop(context);
                                    },
                                    child: const Text(
                                      'Thêm',
                                      style: TextStyle(
                                        color: Colors.cyanAccent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                      _buildBlockItem(
                        icon: Icons.play_circle_filled,
                        color: Colors.redAccent,
                        title: 'Video Youtube',
                        desc: 'Chèn link hoặc ID video Youtube',
                        onTap: () {
                          Navigator.pop(context);
                          _editYoutubeBlock(null);
                        },
                      ),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBlockCategory(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.cyanAccent,
              letterSpacing: 1.0,
            ),
          ),
        ),
        ...children,
        const Divider(color: Colors.white10),
      ],
    );
  }

  Widget _buildBlockItem({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.15),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        desc,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      onTap: onTap,
    );
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    unawaited(_saveDraft());
    _titleController.dispose();
    _subtitleController.dispose();
    for (var controller in _blockControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
