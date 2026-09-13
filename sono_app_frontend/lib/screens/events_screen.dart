import 'package:flutter/material.dart';

import '../models/sono_event.dart';
import '../services/event_api_service.dart';
import '../theme/app_theme.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key, this.isAdmin = true});

  final bool isAdmin;

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final List<SonoEvent> _events = [];
  final _eventApi = EventApiService();
  late DateTime _visibleMonth;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
    _loadEvents();
  }

  List<SonoEvent> get _visibleEvents {
    final events = _events
        .where((event) => _isSameMonth(event.date, _visibleMonth))
        .toList();
    events.sort((a, b) => a.date.compareTo(b.date));
    return events;
  }

  Future<void> _loadEvents() async {
    try {
      final events = await _eventApi.fetchEvents();
      if (!mounted) return;
      setState(() {
        _events
          ..clear()
          ..addAll(events);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('Impossible de charger les événements. Lancez le serveur FastAPI.');
    }
  }

  void _changeMonth(int offset) {
    setState(() {
      _visibleMonth = DateTime(
        _visibleMonth.year,
        _visibleMonth.month + offset,
      );
    });
  }

  Future<void> _openEventForm({SonoEvent? event}) async {
    final result = await showDialog<SonoEvent>(
      context: context,
      builder: (_) => _EventDialog(event: event, initialDate: _visibleMonth),
    );

    if (result == null) {
      return;
    }

    try {
      if (event == null) {
        final savedEvent = await _eventApi.createEvent(result);
        setState(() {
          _events.add(savedEvent);
          _visibleMonth = DateTime(savedEvent.date.year, savedEvent.date.month);
        });
      } else {
        final savedEvent = await _eventApi.updateEvent(result);
        setState(() {
          final index = _events.indexWhere((item) => item.id == event.id);
          if (index != -1) {
            _events[index] = savedEvent;
          }
          _visibleMonth = DateTime(savedEvent.date.year, savedEvent.date.month);
        });
      }
    } catch (error) {
      _showError('Enregistrement impossible. Vérifiez le serveur FastAPI.');
    }
  }

  Future<void> _deleteEvent(SonoEvent event) async {
    try {
      await _eventApi.deleteEvent(event.id);
      setState(() => _events.removeWhere((item) => item.id == event.id));
    } catch (error) {
      _showError('Suppression impossible. Vérifiez le serveur FastAPI.');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  int _eventCountForDay(DateTime day) {
    return _events.where((event) => _isSameDay(event.date, day)).length;
  }

  @override
  Widget build(BuildContext context) {
    final visibleEvents = _visibleEvents;

    return Scaffold(
      appBar: AppBar(title: const Text('Planning & événements')),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              )
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _MonthCalendar(
                      visibleMonth: _visibleMonth,
                      eventsCount: visibleEvents.length,
                      countForDay: _eventCountForDay,
                      onPreviousMonth: () => _changeMonth(-1),
                      onNextMonth: () => _changeMonth(1),
                    ),
                  ),
                  if (visibleEvents.isEmpty)
                    SliverToBoxAdapter(
                      child: _EmptyEventsState(
                        monthLabel: _formatMonth(_visibleMonth),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                      sliver: SliverList.separated(
                        itemCount: visibleEvents.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                              final event = visibleEvents[index];
                              return _EventCard(
                                event: event,
                                isAdmin: widget.isAdmin,
                                onEdit: () => _openEventForm(event: event),
                                onDelete: () => _deleteEvent(event),
                              );
                        },
                      ),
                    ),
                ],
              ),
      ),
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton(
              tooltip: 'Ajouter un événement',
              onPressed: _openEventForm,
              child: const Icon(Icons.add_rounded),
            )
          : null,
    );
  }
}

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.visibleMonth,
    required this.eventsCount,
    required this.countForDay,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  final DateTime visibleMonth;
  final int eventsCount;
  final int Function(DateTime day) countForDay;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  @override
  Widget build(BuildContext context) {
    final days = _calendarDays(visibleMonth);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Mois précédent',
                  onPressed: onPreviousMonth,
                  icon: const Icon(
                    Icons.chevron_left_rounded,
                    color: AppColors.gold,
                  ),
                ),
                Expanded(
                  child: Text(
                    _formatMonth(visibleMonth),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Mois suivant',
                  onPressed: onNextMonth,
                  icon: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: const ['L', 'M', 'M', 'J', 'V', 'S', 'D']
                  .map(
                    (day) => Expanded(
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: days.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
              ),
              itemBuilder: (context, index) {
                final day = days[index];
                return _DayCell(
                  day: day,
                  inMonth: _isSameMonth(day, visibleMonth),
                  eventCount: countForDay(day),
                );
              },
            ),
            const SizedBox(height: 12),
            _MonthSummary(eventsCount: eventsCount),
          ],
        ),
      ),
    );
  }
}

class _MonthSummary extends StatelessWidget {
  const _MonthSummary({required this.eventsCount});

  final int eventsCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        eventsCount == 0
            ? 'Aucun événement programmé pour ce mois'
            : '$eventsCount événement(s) programmé(s) ce mois',
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.muted),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.inMonth,
    required this.eventCount,
  });

  final DateTime day;
  final bool inMonth;
  final int eventCount;

  @override
  Widget build(BuildContext context) {
    final hasEvent = eventCount > 0;

    return Container(
      decoration: BoxDecoration(
        color: hasEvent
            ? AppColors.gold.withValues(alpha: 0.14)
            : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasEvent ? AppColors.gold : AppColors.border,
          width: hasEvent ? 1.2 : 1,
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              '${day.day}',
              style: TextStyle(
                color: inMonth
                    ? Colors.white
                    : AppColors.muted.withValues(alpha: 0.45),
                fontWeight: hasEvent ? FontWeight.w800 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
          if (hasEvent)
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                width: 15,
                height: 15,
                decoration: const BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$eventCount',
                    style: const TextStyle(
                      color: AppColors.black,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyEventsState extends StatelessWidget {
  const _EmptyEventsState({required this.monthLabel});

  final String monthLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Aucun événement en $monthLabel. Appuyez sur + pour ajouter une date.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted),
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.onEdit,
    required this.onDelete,
    this.isAdmin = true,
  });

  final SonoEvent event;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    '${event.troupe} - ${event.type}',
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (isAdmin)
                  IconButton(
                    tooltip: 'Modifier',
                    onPressed: onEdit,
                    icon:
                        const Icon(Icons.edit_outlined, color: AppColors.gold),
                  ),
                if (isAdmin)
                  IconButton(
                    tooltip: 'Supprimer',
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            _InfoLine(
              icon: Icons.calendar_month_outlined,
              text: _formatDate(event.date),
            ),
            const SizedBox(height: 8),
            _InfoLine(icon: Icons.groups_2_outlined, text: event.staffLabel),
            const SizedBox(height: 8),
            _InfoLine(icon: Icons.local_shipping_outlined, text: event.vehicle),
            const SizedBox(height: 8),
            _InfoLine(
              icon: Icons.description_outlined,
              text: event.description,
            ),
            const SizedBox(height: 8),
            _InfoLine(icon: Icons.place_outlined, text: event.lieu),
            const Divider(color: AppColors.border, height: 22),
            Text(
              'Plus d’information: châteaux ${event.numChateau}, bases ${event.numBase}, retours ${event.numRetour}, chanteurs ${event.numChanteur}, percussion ${event.numPercussion}, batterie ${event.batterie ? 'oui' : 'non'}',
              style: const TextStyle(color: AppColors.muted, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}

extension _EventLabels on SonoEvent {
  String get staffLabel => staffNames.isEmpty
      ? 'Aucun travailleur renseigné'
      : staffNames.join(', ');
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.muted, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text.isEmpty ? 'Non renseigné' : text,
            style: const TextStyle(color: Colors.white70, height: 1.35),
          ),
        ),
      ],
    );
  }
}

class _EventDialog extends StatefulWidget {
  const _EventDialog({required this.initialDate, this.event});

  final DateTime initialDate;
  final SonoEvent? event;

  @override
  State<_EventDialog> createState() => _EventDialogState();
}

class _EventDialogState extends State<_EventDialog> {
  static const _troupes = ['Oscar', 'Rayhana', 'Sandra', 'Fedy', 'Autre'];
  static const _types = ['Ferka', 'Trio', 'Duo', 'Solo'];
  static const _vehicles = [
    'Camion 1',
    'Camion 2',
    'Partner',
    'Voiture personnelle',
    'Autre',
  ];

  final _formKey = GlobalKey<FormState>();
  final _customTroupeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _staffController = TextEditingController();
  final _customVehicleController = TextEditingController();
  final _numChateauController = TextEditingController();
  final _numBaseController = TextEditingController();
  final _numRetourController = TextEditingController();
  final _numChanteurController = TextEditingController();
  final _numPercussionController = TextEditingController();

  late String _selectedTroupe;
  late String _selectedType;
  late String _selectedVehicle;
  late DateTime _selectedDate;
  bool _showMoreInfo = false;
  bool _batterie = false;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    _selectedType = event?.type ?? _types.first;
    _selectedDate = event?.date ?? _initialDateInMonth(widget.initialDate);
    _batterie = event?.batterie ?? false;

    if (event == null || _troupes.contains(event.troupe)) {
      _selectedTroupe = event?.troupe ?? _troupes.first;
    } else {
      _selectedTroupe = 'Autre';
      _customTroupeController.text = event.troupe;
    }

    if (event == null || _vehicles.contains(event.vehicle)) {
      _selectedVehicle = event?.vehicle ?? _vehicles.first;
    } else {
      _selectedVehicle = 'Autre';
      _customVehicleController.text = event.vehicle;
    }

    _descriptionController.text = event?.description ?? '';
    _locationController.text = event?.lieu ?? '';
    _staffController.text = event?.staffNames.join(', ') ?? '';
    _numChateauController.text = '${event?.numChateau ?? 0}';
    _numBaseController.text = '${event?.numBase ?? 0}';
    _numRetourController.text = '${event?.numRetour ?? 0}';
    _numChanteurController.text = '${event?.numChanteur ?? 0}';
    _numPercussionController.text = '${event?.numPercussion ?? 0}';
  }

  @override
  void dispose() {
    _customTroupeController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _staffController.dispose();
    _customVehicleController.dispose();
    _numChateauController.dispose();
    _numBaseController.dispose();
    _numRetourController.dispose();
    _numChanteurController.dispose();
    _numPercussionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.gold,
              onPrimary: AppColors.black,
              surface: AppColors.surface,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() => _selectedDate = pickedDate);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final troupe = _selectedTroupe == 'Autre'
        ? _customTroupeController.text.trim()
        : _selectedTroupe;
    final vehicle = _selectedVehicle == 'Autre'
        ? _customVehicleController.text.trim()
        : _selectedVehicle;

    Navigator.pop(
      context,
      SonoEvent(
        id:
            widget.event?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        troupe: troupe,
        type: _selectedType,
        description: _descriptionController.text.trim(),
        lieu: _locationController.text.trim(),
        date: _selectedDate,
        staffNames: _staffController.text
            .split(',')
            .map((name) => name.trim())
            .where((name) => name.isNotEmpty)
            .toList(),
        vehicle: vehicle,
        numChateau: _parseInt(_numChateauController.text),
        numBase: _parseInt(_numBaseController.text),
        numRetour: _parseInt(_numRetourController.text),
        numChanteur: _parseInt(_numChanteurController.text),
        numPercussion: _parseInt(_numPercussionController.text),
        batterie: _batterie,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(
        widget.event == null ? 'Ajouter un événement' : 'Modifier l’événement',
        style: const TextStyle(
          color: AppColors.gold,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DateField(date: _selectedDate, onTap: _pickDate),
              const SizedBox(height: 14),
              _DropdownField(
                value: _selectedTroupe,
                label: 'Troupe / Artiste',
                values: _troupes,
                onChanged: (value) => setState(() => _selectedTroupe = value),
              ),
              if (_selectedTroupe == 'Autre') ...[
                const SizedBox(height: 14),
                _TextField(
                  controller: _customTroupeController,
                  label: 'Nom personnalisé',
                  requiredMessage: 'Veuillez saisir le nom.',
                ),
              ],
              const SizedBox(height: 14),
              _DropdownField(
                value: _selectedType,
                label: 'Type de troupe',
                values: _types,
                onChanged: (value) => setState(() => _selectedType = value),
              ),
              const SizedBox(height: 14),
              _TextField(
                controller: _staffController,
                label: 'Travailleurs',
                hint: 'Ahmed, Sami, Yassine...',
                icon: Icons.groups_2_outlined,
                requiredMessage: 'Veuillez saisir les travailleurs.',
              ),
              const SizedBox(height: 14),
              _DropdownField(
                value: _selectedVehicle,
                label: 'Voiture / Transport',
                values: _vehicles,
                onChanged: (value) => setState(() => _selectedVehicle = value),
              ),
              if (_selectedVehicle == 'Autre') ...[
                const SizedBox(height: 14),
                _TextField(
                  controller: _customVehicleController,
                  label: 'Nom de la voiture',
                  requiredMessage: 'Veuillez saisir le transport.',
                ),
              ],
              const SizedBox(height: 14),
              _TextField(
                controller: _descriptionController,
                label: 'Description / Fiche technique',
                hint: 'Châteaux, retours, micros...',
                minLines: 3,
                maxLines: 5,
                requiredMessage: 'Veuillez saisir la fiche technique.',
              ),
              const SizedBox(height: 14),
              _TextField(
                controller: _locationController,
                label: 'Lieu',
                hint: 'Salle des fêtes ou lien Google Maps',
                icon: Icons.place_outlined,
                requiredMessage: 'Veuillez saisir le lieu.',
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () => setState(() => _showMoreInfo = !_showMoreInfo),
                icon: Icon(
                  _showMoreInfo
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: AppColors.gold,
                ),
                label: const Text(
                  'Plus d’information',
                  style: TextStyle(color: AppColors.gold),
                ),
              ),
              if (_showMoreInfo) ...[
                const SizedBox(height: 8),
                _NumberField(
                  controller: _numChateauController,
                  label: 'Num château',
                ),
                const SizedBox(height: 12),
                _NumberField(
                  controller: _numBaseController,
                  label: 'Num de base',
                ),
                const SizedBox(height: 12),
                _NumberField(
                  controller: _numRetourController,
                  label: 'Num de retour',
                ),
                const SizedBox(height: 12),
                _NumberField(
                  controller: _numChanteurController,
                  label: 'Num de chanteur',
                ),
                const SizedBox(height: 12),
                _NumberField(
                  controller: _numPercussionController,
                  label: 'Num percussion',
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: AppColors.gold,
                  title: const Text(
                    'Batterie',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    _batterie ? 'Oui' : 'Non',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  value: _batterie,
                  onChanged: (value) => setState(() => _batterie = value),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Annuler',
            style: TextStyle(color: AppColors.muted),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _submit,
          icon: Icon(
            widget.event == null ? Icons.add_rounded : Icons.check_rounded,
          ),
          label: Text(widget.event == null ? 'Ajouter' : 'Enregistrer'),
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date de l’événement',
          prefixIcon: Icon(Icons.calendar_today_outlined),
        ),
        child: Text(
          _formatDate(date),
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.label,
    required this.values,
    required this.onChanged,
  });

  final String value;
  final String label;
  final List<String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: AppColors.surface,
      decoration: InputDecoration(labelText: label),
      items: values
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.label,
    required this.requiredMessage,
    this.hint,
    this.icon,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String requiredMessage;
  final String? hint;
  final IconData? icon;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon == null ? null : Icon(icon),
      ),
      validator: (value) {
        if ((value ?? '').trim().isEmpty) {
          return requiredMessage;
        }
        return null;
      },
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final parsed = int.tryParse((value ?? '').trim());
        if (parsed == null || parsed < 0) {
          return 'Veuillez saisir un nombre valide.';
        }
        return null;
      },
    );
  }
}

DateTime _initialDateInMonth(DateTime month) {
  final today = DateTime.now();
  final lastDay = DateTime(month.year, month.month + 1, 0).day;
  final safeDay = today.day > lastDay ? lastDay : today.day;
  return DateTime(month.year, month.month, safeDay);
}

List<DateTime> _calendarDays(DateTime month) {
  final firstDay = DateTime(month.year, month.month);
  final startOffset = firstDay.weekday - 1;
  final startDate = firstDay.subtract(Duration(days: startOffset));
  return List.generate(42, (index) => startDate.add(Duration(days: index)));
}

bool _isSameMonth(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month;

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

int _parseInt(String value) => int.tryParse(value.trim()) ?? 0;

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

String _formatMonth(DateTime date) {
  const months = [
    'Janvier',
    'Février',
    'Mars',
    'Avril',
    'Mai',
    'Juin',
    'Juillet',
    'Août',
    'Septembre',
    'Octobre',
    'Novembre',
    'Décembre',
  ];
  return '${months[date.month - 1]} ${date.year}';
}
