class Idea {
  final int? id;
  final String titre;
  final String description;
  final String priorite;   // Haute / Moyenne / Basse
  final String categorie;  // Produit / Marketing / Technique / Business
  final String statut;     // Backlog / En cours / Terminé
  final String dateCreation;

  const Idea({
    this.id,
    required this.titre,
    required this.description,
    required this.priorite,
    required this.categorie,
    required this.statut,
    required this.dateCreation, String? imageBase64,
  });

  Idea copyWith({
    int? id,
    String? titre,
    String? description,
    String? priorite,
    String? categorie,
    String? statut,
    String? dateCreation,
  }) {
    return Idea(
      id: id ?? this.id,
      titre: titre ?? this.titre,
      description: description ?? this.description,
      priorite: priorite ?? this.priorite,
      categorie: categorie ?? this.categorie,
      statut: statut ?? this.statut,
      dateCreation: dateCreation ?? this.dateCreation,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titre': titre,
      'description': description,
      'priorite': priorite,
      'categorie': categorie,
      'statut': statut,
      'date_creation': dateCreation,
    };
  }

  factory Idea.fromMap(Map<String, dynamic> map) {
    return Idea(
      id: map['id'] as int?,
      titre: map['titre'] as String,
      description: map['description'] as String,
      priorite: map['priorite'] as String,
      categorie: map['categorie'] as String,
      statut: map['statut'] as String,
      dateCreation: map['date_creation'] as String,
    );
  }

  get imageBase64 => null;
}
