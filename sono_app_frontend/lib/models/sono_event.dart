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
    int asInt(Object? v) => (v as num?)?.toInt() ?? 0;
    return SonoEvent(
      id: (json['id'] ?? '').toString(),
      troupe: (json['troupe'] ?? '') as String,
      type: (json['type'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      lieu: (json['lieu'] ?? '') as String,
      date: DateTime.tryParse((json['date'] ?? '') as String) ??
          DateTime.now(),
      staffNames: ((json['staffNames'] as List?) ?? [])
          .map((e) => e.toString())
          .toList(),
      vehicle: (json['vehicle'] ?? '') as String,
      numChateau: asInt(json['numChateau']),
      numBase: asInt(json['numBase']),
      numRetour: asInt(json['numRetour']),
      numChanteur: asInt(json['numChanteur']),
      numPercussion: asInt(json['numPercussion']),
      batterie: json['batterie'] == true,
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
