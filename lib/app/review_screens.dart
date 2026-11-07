part of 'app.dart';

/// Both entry points use the same scope as the list and its pending counter.
class ReviewEntry extends StatelessWidget {
  const ReviewEntry({
    super.key,
    required this.controller,
    required this.module,
    this.topic,
  });
  final LearningController controller;
  final CourseModule module;
  final Topic? topic;

  Iterable<Question> get scope => topic == null
      ? module.questions
      : topic!.lessons.expand((lesson) => lesson.questions);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: OutlinedButton.icon(
      icon: const Icon(Icons.replay_rounded),
      label: Text(
        'Repasar preguntas (${controller.pendingReview(scope).length})',
      ),
      onPressed: () => openScreen(
        context,
        ReviewListScreen(controller: controller, module: module, topic: topic),
      ),
    ),
  );
}

class ReviewListScreen extends StatelessWidget {
  const ReviewListScreen({
    super.key,
    required this.controller,
    required this.module,
    this.topic,
  });
  final LearningController controller;
  final CourseModule module;
  final Topic? topic;

  @override
  Widget build(BuildContext context) => ScreenFrame(
    title: 'Repasar preguntas',
    controller: controller,
    content: (context) {
      final pending = controller.pendingReview(
        topic == null
            ? module.questions
            : topic!.lessons.expand((lesson) => lesson.questions),
      );
      return [
        caption(
          topic == null ? module.title : '${module.title} / ${topic!.title}',
        ),
        heading('Preguntas por repasar'),
        caption(
          'Repasa a tu ritmo. Tus respuestas originales, avance y puntos se conservan.',
        ),
        if (!controller.ready) ...[
          panel([
            Text(controller.loadError ?? 'Recuperando tu repaso…'),
            if (controller.loadError != null)
              FilledButton(
                onPressed: controller.load,
                child: const Text('Volver a intentar'),
              ),
          ]),
        ] else if (pending.isEmpty) ...[
          panel([
            const Icon(Icons.check_circle_outline, color: forest, size: 44),
            const SizedBox(height: 16),
            heading('No tienes preguntas pendientes'),
            const Text(
              'Aquí aparecerán las preguntas que respondas incorrectamente en este recorrido.',
            ),
          ]),
        ] else ...[
          caption(
            'Tienes ${pending.length} ${pending.length == 1 ? 'pregunta pendiente' : 'preguntas pendientes'}. Practica a tu ritmo.',
          ),
          for (final q in pending)
            panel([
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(q.prompt),
                subtitle: Text(
                  controller.reviewAnswerFor(q) == null
                      ? 'Pendiente de repasar'
                      : 'Puedes volver a intentarlo',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => openScreen(
                  context,
                  ReviewQuestionScreen(controller: controller, question: q),
                ),
              ),
            ]),
        ],
        if (pending.isNotEmpty && controller.ready)
          caption('Al acertar, la pregunta saldrá de esta lista.'),
        TextButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
          label: Text(topic == null ? 'Volver al módulo' : 'Volver al tema'),
        ),
      ];
    },
  );
}

class ReviewQuestionScreen extends StatefulWidget {
  const ReviewQuestionScreen({
    super.key,
    required this.controller,
    required this.question,
  });
  final LearningController controller;
  final Question question;

  @override
  State<ReviewQuestionScreen> createState() => _ReviewQuestionScreenState();
}

class _ReviewQuestionScreenState extends State<ReviewQuestionScreen> {
  int? selected;
  bool checked = false;
  bool busy = false;
  String? error;

  Future<void> check() async {
    if (selected == null || busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    final saved = await widget.controller.reviewAnswer(
      widget.question,
      selected!,
    );
    if (!mounted) return;
    setState(() {
      busy = false;
      checked = saved;
      if (!saved) {
        error = 'No se pudo guardar el repaso. La pregunta sigue pendiente. Intenta comprobar otra vez.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final correct = checked && selected == q.correctIndex;
    return PopScope(
      canPop: !busy,
      child: ScreenFrame(
        title: 'Pregunta de repaso',
        controller: widget.controller,
        content: (context) => [
          caption('REPASO · Sin cambios en tu avance ni puntos'),
          heading(
            widget.controller.lessons
                .firstWhere((lesson) => lesson.questions.contains(q))
                .title,
          ),
          Text(
            q.prompt,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          caption('Selecciona una respuesta'),
          for (var i = 0; i < q.options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: selected == i
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainerLow,
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  disabledForegroundColor: Theme.of(context)
                      .colorScheme
                      .onSurface,
                  padding: const EdgeInsets.all(18),
                  alignment: Alignment.centerLeft,
                ),
                onPressed: busy || checked
                    ? null
                    : () => setState(() {
                        selected = i;
                        error = null;
                      }),
                child: Row(
                  children: [
                    Icon(
                      selected == i
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(q.options[i])),
                  ],
                ),
              ),
            ),
          if (error != null) panel([Text(error!)]),
          if (!checked)
            FilledButton(
              onPressed: selected == null || busy || widget.controller.saving
                  ? null
                  : check,
              child: Text(busy ? 'Guardando repaso…' : 'Comprobar respuesta'),
            ),
          if (checked)
            panel([
              Icon(
                correct ? Icons.check_circle_outline : Icons.refresh,
                color: forest,
                size: 36,
              ),
              const SizedBox(height: 12),
              heading(
                correct
                    ? '¡Pregunta resuelta en el repaso!'
                    : 'Sigue intentándolo',
              ),
              Text(q.explanation),
              const SizedBox(height: 16),
              Text(
                correct
                    ? 'Tu repaso quedó guardado. Esta pregunta ya no está pendiente.'
                    : 'La pregunta sigue pendiente. Puedes volver a intentarlo.',
              ),
              if (!correct)
                FilledButton(
                  onPressed: () => setState(() {
                    selected = null;
                    checked = false;
                  }),
                  child: const Text('Volver a intentar'),
                ),
            ]),
          TextButton(
            onPressed: busy ? null : () => Navigator.of(context).pop(),
            child: Text(correct ? 'Continuar repaso' : 'Volver a la lista'),
          ),
        ],
      ),
    );
  }
}
