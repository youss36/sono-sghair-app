class TransportVehicle {
  const TransportVehicle({
    required this.id,
    required this.matricule,
    required this.modele,
  });

  final String id;
  final String matricule;
  final String modele;

  factory TransportVehicle.fromJson(Map<String, dynamic> json) {
    return TransportVehicle(
      id: json['id'].toString(),
      matricule: json['matricule'] as String,
      modele: json['modele'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'matricule': matricule,
      'modele': modele,
    };
  }
}
