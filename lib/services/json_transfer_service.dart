import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/idea.dart';
import '../repositories/idea_repository.dart';

class JsonTransferService {
  final IdeaRepository ideasRepo;

  JsonTransferService({IdeaRepository? repo})
      : ideasRepo = repo ?? IdeaRepository();

  /// Export: toutes les idées -> fichier JSON
  Future<File> exportIdeasToJsonFile() async {
    final ideas = await ideasRepo.getAllIdeas();

    final payload = {
      "app": "startup_launchpad",
      "version": 1,
      "exportedAt": DateTime.now().toIso8601String(),
      "ideas": ideas.map((i) => i.toMap()).toList(),
    };

    final jsonStr = const JsonEncoder.withIndent("  ").convert(payload);

    final dir = Directory('/storage/emulated/0/Download');
    final file = File("${dir.path}/startup_ideas_export.json");

    return file.writeAsString(jsonStr);
  }


  /// Import: lit le JSON et insère les idées (sans doublons)
  /// Doublon = même (titre + date_creation)
  Future<int> importIdeasFromJsonString(String jsonStr) async {
    final decoded = json.decode(jsonStr);

    final ideasRaw = (decoded["ideas"] as List?) ?? [];
    int inserted = 0;

    final existing = await ideasRepo.getAllIdeas();
    final existingKeys = existing
        .map((e) => "${e.titre}__${e.dateCreation}")
        .toSet();

    for (final item in ideasRaw) {
      if (item is! Map) continue;

      final mapItem = Map<String, dynamic>.from(item);

      //  Important: on ignore l'id pour éviter conflits
      mapItem['id'] = null;

      final idea = Idea.fromMap(mapItem);
      final key = "${idea.titre}__${idea.dateCreation}";

      if (existingKeys.contains(key)) continue;

      await ideasRepo.insertIdea(idea);
      inserted++;
      existingKeys.add(key);
    }

    return inserted;
  }
}
