class Equipment {
  const Equipment({
    required this.id,
    required this.nomMateriel,
    required this.quantiteTotale,
  });

  final String id;
  final String nomMateriel;
  final int quantiteTotale;

  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      id: json['id'].toString(),
      nomMateriel: json['nom_materiel'] as String,
      quantiteTotale: (json['quantite_totale'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nom_materiel': nomMateriel,
      'quantite_totale': quantiteTotale,
    };
  }
}
