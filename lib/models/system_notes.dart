import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/note_model.dart';
import '../widgets/billiard_diagram.dart';

class SystemDefaultNotes {
  static List<Note> getCoBanNotes() {
    return [
      Note(
        title: 'TƯ THẾ & CẦM CƠ',
        subtitle: 'Nền tảng của mọi cú đánh chính xác',
        color: Colors.green,
        date: DateTime.now(),
        blocks: [
          NoteBlock(
            type: BlockType.section,
            content: jsonEncode({
              'number': 1,
              'title': 'Tư thế đứng (Stance)',
              'text':
                  'Một tư thế đứng tốt là cần thiết để tối ưu hóa cơ chế đánh và động tác của người chơi. Đáng tiếc là rất khó để định nghĩa một tư thế chuẩn tuyệt đối. Tuy nhiên, các nội dung trong chương này sẽ giúp hình dung rõ hơn về một tư thế tạm gọi là lý tưởng.',
            }),
          ),
          NoteBlock(
            type: BlockType.text,
            content:
                '1.1 CẢM THẤY THOẢI MÁI VÀ CÓ SỰ ỔN ĐỊNH HOÀN HẢO\nNgười chơi mới bắt đầu cần tìm kiếm một tư thế mang lại cảm giác thoải mái và giữ thăng bằng tốt nhất để cú vung cơ đạt độ thẳng mượt mong muốn.',
          ),
          NoteBlock(
            type: BlockType.iconText,
            content: jsonEncode({
              'icon': Icons.accessibility_new.codePoint,
              'color': Colors.green.value,
              'text': 'Giữ lưng thẳng và thoải mái, không nên gồng cứng người.',
            }),
          ),
          NoteBlock(
            type: BlockType.section,
            content: jsonEncode({
              'number': 2,
              'title': 'Cách cầm cơ (Grip)',
              'text':
                  'Cầm cơ lỏng tay bằng các ngón tay, không nắm chặt bằng cả lòng bàn tay để tránh làm lệch hướng ngắm khi ra cơ lực mạnh.',
            }),
          ),
        ],
      ),
      Note(
        title: 'ĐỘNG TÁC RA CƠ',
        subtitle: 'Quyết định độ chính xác cú đánh',
        color: Colors.teal,
        date: DateTime.now(),
        blocks: [
          NoteBlock(
            type: BlockType.section,
            content: jsonEncode({
              'number': 1,
              'title': 'ĐỊNH NGHĨA',
              'text':
                  'Động tác ra cơ là chuyển động của cây cơ truyền năng lượng cần thiết vào bi chủ. Nhịp đẩy cơ thẳng, dứt khoát quyết định 90% sự thành bại của cú đánh.',
            }),
          ),
          NoteBlock(
            type: BlockType.iconText,
            content: jsonEncode({
              'icon': Icons.lightbulb.codePoint,
              'color': Colors.amber.value,
              'text':
                  'Rất chính xác: Đầu cơ luôn quay trở lại vị trí cực kỳ gần bi chủ sau khi nhấp cơ.',
            }),
          ),
          NoteBlock(
            type: BlockType.shotDetail,
            content: jsonEncode({
              'thickness': 0.125,
              'effet': [-0.4, -0.75],
              'cueAngle': 0.0,
              'forceImage': 'assets/images/Luc 2.png',
            }),
          ),
        ],
      ),
      Note(
        title: 'KỸ THUẬT TRÔ KÉO',
        subtitle: 'Nền tảng quan trọng nhất để tạo series',
        color: Colors.redAccent,
        date: DateTime.now(),
        blocks: [
          NoteBlock(
            type: BlockType.section,
            content: jsonEncode({
              'number': 1,
              'title': 'Nguyên lý',
              'text':
                  'Trô kéo gom bi là việc sử dụng độ xoáy ngược (tầng dưới tâm bi chủ) để điều khiển bi chủ quay về sau khi chạm bi carde.',
            }),
          ),
          NoteBlock(
            type: BlockType.iconText,
            content: jsonEncode({
              'icon': Icons.note_add.codePoint,
              'color': Colors.orange.value,
              'text':
                  'Lưu ý: Khoảng cách giữa bi chủ và bi carde không nên quá 2 nút để tối ưu độ xoáy giật về.',
            }),
          ),
          NoteBlock(
            type: BlockType.text,
            content:
                '1.1 Trô kéo góc 22 độ\nChạm dày 7/8 bi, tầng bi mức 1. Bi chủ quay về gần như thẳng hàng.',
          ),
          NoteBlock(
            type: BlockType.diagram,
            content: jsonEncode({
              'white': [1.0, 0.5],
              'yellow': [1.0, 1.5],
              'red': [
                0.516,
                0.344,
              ], // ~ 3 * Ball.diameter (0.172*3) = 0.516, 2 * Ball.diameter (0.172*2) = 0.344
              'viewType': TableViewType.quarter.index,
              'system': DiagramSystem.standard.index,
              'paths': {
                'white': [
                  [1.0, 1.5],
                  [0.516, 0.344],
                ],
              },
              'labels': [],
            }),
          ),
          NoteBlock(
            type: BlockType.shotDetail,
            content: jsonEncode({
              'thickness': 0.85,
              'effet': [0.0, 0.6],
              'cueAngle': 10.0,
              'forceImage': 'assets/images/Luc 2.png',
            }),
          ),
          NoteBlock(
            type: BlockType.text,
            content:
                '1.2 Trô kéo góc 45 độ\nChạm dày 3/4 bi carde, tầng bi dưới tâm.',
          ),
          NoteBlock(
            type: BlockType.diagram,
            content: jsonEncode({
              'white': [2.0, 1.0],
              'yellow': [2.0, 1.5],
              'red': [1.0, 0.5],
              'viewType': TableViewType.quarter.index,
              'system': DiagramSystem.standard.index,
              'paths': {
                'white': [
                  [2.0, 1.5],
                  [1.0, 0.5],
                ],
              },
              'labels': [],
            }),
          ),
          NoteBlock(
            type: BlockType.shotDetail,
            content: jsonEncode({
              'thickness': 0.75,
              'effet': [0.0, 0.6],
              'cueAngle': 10.0,
              'forceImage': 'assets/images/Luc 2.png',
            }),
          ),
        ],
      ),
      Note(
        title: 'CÁC CÚ ĐÁNH CĂN BẢN',
        subtitle: 'Stun, Draw và Follow shots',
        color: Colors.lightGreen,
        date: DateTime.now(),
        blocks: [
          NoteBlock(
            type: BlockType.section,
            content: jsonEncode({
              'number': 1,
              'title': 'Cú đánh Chuẩn (Stun Shot)',
              'text':
                  'Đánh vào tâm bi chủ với lực vừa đủ để bi chủ trượt đi và dừng lại nhanh sau khi chạm bi carde.',
            }),
          ),
          NoteBlock(
            type: BlockType.section,
            content: jsonEncode({
              'number': 2,
              'title': 'Kỹ thuật Trô bi (Draw Shot)',
              'text':
                  'Đánh vào phần dưới tâm bi chủ để tạo xoáy ngược giật về sau khi va chạm.',
            }),
          ),
          NoteBlock(
            type: BlockType.section,
            content: jsonEncode({
              'number': 3,
              'title': 'Kỹ thuật Cule (Follow Shot)',
              'text':
                  'Đánh vào phần trên tâm bi chủ để bi chủ lăn thẳng tiếp tục tiến lên phía trước sau khi chạm bi carde.',
            }),
          ),
        ],
      ),
      Note(
        title: 'KỸ THUẬT MASSE',
        subtitle: 'Tạo đường cong biến ảo',
        color: Colors.blueGrey,
        date: DateTime.now(),
        blocks: [
          NoteBlock(
            type: BlockType.section,
            content: jsonEncode({
              'number': 1,
              'title': 'Nguyên lý',
              'text':
                  'Dựng đứng cơ một góc nghiêng lớn và đánh vào phía trên mép bi chủ để tạo lực xoay ép lượn vòng cong lách qua các bi cản trở.',
            }),
          ),
          NoteBlock(
            type: BlockType.iconText,
            content: jsonEncode({
              'icon': Icons.warning_amber.codePoint,
              'color': Colors.orange.value,
              'text':
                  'Lưu ý: Masse rất dễ làm xước hoặc rách vải bàn bida nếu thực hiện kỹ thuật sai góc đứng cơ.',
            }),
          ),
        ],
      ),
    ];
  }

  static List<Note> getBoSoNotes() {
    return [
      Note(
        title: 'BỘ SỐ 50 (DIAMOND SYSTEM)',
        subtitle: 'Hệ thống căn bản nhất của bida 3 băng',
        color: Colors.cyan,
        date: DateTime.now(),
        blocks: [
          NoteBlock(
            type: BlockType.section,
            content: jsonEncode({
              'number': 1,
              'title': 'Giới thiệu',
              'text':
                  'Bộ số 50 (Hệ thống Kim cương) là "kinh thánh" đối với mọi cơ thủ bida 3 băng. Đây là hệ thống dùng để tính toán đường chạy của bi chủ sau khi chạm 3 băng dài.',
            }),
          ),
          NoteBlock(
            type: BlockType.diagram,
            content: jsonEncode({
              'white': [1.0, 1.0],
              'viewType': TableViewType.full.index,
              'system': DiagramSystem.diamond.index,
              'paths': {
                'white': [
                  [0.375, 0.0],
                  [1.0, 0.4],
                  [0.0, 1.0],
                ],
              },
              'labels': [],
            }),
          ),
          NoteBlock(
            type: BlockType.headingText,
            content: jsonEncode({
              'text': 'Đầu 50 - Chạm 30 = Trúng 20',
              'color': Colors.cyan.value,
            }),
          ),
          NoteBlock(
            type: BlockType.iconText,
            content: jsonEncode({
              'iconCode': Icons.lightbulb.codePoint,
              'colorVal': Colors.amber.value,
              'text':
                  'Mẹo: Luôn kiểm tra độ nảy của bàn trước khi áp dụng hệ số bù trừ.',
            }),
          ),
          NoteBlock(
            type: BlockType.shotDetail,
            content: jsonEncode({
              'thickness': 0.0,
              'effet': [0.5, 0.0],
              'cueAngle': 0.0,
              'forceImage': 'assets/images/Luc 2.png',
            }),
          ),
        ],
      ),
      Note(
        title: 'BỘ SỐ 3 BĂNG CHA (ĐỖ NHÂN)',
        subtitle: 'Kỹ thuật gom bi đỉnh cao theo Đỗ Nhân',
        color: Colors.blue,
        date: DateTime.now(),
        blocks: [
          NoteBlock(
            type: BlockType.section,
            content: jsonEncode({
              'number': 1,
              'title': 'Nguyên lý Hệ thống 3 Băng Cha',
              'text':
                  'Hệ thống 3 băng cha được sử dụng cho những thế bi có góc lớn, vị trí bi vượt qua khỏi giữa bàn (qua nút số 8). Công thức: Tổng Độ Lệch = Vị trí bi đỏ (Carde) + Độ xiên bi chủ + Điểm trúng băng thứ 3.',
            }),
          ),
          NoteBlock(
            type: BlockType.diagram,
            content: jsonEncode({
              'white': [2.5, 5.0],
              'yellow': [2.0, 1.0],
              'red': [4.0, 4.0],
              'viewType': TableViewType.full.index,
              'system': DiagramSystem.babangcha.index,
              'paths': {
                'white': [
                  [0.0, 2.5],
                  [1.5, 0.0],
                  [1.0, 2.0],
                ],
              },
              'labels': [],
            }),
          ),
          NoteBlock(
            type: BlockType.shotDetail,
            content: jsonEncode({
              'thickness': 0.75,
              'effet': [0.8, 0.0], // 2 ép phê ngang
              'cueAngle': 0.0,
              'forceImage': 'assets/images/Luc 2.png',
            }),
          ),
        ],
      ),
      Note(
        title: 'BỘ SỐ XỔ NGẮN - DÀI - NGẮN',
        subtitle: 'Kỹ thuật xổ từ băng ngắn qua băng dài',
        color: Colors.orange,
        date: DateTime.now(),
        blocks: [
          NoteBlock(
            type: BlockType.section,
            content: jsonEncode({
              'number': 1,
              'title': 'Quy ước nút số',
              'text':
                  '• Băng ngắn trên (Đầu): 1, 2, 3, 4, 5 (Vàng).\n• Băng ngắn dưới (Đích): 0, 1, 2, 3, 4 (Trắng).',
            }),
          ),
          NoteBlock(
            type: BlockType.diagram,
            content: jsonEncode({
              'white': [0.5, 0.05],
              'viewType': TableViewType.full.index,
              'system': DiagramSystem.shortLongShort.index,
              'paths': {
                'white': [
                  [1.0, 0.5],
                  [0.5, 1.0],
                ],
              },
              'labels': [],
            }),
          ),
          NoteBlock(
            type: BlockType.headingText,
            content: jsonEncode({
              'text': 'Điểm Chạm = Điểm Đầu - Điểm Trúng',
              'color': Colors.orange.value,
            }),
          ),
          NoteBlock(
            type: BlockType.text,
            content:
                'Cách tính\nVí dụ bi chủ ở vị trí nút số 3 (Vàng), bạn muốn trúng ở nút số 1 (Trắng) ở băng dưới, hãy ngắm vào điểm tương ứng 2 đơn vị trên băng dài.',
          ),
        ],
      ),
      Note(
        title: 'BỘ SỐ XỔ 2 BĂNG',
        subtitle: 'Kỹ thuật xổ nhanh 2 băng',
        color: Colors.deepOrange,
        date: DateTime.now(),
        blocks: [
          NoteBlock(
            type: BlockType.section,
            content: jsonEncode({
              'number': 1,
              'title': 'Mục đích',
              'text':
                  'Trong bida libre cũng như 3 băng, đây là một thế bi không đơn giản.',
            }),
          ),
          NoteBlock(
            type: BlockType.diagram,
            content: jsonEncode({
              'white': [1.25, 5.0],
              'yellow': [2.0, 2.0],
              'red': [1.0, 8.0 - 0.172], // Ball.diameter is ~ 0.172
              'viewType': TableViewType.full.index,
              'system': DiagramSystem.xohaibang.index,
              'paths': {
                'white': [
                  [2.0 - 0.5 * 0.172, 2.0],
                  [2.0 - 3.0 * 0.172, 0.0],
                  [0.0, 7.0],
                  [1.0 - 0.172, 8.0],
                ],
                'yellow': [
                  [2.0, 8.0],
                ],
                'red': [
                  [0.5, 8.0],
                ],
              },
              'labels': [
                {
                  'x': 2.0,
                  'y': 0.0 + 0.172,
                  'text': 'Vị trí bi Carde',
                  'color': Colors.yellow.value,
                },
                {
                  'x': 2.0,
                  'y': 8.0 - 0.172,
                  'text': 'Điểm trúng',
                  'color': Colors.white.value,
                },
                {
                  'x': 0.172,
                  'y': 4.0 + 0.172,
                  'text': 'Điểm trúng trên băng dài',
                  'color': Colors.yellow.value,
                },
                {
                  'x': 2.0,
                  'y': 6.0,
                  'text': 'Total = VT Bi Carde + Độ xiên + Điểm trúng',
                  'color': Colors.white.value,
                },
              ],
            }),
          ),
          NoteBlock(
            type: BlockType.headingText,
            content: jsonEncode({
              'text': 'Tính theo góc đối xứng',
              'color': Colors.deepOrange.value,
            }),
          ),
          NoteBlock(
            type: BlockType.iconText,
            content: jsonEncode({
              'iconCode': Icons.lightbulb.codePoint,
              'colorVal': Colors.amber.value,
              'text':
                  'Lưu ý: Độ nảy của băng ảnh hưởng rất lớn đến độ chính xác của cú xổ 2 băng.',
            }),
          ),
        ],
      ),
      Note(
        title: 'BỘ SỐ CANH 1 BĂNG (ĐỖ NHÂN)',
        subtitle: 'Kỹ thuật gom dậu kinh điển của Đỗ Nhân',
        color: Colors.blueGrey,
        date: DateTime.now(),
        blocks: [
          NoteBlock(
            type: BlockType.section,
            content: jsonEncode({
              'number': 1,
              'title': 'Nguyên lý gom dậu (Lùi mặt bi)',
              'text':
                  'Dựa vào trung điểm M giữa bi carde và vị trí mong muốn của bi đỏ để tính toán điểm ngắm song song, kết hợp các mức áp-phê và lực nhằm đưa cả 2 bi về khu vực dậu.',
            }),
          ),
          NoteBlock(
            type: BlockType.diagram,
            content: jsonEncode({
              'white': [2.5, 5.0],
              'yellow': [2.0, 1.0],
              'red': [3.5, 2.5],
              'viewType': TableViewType.full.index,
              'system': DiagramSystem.standard.index,
              'paths': {
                'white': [
                  [2.5, 1.5],
                  [3.8, 3.8],
                ],
                'yellow': [
                  [2.4, 2.9],
                  [4.0, 2.1],
                ],
              },
              'labels': [
                {
                  'x': 2.5,
                  'y': 2.2,
                  'text': 'Tia song song lùi 1.5 nút (đánh 1/2)',
                  'color': Colors.yellow.value,
                },
              ],
            }),
          ),
          NoteBlock(
            type: BlockType.section,
            content: jsonEncode({
              'number': 2,
              'title': 'Cách tính Tổng độ lệch thực tế',
              'text':
                  'Điểm Ngắm Cuối = Trung Điểm (M) - Khoảng lùi theo mặt bi.\n• Ví dụ: Trung điểm ở nút 4, đánh 1/2 trái bi -> Ngắm vào nút 4 - 1.5 = 2.5.',
            }),
          ),
          NoteBlock(
            type: BlockType.subSection,
            content: jsonEncode({
              'title': '2.1 Bảng phối hợp kỹ thuật gom dậu',
            }),
          ),
          NoteBlock(
            type: BlockType.dataTable,
            content: jsonEncode({
              'data': [
                ['MỤC TIÊU', 'CHẠM BI', 'ÉP-PHÊ', 'LỰC ĐÁNH'],
                ['Gom dậu chuẩn', '1/2', '2.0 EF', 'Lực 2.0'],
                ['Điều bi đỏ dài', '1/4', '3.0 EF', 'Lực 1.5'],
                ['Gom dậu hẹp', '3/4', '1.0 EF', 'Lực 2.5'],
              ],
            }),
          ),
          NoteBlock(
            type: BlockType.shotDetail,
            content: jsonEncode({
              'thickness': 0.5,
              'effet': [0.7, 0.0],
              'cueAngle': 0.0,
              'forceImage': 'assets/images/Luc 2.png',
            }),
          ),
          NoteBlock(
            type: BlockType.iconText,
            content: jsonEncode({
              'iconCode': Icons.lightbulb.codePoint,
              'colorVal': Colors.amber.value,
              'text':
                  'Lưu ý Đỗ Nhân: Ép-phê thuận làm tăng độ văng (phải lùi thêm), ép-phê nghịch làm giảm độ văng (lùi ít lại).',
            }),
          ),
        ],
      ),
      Note(
        title: 'BỘ NÚT SỐ BOLA 12',
        subtitle: 'Hệ thống chạm trái và ép phê hiện đại Hàn Quốc & Châu Âu',
        color: Colors.deepPurple,
        date: DateTime.now(),
        blocks: [
          NoteBlock(
            type: BlockType.section,
            content: jsonEncode({
              'number': 1,
              'title': 'Khái niệm chạm trái & Ép phê',
              'text':
                  'Bộ nút số Bola 12 tập trung vào 2 yếu tố cốt lõi: Độ dày mỏng khi chạm trái (chia bi carde thành 12 phần bằng nhau) và lượng Ép-phê (chia thành 9 mức từ 2 đến 9). Sự kết hợp này mang lại đường chạy chính xác mà không cần bắt tia phức tạp.',
            }),
          ),
          NoteBlock(
            type: BlockType.dataTable,
            content: jsonEncode({
              'data': [
                [
                  'CHẠM TRÁI (1-12)',
                  'Ý NGHĨA THỰC TẾ',
                  'ÉP-PHÊ (2-9)',
                  'QUY ƯỚC XOÁY',
                ],
                ['Chạm 6', 'Nửa trái bi (1/2)', 'Mức 2', 'Ép-phê nghịch (-1)'],
                [
                  'Chạm 12',
                  'Nguyên trái bi (1/1)',
                  'Mức 3 - 5',
                  'Ép-phê thuận ít',
                ],
                [
                  'Chạm 4',
                  'Một phần ba bi (1/3)',
                  'Mức 6 - 9',
                  'Ép-phê thuận nhiều',
                ],
              ],
            }),
          ),
          NoteBlock(
            type: BlockType.section,
            content: jsonEncode({
              'number': 2,
              'title': 'Áp dụng thế bi 3 băng cha (Ngắn - Dài - Ngắn)',
              'text':
                  'Áp dụng cho thế bi sườn dài chạy 3 băng khuôn chạm băng ngắn trước.\n\nCông thức:\nTổng = Vị trí bi chủ + Vị trí bi carde + Điểm trúng\n\nSau khi tính ra Tổng, ta chọn chạm trái và ép-phê sao cho: Chạm bi + Ép-phê = Tổng.\n\n• Vị trí bi chủ: Giao điểm của tia ngắm (nối từ bi chủ qua mép bi carde) cắt băng dài gần bi chủ.\n• Vị trí bi carde: Giao điểm của tia ngắm cắt băng ngắn đối diện.\n• Điểm trúng: Điểm chạm mong muốn trên băng ngắn thứ 3.',
            }),
          ),
          NoteBlock(
            type: BlockType.diagram,
            content: jsonEncode({
              'white': [3.0, 1.0],
              'yellow': [4.0, 2.0],
              'red': [2.0, 3.0],
              'viewType': TableViewType.full.index,
              'system': DiagramSystem.standard.index,
              'paths': {
                'white': [
                  [3.0, 1.0],
                  [4.0, 2.0],
                  [0.0, 3.0],
                  [2.0, 4.0],
                ],
              },
              'labels': [
                {
                  'x': 3.0,
                  'y': 1.0,
                  'text': 'Chủ (3)',
                  'color': Colors.white.value,
                },
                {
                  'x': 4.0,
                  'y': 2.0,
                  'text': 'Carde (4)',
                  'color': Colors.yellow.value,
                },
              ],
            }),
          ),
          NoteBlock(
            type: BlockType.headingText,
            content: jsonEncode({
              'text':
                  'Ví dụ: Chủ 3 + Carde 4 + Trúng 6 = Tổng 13 => Chạm 6 + Ép-phê 7',
              'color': Colors.deepPurple.value,
            }),
          ),
          NoteBlock(
            type: BlockType.section,
            content: jsonEncode({
              'number': 3,
              'title': 'Áp dụng thế bi 3 băng con (Dài - Ngắn - Dài)',
              'text':
                  'Áp dụng cho nhóm hình góc nhỏ 3 băng con.\n\nCông thức:\nTổng = Vị trí bi Carde + Độ lệch bi (x2) + Điểm trúng - Điểm hở băng\n\n• Độ lệch bi: Đo khoảng cách lệch giữa bi chủ và bi carde theo chiều ngang rồi nhân 2 (mang giá trị dương hoặc âm tùy hướng nghiêng).\n• Điểm hở băng: Số nút cách băng dài của bi carde.',
            }),
          ),
          NoteBlock(
            type: BlockType.headingText,
            content: jsonEncode({
              'text':
                  'Ví dụ: Carde 4 + Lệch 0 + Trúng 4 = Tổng 8 => Chạm 4 + Ép-phê 4',
              'color': Colors.deepPurple.value,
            }),
          ),
          NoteBlock(
            type: BlockType.shotDetail,
            content: jsonEncode({
              'thickness': 0.5,
              'effet': [0.75, 0.0],
              'cueAngle': 0.0,
            }),
          ),
        ],
      ),
    ];
  }

  static List<Note> getGomBiNotes() {
    return [
      Note(
        title: 'CÁC THẾ ĐIỀU BI',
        subtitle: 'Kỹ thuật điều hướng bi mục tiêu về vị trí định sẵn',
        color: Colors.blueGrey,
        date: DateTime.now(),
        blocks: [
          NoteBlock(
            type: BlockType.section,
            content: jsonEncode({
              'number': 1,
              'title': 'ĐỊNH NGHĨA VÀ TỔNG QUAN',
              'text':
                  'Thực tế, chúng ta chỉ tìm thấy hai dạng cú đánh cơ bản: cú đánh gom bi và cú đánh điều bi.',
            }),
          ),
          NoteBlock(
            type: BlockType.iconText,
            content: jsonEncode({
              'icon': Icons.lightbulb.codePoint,
              'color': Colors.amber.value,
              'text':
                  'Bi carde: Là bi bị bi chủ chạm trúng trực tiếp đầu tiên.',
            }),
          ),
          NoteBlock(
            type: BlockType.diagram,
            content: jsonEncode({
              'white': [1.5, 0.43], // 2.5 * Ball.diameter (0.172*2.5) ~ 0.43
              'yellow': [1.0, 1.0],
              'red': [2.0, 1.0],
              'viewType': TableViewType.quarter.index,
              'system': DiagramSystem.standard.index,
              'paths': {
                'white': [
                  [1.0, 1.0],
                  [2.0, 1.0],
                ],
              },
              'labels': [],
            }),
          ),
        ],
      ),
      Note(
        title: 'KỸ THUẬT GOM AMORTI',
        subtitle: 'Cú đánh giảm lực giảm độ nảy của bi chủ',
        color: Colors.indigo,
        date: DateTime.now(),
        blocks: [
          NoteBlock(
            type: BlockType.section,
            content: jsonEncode({
              'number': 1,
              'title': 'Giới thiệu',
              'text':
                  'Kỹ thuật chạm nhẹ hãm lực (Amorti) giúp bi chủ dừng lại ngay sát bi mục tiêu thứ hai trong khi truyền toàn bộ động lượng để bi mục tiêu thứ nhất chạy giáp vòng bàn quay về vị trí gom bi.',
            }),
          ),
        ],
      ),
      Note(
        title: 'CÁC THẾ GOM DỌC BĂNG',
        subtitle: 'Đường gom bi kinh điển dọc theo thành băng bida',
        color: Colors.deepPurple,
        date: DateTime.now(),
        blocks: [
          NoteBlock(
            type: BlockType.section,
            content: jsonEncode({
              'number': 1,
              'title': 'Đặc điểm',
              'text':
                  'Gom bi dọc băng tận dụng việc va chạm băng để ép hai bi mục tiêu dồn tụ lại một vùng nhỏ ở góc bàn bida.',
            }),
          ),
        ],
      ),
    ];
  }
}
