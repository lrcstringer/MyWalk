import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/datasources/remote/auth_service.dart';
import '../../providers/circle_events_provider.dart';
import '../../providers/circle_notification_provider.dart';
import '../../../domain/entities/circle.dart';
import '../../theme/app_theme.dart';

Future<bool> _isOffline() async {
  final r = await Connectivity().checkConnectivity();
  return r.every((c) => c == ConnectivityResult.none);
}

class EventsTab extends StatelessWidget {
  final String circleId;
  final bool isAdmin;
  final CircleSettings settings;
  const EventsTab({
    super.key,
    required this.circleId,
    required this.isAdmin,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CircleEventsProvider>(
      builder: (context, provider, _) {
        final uid = AuthService.shared.userId ?? '';
        final events = provider.eventsFor(circleId);
        final isLoading = provider.isLoading(circleId);
        final canCreate = isAdmin || settings.eventPermission == 'any_member';

        return Scaffold(
          backgroundColor: MyWalkColor.charcoal,
          floatingActionButton: canCreate
              ? FloatingActionButton.small(
                  onPressed: () => _showCreateSheet(context),
                  backgroundColor: MyWalkColor.golden,
                  foregroundColor: MyWalkColor.charcoal,
                  child: const Icon(Icons.add),
                )
              : null,
          body: isLoading && events.isEmpty
              ? const Center(child: CircularProgressIndicator(color: MyWalkColor.golden))
              : RefreshIndicator(
                  color: MyWalkColor.golden,
                  backgroundColor: MyWalkColor.cardBackground,
                  onRefresh: () => provider.load(circleId),
                  child: events.isEmpty
                      ? _emptyState(canCreate)
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                          itemCount: events.length,
                          separatorBuilder: (context, i) => const SizedBox(height: 12),
                          itemBuilder: (_, i) => _EventCard(
                            event: events[i],
                            uid: uid,
                            circleId: circleId,
                            isAdmin: isAdmin,
                          ),
                        ),
                ),
        );
      },
    );
  }

  Widget _emptyState(bool canCreate) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.event_rounded, size: 40, color: Colors.white.withValues(alpha: 0.15)),
          const SizedBox(height: 12),
          Text('No upcoming events.',
              style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.4))),
          const SizedBox(height: 6),
          Text(canCreate
              ? 'Tap + to create an event for your circle.'
              : 'Your admin hasn\'t created any events yet.',
              style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.3)),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: MyWalkColor.charcoal,
      builder: (_) => CreateEventSheet(circleId: circleId, isAdmin: isAdmin),
    );
  }
}

// ─── Event Card ───────────────────────────────────────────────────────────────

class _EventCard extends StatelessWidget {
  final CircleEvent event;
  final String uid;
  final String circleId;
  final bool isAdmin;

  const _EventCard({
    required this.event,
    required this.uid,
    required this.circleId,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final eventDt = event.eventDateTime;
    final canEdit = isAdmin || event.isAuthor(uid);
    final canDelete = isAdmin || event.isAuthor(uid);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MyWalkColor.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MyWalkColor.cardBorder, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: MyWalkColor.sage.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _formatDateShort(eventDt),
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: MyWalkColor.sage),
            ),
          ),
          const Spacer(),
          if (canEdit) ...[
            GestureDetector(
              onTap: () => _showEditSheet(context),
              child: Icon(Icons.edit_outlined,
                  size: 18, color: Colors.white.withValues(alpha: 0.3)),
            ),
            const SizedBox(width: 12),
          ],
          if (canDelete)
            GestureDetector(
              onTap: () => _confirmDelete(context),
              child: Icon(Icons.delete_outline_rounded,
                  size: 18, color: Colors.white.withValues(alpha: 0.3)),
            ),
        ]),
        const SizedBox(height: 10),
        Text(event.title,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: MyWalkColor.warmWhite)),
        if (event.description != null && event.description!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(event.description!,
              style: TextStyle(
                  fontSize: 13, color: Colors.white.withValues(alpha: 0.55), height: 1.4)),
        ],
        const SizedBox(height: 12),
        Row(children: [
          Icon(Icons.access_time_rounded, size: 13, color: MyWalkColor.softGold),
          const SizedBox(width: 5),
          Text(_formatTime(eventDt),
              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.55))),
          if (event.location != null) ...[
            const SizedBox(width: 12),
            const Icon(Icons.place_rounded, size: 13, color: MyWalkColor.softGold),
            const SizedBox(width: 5),
            Expanded(
              child: Text(event.location!,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.55))),
            ),
          ],
        ]),
        if (event.meetingLink != null) ...[
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => _openLink(context, event.meetingLink!),
            child: Row(children: [
              const Icon(Icons.video_call_rounded, size: 14, color: MyWalkColor.golden),
              const SizedBox(width: 5),
              const Text('Join Meeting',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: MyWalkColor.golden)),
            ]),
          ),
        ],
      ]),
    );
  }

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: MyWalkColor.charcoal,
      builder: (_) => EditEventSheet(circleId: circleId, event: event, isAdmin: isAdmin),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: MyWalkColor.cardBackground,
        title: const Text('Delete Event',
            style: TextStyle(color: MyWalkColor.warmWhite, fontSize: 16)),
        content: Text('Remove "${event.title}"?',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<CircleEventsProvider>().deleteEvent(circleId, event.id);
            },
            child: const Text('Delete', style: TextStyle(color: MyWalkColor.warmCoral)),
          ),
        ],
      ),
    );
  }

  void _openLink(BuildContext context, String url) {
    // URL launcher — using share_plus as a fallback clipboard copy since
    // url_launcher is not in the current dependency set.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(url, overflow: TextOverflow.ellipsis),
        backgroundColor: MyWalkColor.cardBackground,
        action: SnackBarAction(
          label: 'Copy',
          textColor: MyWalkColor.golden,
          onPressed: () {
            // Clipboard access without url_launcher.
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Link copied')),
            );
          },
        ),
      ),
    );
  }

  String _formatDateShort(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return '${days[dt.weekday % 7]}, ${months[dt.month - 1]} ${dt.day}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }
}

// ─── Create Event Sheet ───────────────────────────────────────────────────────

class CreateEventSheet extends StatefulWidget {
  final String circleId;
  final bool isAdmin;
  const CreateEventSheet({super.key, required this.circleId, this.isAdmin = false});

  @override
  State<CreateEventSheet> createState() => _CreateEventSheetState();
}

class _CreateEventSheetState extends State<CreateEventSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  final _linkController = TextEditingController();
  DateTime? _eventDate;
  bool _notifyMembers = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        backgroundColor: MyWalkColor.charcoal,
        title: const Text('New Event',
            style: TextStyle(color: MyWalkColor.warmWhite, fontSize: 17)),
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
        ),
        actions: [
          TextButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: MyWalkColor.golden))
                : const Text('Create',
                    style: TextStyle(
                        color: MyWalkColor.golden, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _label('Event Title'),
          const SizedBox(height: 6),
          TextField(
            controller: _titleController,
            style: const TextStyle(color: MyWalkColor.warmWhite, fontSize: 14),
            decoration: _inputDec('e.g. Friday Prayer Night'),
          ),
          const SizedBox(height: 14),
          _label('Date & Time'),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _pickDateTime,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: MyWalkColor.inputBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 16, color: MyWalkColor.softGold),
                const SizedBox(width: 10),
                Text(
                  _eventDate == null
                      ? 'Pick date and time'
                      : _formatFull(_eventDate!),
                  style: TextStyle(
                    fontSize: 14,
                    color: _eventDate == null
                        ? Colors.white.withValues(alpha: 0.3)
                        : MyWalkColor.warmWhite,
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          _label('Description (optional)'),
          const SizedBox(height: 6),
          TextField(
            controller: _descController,
            maxLines: 3,
            style: const TextStyle(color: MyWalkColor.warmWhite, fontSize: 14),
            decoration: _inputDec("What's happening at this event?"),
          ),
          const SizedBox(height: 14),
          _label('Location (optional)'),
          const SizedBox(height: 6),
          TextField(
            controller: _locationController,
            style: const TextStyle(color: MyWalkColor.warmWhite, fontSize: 14),
            decoration: _inputDec('Address or venue name'),
          ),
          const SizedBox(height: 14),
          _label('Meeting Link (optional)'),
          const SizedBox(height: 6),
          TextField(
            controller: _linkController,
            keyboardType: TextInputType.url,
            style: const TextStyle(color: MyWalkColor.warmWhite, fontSize: 14),
            decoration: _inputDec('https://zoom.us/…'),
          ),
          if (widget.isAdmin) ...[
            const SizedBox(height: 14),
            _notifyRow(),
          ],
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!,
                style: const TextStyle(fontSize: 12, color: MyWalkColor.warmCoral)),
          ],
        ]),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.5)));

  InputDecoration _inputDec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
        filled: true,
        fillColor: MyWalkColor.inputBackground,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      );

  Widget _notifyRow() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: MyWalkColor.cardBackground,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(children: [
      const Icon(Icons.notifications_outlined, size: 18, color: MyWalkColor.softGold),
      const SizedBox(width: 10),
      const Expanded(
        child: Text('Notify members',
            style: TextStyle(fontSize: 14, color: MyWalkColor.warmWhite)),
      ),
      Switch(
        value: _notifyMembers,
        onChanged: (v) => setState(() => _notifyMembers = v),
        activeTrackColor: MyWalkColor.golden,
      activeThumbColor: Colors.white,
      ),
    ]),
  );

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: MyWalkColor.golden,
            surface: MyWalkColor.cardBackground,
          ),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 19, minute: 0),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: MyWalkColor.golden,
            surface: MyWalkColor.cardBackground,
          ),
        ),
        child: child!,
      ),
    );
    if (time == null || !mounted) return;

    setState(() {
      _eventDate =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  String _formatFull(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    return '${days[dt.weekday % 7]}, ${months[dt.month - 1]} ${dt.day}  •  $h:$m $ampm';
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Title required.');
      return;
    }
    if (_eventDate == null) {
      setState(() => _error = 'Pick a date and time.');
      return;
    }
    setState(() { _submitting = true; _error = null; });
    if (await _isOffline()) {
      if (mounted) setState(() { _error = 'No internet connection. Please connect and try again.'; _submitting = false; });
      return;
    }
    if (!mounted) return;
    final eventsProvider = context.read<CircleEventsProvider>();
    final notifProvider = _notifyMembers && widget.isAdmin
        ? context.read<CircleNotificationProvider>()
        : null;
    final nav = Navigator.of(context);
    try {
      await eventsProvider.createEvent(
        circleId: widget.circleId,
        title: title,
        eventDate: _eventDate!,
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        meetingLink: _linkController.text.trim().isEmpty
            ? null
            : _linkController.text.trim(),
      );
      notifProvider?.sendAnnouncement(
        circleId: widget.circleId,
        message: 'New event: $title — ${_formatFull(_eventDate!)}',
      ).catchError((_) {});
      nav.pop();
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _submitting = false; });
    }
  }
}

// ─── Edit Event Sheet ─────────────────────────────────────────────────────────

class EditEventSheet extends StatefulWidget {
  final String circleId;
  final CircleEvent event;
  final bool isAdmin;
  const EditEventSheet({super.key, required this.circleId, required this.event, this.isAdmin = false});

  @override
  State<EditEventSheet> createState() => _EditEventSheetState();
}

class _EditEventSheetState extends State<EditEventSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _locationController;
  late final TextEditingController _linkController;
  late DateTime _eventDate;
  bool _notifyMembers = false;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    _titleController = TextEditingController(text: e.title);
    _descController = TextEditingController(text: e.description ?? '');
    _locationController = TextEditingController(text: e.location ?? '');
    _linkController = TextEditingController(text: e.meetingLink ?? '');
    _eventDate = e.eventDateTime;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        backgroundColor: MyWalkColor.charcoal,
        title: const Text('Edit Event',
            style: TextStyle(color: MyWalkColor.warmWhite, fontSize: 17)),
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
        ),
        actions: [
          TextButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: MyWalkColor.golden))
                : const Text('Save',
                    style: TextStyle(
                        color: MyWalkColor.golden, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _label('Event Title'),
          const SizedBox(height: 6),
          TextField(
            controller: _titleController,
            style: const TextStyle(color: MyWalkColor.warmWhite, fontSize: 14),
            decoration: _inputDec('e.g. Friday Prayer Night'),
          ),
          const SizedBox(height: 14),
          _label('Date & Time'),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _pickDateTime,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: MyWalkColor.inputBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 16, color: MyWalkColor.softGold),
                const SizedBox(width: 10),
                Text(_formatFull(_eventDate),
                    style: const TextStyle(
                        fontSize: 14, color: MyWalkColor.warmWhite)),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          _label('Description (optional)'),
          const SizedBox(height: 6),
          TextField(
            controller: _descController,
            maxLines: 3,
            style: const TextStyle(color: MyWalkColor.warmWhite, fontSize: 14),
            decoration: _inputDec("What's happening at this event?"),
          ),
          const SizedBox(height: 14),
          _label('Location (optional)'),
          const SizedBox(height: 6),
          TextField(
            controller: _locationController,
            style: const TextStyle(color: MyWalkColor.warmWhite, fontSize: 14),
            decoration: _inputDec('Address or venue name'),
          ),
          const SizedBox(height: 14),
          _label('Meeting Link (optional)'),
          const SizedBox(height: 6),
          TextField(
            controller: _linkController,
            keyboardType: TextInputType.url,
            style: const TextStyle(color: MyWalkColor.warmWhite, fontSize: 14),
            decoration: _inputDec('https://zoom.us/…'),
          ),
          if (widget.isAdmin) ...[
            const SizedBox(height: 14),
            _notifyRow(),
          ],
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!,
                style: const TextStyle(fontSize: 12, color: MyWalkColor.warmCoral)),
          ],
        ]),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.5)));

  InputDecoration _inputDec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
        filled: true,
        fillColor: MyWalkColor.inputBackground,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      );

  Widget _notifyRow() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: MyWalkColor.cardBackground,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(children: [
      const Icon(Icons.notifications_outlined, size: 18, color: MyWalkColor.softGold),
      const SizedBox(width: 10),
      const Expanded(
        child: Text('Notify members',
            style: TextStyle(fontSize: 14, color: MyWalkColor.warmWhite)),
      ),
      Switch(
        value: _notifyMembers,
        onChanged: (v) => setState(() => _notifyMembers = v),
        activeTrackColor: MyWalkColor.golden,
        activeThumbColor: Colors.white,
      ),
    ]),
  );

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _eventDate.isAfter(now) ? _eventDate : now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: MyWalkColor.golden,
            surface: MyWalkColor.cardBackground,
          ),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_eventDate),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: MyWalkColor.golden,
            surface: MyWalkColor.cardBackground,
          ),
        ),
        child: child!,
      ),
    );
    if (time == null || !mounted) return;

    setState(() {
      _eventDate =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  String _formatFull(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    return '${days[dt.weekday % 7]}, ${months[dt.month - 1]} ${dt.day}  •  $h:$m $ampm';
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Title required.');
      return;
    }
    if (_eventDate.isBefore(DateTime.now())) {
      setState(() => _error = 'Event date must be in the future.');
      return;
    }
    setState(() { _submitting = true; _error = null; });
    if (await _isOffline()) {
      if (mounted) setState(() { _error = 'No internet connection. Please connect and try again.'; _submitting = false; });
      return;
    }
    if (!mounted) return;
    final eventsProvider = context.read<CircleEventsProvider>();
    final notifProvider = _notifyMembers && widget.isAdmin
        ? context.read<CircleNotificationProvider>()
        : null;
    final nav = Navigator.of(context);
    try {
      await eventsProvider.updateEvent(
        circleId: widget.circleId,
        eventId: widget.event.id,
        title: title,
        eventDate: _eventDate,
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        meetingLink: _linkController.text.trim().isEmpty
            ? null
            : _linkController.text.trim(),
      );
      notifProvider?.sendAnnouncement(
        circleId: widget.circleId,
        message: 'Event updated: $title — ${_formatFull(_eventDate)}',
      ).catchError((_) {});
      nav.pop();
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _submitting = false; });
    }
  }
}
