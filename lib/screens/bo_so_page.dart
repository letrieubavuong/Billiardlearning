import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/note_repository.dart';
import '../widgets/article_blocks.dart';
import '../widgets/billiard_diagram.dart';
import '../models/note_model.dart';
import '../models/system_notes.dart';
import '../widgets/youtube_player_widget.dart';
import '../widgets/data_state_view.dart';
import '../widgets/note_search_field.dart';
import '../widgets/lesson_preview_card.dart';
import 'note_editor_page.dart';
import 'category_notes_state.dart';
import 'article_detail_page.dart';

class BoSoPage extends StatefulWidget {
  const BoSoPage({super.key, this.repository = const SqliteNoteRepository()});

  final NoteRepository repository;

  @override
  State<BoSoPage> createState() => BoSoPageState();
}

class BoSoPageState extends State<BoSoPage> with CategoryNotesState<BoSoPage> {
  @override
  NoteRepository get noteRepository => widget.repository;

  @override
  String get noteCategory => 'boso';

  List<ExpansionTileController> get _controllers => expansionControllers;
  List<Note> get _userSystems => filteredCategoryNotes;

  @override
  void initState() {
    super.initState();
    loadUserSystems();
  }

  Future<void> loadUserSystems() => loadCategoryNotes();

  Future<void> resetToDefaults() async {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Khôi phục mặc định'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa tất cả thay đổi và khôi phục các bộ số mẫu ban đầu không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await resetCategoryNotes(SystemDefaultNotes.getBoSoNotes());
                if (!mounted) return;
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Đã khôi phục các Bộ số mặc định!'),
                  ),
                );
              } catch (_) {
                if (!mounted) return;
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Không thể khôi phục dữ liệu. Vui lòng thử lại.',
                    ),
                  ),
                );
              }
            },
            child: const Text(
              'Khôi phục',
              style: TextStyle(color: Colors.orangeAccent),
            ),
          ),
        ],
      ),
    );
  }

  void addNewSystem() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NoteEditorPage()),
    );
    if (!mounted) return;
    if (result != null && result is Note) {
      addNewSystemWithNote(result);
    }
  }

  void addNewSystemWithNote(Note note) async {
    await insertCategoryNote(note);
  }

  void _onExpansionChanged(int index, bool expanded) {
    collapseOtherTiles(index, expanded);
  }

  Future<void> _openLesson(Note note) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArticleDetailPage(
          note: note,
          category: noteCategory,
          onUpdated: loadUserSystems,
          repository: noteRepository,
        ),
      ),
    );
    await loadUserSystems();
  }

  Future<void> _editLesson(Note note) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NoteEditorPage(note: note)),
    );
    if (result is Note) await updateCategoryNote(result);
  }

  Future<void> _confirmDeleteLesson(Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa bộ số'),
        content: Text('Bạn có chắc muốn xóa “${note.title}” không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed == true) await deleteCategoryNote(note);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Giữ màu nền chìm của HomePage
      body: DataStateView(
        isLoading: isLoadingNotes,
        error: notesLoadError,
        onRetry: loadUserSystems,
        child: ListView(
          children: [
            NoteSearchField(onChanged: updateNotesQuery),
            ...List.generate(_userSystems.length, (index) {
              final note = _userSystems[index];
              return LessonPreviewCard(
                note: note,
                accentColor: note.color,
                completed: isNoteCompleted(note),
                categoryLabel: 'Bộ số',
                onOpen: () => _openLesson(note),
                onToggleCompleted: () => toggleNoteCompleted(note),
                onEdit: () => _editLesson(note),
                onDelete: () => _confirmDeleteLesson(note),
              );
            }),
          ],
        ),
      ),
    );
  }

  // --- HÀM RENDER CÁC BLOCK DO NGƯỜI DÙNG SOẠN THẢO ---
  Widget _buildUserSystemArticle({
    required int controllerIndex,
    required int userIndex,
    required Note note,
  }) {
    List<Widget> contentWidgets = note.blocks.map((block) {
      if (block.type == BlockType.text) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            block.content,
            style: const TextStyle(fontSize: 15),
            textAlign: TextAlign.justify,
          ),
        );
      }
      if (block.type == BlockType.item) {
        List<String> lines = block.content.split('\n');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: lines.map((line) {
            String cleanLine = line;
            if (cleanLine.startsWith('• ')) {
              cleanLine = cleanLine.substring(2);
            } else if (cleanLine.startsWith('•')) {
              cleanLine = cleanLine.substring(1);
            }
            if (cleanLine.trim().isEmpty) return const SizedBox();
            return ArticleBlocks.iconText(
              Icons.fiber_manual_record,
              note.color,
              cleanLine,
              bottomPadding: 6.0,
            );
          }).toList(),
        );
      }
      if (block.type == BlockType.image) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: block.content.startsWith('http')
                ? Image.network(block.content)
                : Image.file(File(block.content)),
          ),
        );
      }
      if (block.type == BlockType.diagram) {
        Map<String, dynamic> data;
        try {
          data = jsonDecode(block.content);
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
                      ((g['rotation'] ?? 0.0) as double) * math.pi / 180.0,
                  text: g['number']?.toString(),
                ),
              );
            }
          }
        }
        TableViewType vType = TableViewType.values[data['viewType'] ?? 0];
        DiagramSystem sys = DiagramSystem.values[data['system'] ?? 0];

        List<BallPath> paths = [];
        if (data.containsKey('paths')) {
          var p = data['paths'];
          if (p['white'] != null && (p['white'] as List).isNotEmpty) {
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
          if (p['yellow'] != null && (p['yellow'] as List).isNotEmpty) {
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
          if (p['red'] != null && (p['red'] as List).isNotEmpty) {
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
          if (p['free'] != null && (p['free'] as List).isNotEmpty) {
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
            (data['labelFontSize'] as num?)?.toDouble() ?? 9.5;
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
                  color: Color(l['color'] ?? Colors.yellowAccent.value),
                  fontSize: labelFontSize,
                  rotation:
                      ((l['rotation'] ?? 0.0) as double) * math.pi / 180.0,
                ),
              );
            }
          }
        }

        return ArticleBlocks.diagram(
          viewType: vType,
          system: sys,
          isVertical: true,
          balls: balls,
          paths: paths,
          labels: labels,
        );
      }
      if (block.type == BlockType.shotDetail) {
        Map<String, dynamic> data;
        try {
          data = jsonDecode(block.content);
        } catch (e) {
          data = {
            "thickness": 0.5,
            "effet": [0.0, 0.0],
          };
        }
        return ArticleBlocks.details(
          thickness: (data['thickness'] ?? 0.5).toDouble(),
          effet: Offset(
            (data['effet']?[0] ?? 0.0).toDouble(),
            (data['effet']?[1] ?? 0.0).toDouble(),
          ),
          forceImage: data['forceImage']?.toString(),
          cueAngle: (data['cueAngle'] ?? 0.0).toDouble(),
        );
      }
      if (block.type == BlockType.effetDiagram) {
        dynamic blockData;
        try {
          blockData = jsonDecode(block.content);
        } catch (_) {}
        return ArticleBlocks.effetDiagram(blockData ?? []);
      }
      if (block.type == BlockType.section) {
        Map<String, dynamic> data;
        try {
          data = jsonDecode(block.content);
        } catch (e) {
          data = {};
        }
        final blockColor = data['colorVal'] != null
            ? Color(data['colorVal'])
            : note.color;
        return ArticleBlocks.section(
          data['number'] ?? 1,
          data['title'] ?? '',
          blockColor,
          text: data['text'] != null && data['text'].toString().isNotEmpty
              ? data['text'].toString()
              : null,
        );
      }
      if (block.type == BlockType.subSection) {
        Map<String, dynamic> data;
        try {
          data = jsonDecode(block.content);
        } catch (e) {
          data = {};
        }
        final blockColor = data['colorVal'] != null
            ? Color(data['colorVal'])
            : note.color;
        return ArticleBlocks.subSection(
          data['title'] ?? '',
          blockColor,
          text: data['text'] != null && data['text'].toString().isNotEmpty
              ? data['text'].toString()
              : null,
        );
      }
      if (block.type == BlockType.headingText) {
        Map<String, dynamic> data;
        try {
          data = jsonDecode(block.content);
        } catch (e) {
          data = {};
        }
        return ArticleBlocks.text(data['heading'] ?? '', data['text'] ?? '');
      }
      if (block.type == BlockType.dataTable) {
        Map<String, dynamic> data;
        try {
          data = jsonDecode(block.content);
        } catch (e) {
          data = {};
        }
        List<List<String>> tableData = [];
        if (data.containsKey('data') && data['data'] is List) {
          for (var row in data['data']) {
            if (row is List) {
              tableData.add(row.map((e) => e.toString()).toList());
            }
          }
        }
        if (tableData.isEmpty) {
          tableData = [
            ['Không có dữ liệu'],
          ];
        }
        return ArticleBlocks.dataTable(
          tableData,
          headerColor: note.color.withOpacity(0.3),
        );
      }
      if (block.type == BlockType.iconText) {
        Map<String, dynamic> data;
        try {
          data = jsonDecode(block.content);
        } catch (e) {
          data = {};
        }
        int iconCode = data['iconCode'] ?? Icons.lightbulb.codePoint;
        int colorVal = data['colorVal'] ?? Colors.amber.value;
        return ArticleBlocks.iconText(
          NoteIconHelper.getIcon(iconCode),
          Color(colorVal),
          data['text'] ?? '',
        );
      }
      if (block.type == BlockType.youtube) {
        String videoId = block.content;
        int? startSeconds;
        int? endSeconds;
        if (block.content.startsWith('{') && block.content.endsWith('}')) {
          try {
            final data = jsonDecode(block.content);
            videoId = data['videoId'] ?? '';
            startSeconds = data['startSeconds'];
            endSeconds = data['endSeconds'];
          } catch (_) {}
        }
        return YoutubePlayerWidget(
          videoId: videoId,
          startSeconds: startSeconds,
          endSeconds: endSeconds,
        );
      }
      if (block.type == BlockType.formula) {
        return ArticleBlocks.formula(block.content, note.color);
      }
      return const SizedBox();
    }).toList();

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.cyanAccent.withOpacity(0.5)),
        ),
      ),
      child: ExpansionTile(
        key: ValueKey('boso_${note.id ?? note.title}'),
        tilePadding: const EdgeInsets.only(left: 12.0, right: 4.0),
        controller: _controllers[controllerIndex],
        onExpansionChanged: (val) => _onExpansionChanged(controllerIndex, val),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                note.color.withOpacity(0.18),
                note.color.withOpacity(0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: note.color.withOpacity(0.35), width: 1.2),
          ),
          child: Icon(Icons.grid_4x4_rounded, color: note.color, size: 22),
        ),
        title: Text(
          note.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
          textAlign: TextAlign.justify,
        ),
        subtitle: Text(
          note.subtitle.isNotEmpty ? note.subtitle : 'Bộ số cá nhân do bạn tạo',
          style: const TextStyle(fontSize: 12, color: Colors.cyanAccent),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.grey),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onSelected: (value) async {
            if (value == 'complete') {
              await toggleNoteCompleted(note);
            } else if (value == 'edit') {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NoteEditorPage(note: note),
                ),
              );
              if (result != null && result is Note) {
                await updateCategoryNote(result);
              }
            } else if (value == 'delete') {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Xóa bài viết'),
                  content: const Text(
                    'Bạn có chắc chắn muốn xóa bộ số này không?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Hủy'),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        if (note.id != null) {
                          await deleteCategoryNote(note);
                        }
                      },
                      child: const Text(
                        'Xóa',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              );
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'complete',
              child: Row(
                children: [
                  Icon(
                    isNoteCompleted(note)
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: Colors.greenAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isNoteCompleted(note) ? 'Đã học xong' : 'Đánh dấu đã học',
                  ),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.blueAccent, size: 20),
                  SizedBox(width: 8),
                  Text('Chỉnh sửa'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.redAccent, size: 20),
                  SizedBox(width: 8),
                  Text('Xóa', style: TextStyle(color: Colors.redAccent)),
                ],
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4.0, 8.0, 4.0, 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: contentWidgets,
            ),
          ),
        ],
      ),
    );
  }
}
