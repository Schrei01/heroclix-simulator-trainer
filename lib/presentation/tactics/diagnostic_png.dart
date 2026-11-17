import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

import '../../application/board/board_session.dart';
import '../../domain/board/board_viewport.dart';
import '../../domain/board/cell_coordinate.dart';
import '../../domain/characters/character.dart';
import '../../domain/characters/character_repository.dart';
import '../../domain/characters/team.dart';
import '../../domain/tactics/tactical_diagnostic.dart';
import '../../domain/rules/line_of_sight.dart';
import '../editor/board_painter.dart';
import 'tactical_map_painter.dart';

BoardSession publicDiagnosticBoard(BoardSession original) {
  final teams = <Team>[];
  for (var i = 0; i < original.teams.length; i++) {
    final t = original.teams[i];
    teams.add(
      Team(
        id: t.id,
        code: 'T${i + 1}',
        name: 'Equipo ${i + 1}',
        color: t.color,
        pattern: t.pattern,
      ),
    );
  }
  var figures = const CharacterRepository.empty();
  for (var i = 0; i < original.characters.length; i++) {
    final f = original.characters.all.elementAt(i), d = f.data;
    figures = figures.add(
      Character(
        id: f.id,
        label: CellCoordinate.columnLabel(i),
        data: CharacterDraft(
          name: 'Figura ${i + 1}',
          teamId: d.teamId,
          position: d.position,
          footprint: d.footprint,
          speed: d.speed,
          range: d.range,
          abilities: d.abilities,
          movementAbilities: d.movementAbilities,
          size: d.size,
        ),
      ),
      original.dimensions,
    );
  }
  return BoardSession.restore(
    dimensions: original.dimensions,
    teams: teams,
    characters: figures,
    terrain: original.terrain,
    walls: original.walls,
    nextCharacter: original.nextCharacter,
    nextTeam: original.nextTeam,
  );
}

List<String> diagnosticImageLines(
  PositionDiagnostic current,
  TacticalCandidate? selected,
  TacticalPriority priority,
) => [
  'Diagnóstico · edición ${current.context.rulesVersion == VisionContext.supportedVersion ? VisionContext.supportedVersion : 'no soportada'} · ${priority.label}',
  'V: visibles · T: amenazas con línea y alcance · C: costo · ?: datos parciales',
  'Actual ${current.cell.label}: ${TacticalMetric.values.map((m) => '${m.label} ${current.metrics[m]!.text}').join(' / ')}',
  if (selected?.position != null)
    'Hipótesis ${selected!.cell.label}: ${TacticalMetric.values.map((m) => '${m.label} ${selected.position!.metrics[m]!.text}').join(' / ')}',
  'Color: métrica elegida, sin valoración estratégica universal. No valida ataques ni victoria.',
  'Sin mejoras: hipótesis separada cuando se activa en el informe. Se conservan límites de los motores.',
];

Future<Uint8List> diagnosticPng(
  BoardSession original,
  PositionDiagnostic current,
  List<TacticalCandidate> candidates,
  TacticalCandidate? selected,
  TacticalPriority priority,
) async {
  final session = publicDiagnosticBoard(original);
  const geometry = BoardGeometry();
  final width = math.max(560.0, geometry.width(session.dimensions)),
      boardHeight = geometry.height(session.dimensions);
  final rows = <TextPainter>[];
  for (final line in diagnosticImageLines(current, selected, priority)) {
    rows.add(
      TextPainter(
        text: TextSpan(
          text: line,
          style: const TextStyle(
            fontFamily: 'sans-serif',
            fontSize: 13,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: width - 24),
    );
  }
  final height =
          boardHeight +
          24 +
          rows.fold<double>(0, (sum, t) => sum + t.height + 8),
      scale = math.min(2.0, 2048 / math.max(width, height));
  final recorder = ui.PictureRecorder(), canvas = Canvas(recorder);
  canvas.scale(scale);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width, height),
    Paint()..color = const Color(0xff101c2b),
  );
  canvas.save();
  canvas.translate((width - geometry.width(session.dimensions)) / 2, 0);
  BoardPainter(
    dimensions: session.dimensions,
    selectedCell: null,
    showGrid: true,
    showCoordinates: true,
    session: session,
  ).paint(canvas, Size(geometry.width(session.dimensions), boardHeight));
  TacticalMapPainter(
    candidates: candidates,
    current: current.cell,
    selected: selected?.cell,
    priority: priority,
  ).paint(canvas, Size(geometry.width(session.dimensions), boardHeight));
  canvas.restore();
  var y = boardHeight + 12;
  for (final text in rows) {
    text.paint(canvas, Offset(12, y));
    y += text.height + 8;
    text.dispose();
  }
  final picture = recorder.endRecording();
  try {
    final image = await picture.toImage(
      (width * scale).ceil(),
      (height * scale).ceil(),
    );
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw StateError('No se pudo crear PNG.');
      return Uint8List.fromList(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
    } finally {
      image.dispose();
    }
  } finally {
    picture.dispose();
  }
}
