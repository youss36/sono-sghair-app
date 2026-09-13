class SonoEvent {
  const SonoEvent({
    required this.id,
    required this.troupe,
    required this.type,
    required this.description,
    required this.lieu,
    required this.date,
    required this.staffNames,
    required this.vehicle,
    required this.numChateau,
    required this.numBase,
    required this.numRetour,
    required this.numChanteur,
    required this.numPercussion,
    required this.batterie,
  });

  final String id;
  final String troupe;
  final String type;
  final String description;
  final String lieu;
  final DateTime date;
  final List<String> staffNames;
  final String vehicle;
  final int numChateau;
  final int numBase;
  final int numRetour;
  final int numChanteur;
  final int numPercussion;
  final bool batterie;

  factory SonoEvent.fromJson(Map<String, dynamic> json) {
    return SonoEvent(
      id: json['id'].toString(),
      troupe: json['troupe'] as String,
      type: json['type'] as String,
      description: json['description'] as String,
      lieu: json['lieu'] as String,
      date: DateTime.parse(json['date'] as String),
      staffNames: List<String>.from(json['staffNames'] as List),
      vehicle: json['vehicle'] as String,
      numChateau: json['numChateau'] as int,
      numBase: json['numBase'] as int,
      numRetour: json['numRetour'] as int,
      numChanteur: json['numChanteur'] as int,
      numPercussion: json['numPercussion'] as int,
      batterie: json['batterie'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'troupe': troupe,
      'type': type,
      'description': description,
      'lieu': lieu,
      'date': date.toIso8601String(),
      'staffNames': staffNames,
      'vehicle': vehicle,
      'numChateau': numChateau,
      'numBase': numBase,
      'numRetour': numRetour,
      'numChanteur': numChanteur,
      'numPercussion': numPercussion,
      'batterie': batterie,
    };
  }
}
