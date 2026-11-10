part of 'app.dart';

class NotesScope extends InheritedNotifier<NotesController> {
  const NotesScope({
    super.key,
    required NotesController controller,
    required super.child,
  }) : super(notifier: controller);

  static NotesController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NotesScope>()?.notifier;
}

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key, required this.controller});
  final LearningController controller;

  @override
  Widget build(BuildContext context) {
    final notes = NotesScope.maybeOf(context)!;
    final entries = notes.visibleNotes;
    return ScreenFrame(
      title: 'Mis notas',
      controller: controller,
      content: (context) => [
        if (!notes.ready) ...[
          Text(notes.loadError ?? 'Cargando tus notas…'),
          if (notes.loadError != null)
            FilledButton(
              onPressed: notes.load,
              child: const Text('Reintentar'),
            ),
        ] else if (entries.isEmpty)
          const Text('Aún no tienes notas. Agrega una desde cualquier subtema')
        else
          for (final entry in entries)
            Card(
              child: ListTile(
                title: Text(entry.lesson.title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${entry.module.title} → ${entry.topic.title}'),
                    Text(
                      '${entry.note.text.characters.take(80)}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(_noteDate(entry.note.modifiedAt)),
                  ],
                ),
                onTap: () => openScreen(
                  context,
                  LessonScreen(
                    controller: controller,
                    module: entry.module,
                    topic: entry.topic,
                    lesson: entry.lesson,
                    openNote: true,
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

String _noteDate(DateTime value) {
  final date = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(date.day)}/${two(date.month)}/${date.year} '
      '${two(date.hour)}:${two(date.minute)}';
}

class NoteEditorScreen extends StatefulWidget {
  const NoteEditorScreen({super.key, required this.lesson});
  final Lesson lesson;

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final text = TextEditingController();
  NotesController? notes;
  String initialText = '';
  bool leaving = false;
  bool busy = false;
  bool initialized = false;
  String? error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    notes ??= NotesScope.maybeOf(context)!;
    if (!initialized && notes!.ready) {
      initialText = notes!.noteFor(widget.lesson)?.text ?? '';
      text.text = initialText;
      initialized = true;
    }
  }

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  Future<bool> confirm(String title, String message, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                action == 'Descartar' ? 'Seguir editando' : 'Cancelar',
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> leave() async {
    if (busy || leaving) return;
    if (text.text != initialText &&
        !await confirm(
          '¿Descartar los cambios?',
          'Los cambios de esta nota todavía no se han guardado.',
          'Descartar',
        )) {
      return;
    }
    if (!mounted) return;
    setState(() => leaving = true);
    // Allow PopScope to rebuild before completing this explicit navigation.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  Future<void> persist({bool delete = false}) async {
    if (busy || notes!.saving) return;
    if (delete &&
        !await confirm(
          '¿Eliminar esta nota?',
          'No se puede deshacer.',
          'Eliminar',
        )) {
      return;
    }
    if (!mounted) return;
    setState(() {
      busy = true;
      error = null;
    });
    final ok = delete
        ? await notes!.deleteNote(widget.lesson)
        : await notes!.saveNote(widget.lesson, text.text);
    if (!mounted) return;
    if (!ok) {
      setState(() {
        busy = false;
        error =
            notes!.saveError ??
            'No se pudo guardar el cambio. Intenta de nuevo.';
      });
      return;
    }
    initialText = text.text;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(delete ? 'Nota eliminada' : 'Nota guardada')),
    );
    setState(() {
      busy = false;
      leaving = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = notes!;
    final exists = controller.noteFor(widget.lesson) != null;
    return PopScope(
      canPop: leaving,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) leave();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Mi nota')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                widget.lesson.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              if (!controller.ready) ...[
                Text(controller.loadError ?? 'Cargando tus notas…'),
                if (controller.loadError != null)
                  FilledButton(
                    onPressed: () async {
                      await controller.load();
                      if (!mounted || !controller.ready) return;
                      initialText =
                          controller.noteFor(widget.lesson)?.text ?? '';
                      text.text = initialText;
                      initialized = true;
                      setState(() {});
                    },
                    child: const Text('Reintentar'),
                  ),
              ] else ...[
                TextField(
                  controller: text,
                  enabled: !busy,
                  minLines: 6,
                  maxLines: 12,
                  maxLength: NotesController.maxLength,
                  decoration: const InputDecoration(
                    labelText: 'Tu nota',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                if (error != null) Text(error!),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed:
                      busy || controller.saving || text.text.trim().isEmpty
                      ? null
                      : () => persist(),
                  child: Text(busy ? 'Guardando…' : 'Guardar'),
                ),
                if (exists) ...[
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: busy || controller.saving
                        ? null
                        : () => persist(delete: true),
                    child: const Text('Eliminar nota'),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
