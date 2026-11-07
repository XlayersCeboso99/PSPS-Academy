part of 'app.dart';

class FeatureLinks extends StatelessWidget {
  const FeatureLinks({super.key, required this.controller});
  final LearningController controller;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.extension_outlined),
          label: const Text('Actividades'),
          onPressed: () =>
              openScreen(context, ActivitiesScreen(controller: controller)),
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.stars_outlined),
          label: const Text('Puntos'),
          onPressed: () =>
              openScreen(context, PointsScreen(controller: controller)),
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.emoji_events_outlined),
          label: const Text('Logros'),
          onPressed: () =>
              openScreen(context, AchievementsScreen(controller: controller)),
        ),
      ],
    ),
  );
}

List<Widget> unavailableState(LearningController controller) => [
  panel([
    const Icon(Icons.error_outline, size: 36),
    const SizedBox(height: 12),
    Text(controller.loadError ?? 'Recuperando tus datos…'),
    if (controller.loadError != null)
      FilledButton(
        onPressed: controller.load,
        child: const Text('Reintentar carga'),
      ),
  ]),
];

class PointsScreen extends StatelessWidget {
  const PointsScreen({super.key, required this.controller});
  final LearningController controller;
  @override
  Widget build(BuildContext context) => ScreenFrame(
    title: 'Puntos',
    controller: controller,
    content: (context) => !controller.ready
        ? unavailableState(controller)
        : [
            caption('TOTAL DE PUNTOS'),
            panel([
              Icon(
                Icons.stars_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Semantics(
                key: const ValueKey('cu10.total'),
                container: true,
                label: 'Total de puntos acumulados',
                value: '${controller.points} puntos',
                excludeSemantics: true,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${controller.points} pts',
                    style: const TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Tus puntos se guardan en este dispositivo.'),
            ]),
            caption(
              'Cada actividad elegible completada y guardada por primera vez otorga ${Gamification.pointsPerPractice} puntos. Repetirla no suma puntos.',
            ),
            caption(
              'Los puntos son recompensas de gamificación, no una calificación académica.',
            ),
            caption(
              'Consultar esta pantalla no modifica puntos, progreso, actividades ni logros.',
            ),
          ],
  );
}

class ActivitiesScreen extends StatelessWidget {
  const ActivitiesScreen({super.key, required this.controller});
  final LearningController controller;
  @override
  Widget build(BuildContext context) {
    if (!controller.ready || controller.practices.isEmpty) {
      return ScreenFrame(
        title: 'Actividades',
        controller: controller,
        content: (_) => !controller.ready
            ? unavailableState(controller)
            : [
                for (final module in controller.modules)
                  for (final topic in module.topics) ...[
                    Text(topic.title),
                    const Text('Este tema no tiene actividades disponibles'),
                  ],
                const Text('No hay actividades disponibles.'),
              ],
      );
    }
    final activities = [
      for (final module in controller.modules)
        for (final topic in module.topics)
          if (topic.practice.steps.isNotEmpty)
            ActivityDefinition(
              id: topic.practice.id,
              title: topic.practice.title,
              moduleId: module.id,
              moduleName: module.title,
              topicId: topic.id,
              topicName: topic.title,
              requiredElementIds: {
                for (var i = 0; i < topic.practice.steps.length; i++) '$i',
              },
            ),
    ];
    return Cu08ActivitiesPage(
      catalog: activities,
      engine: ActivityEngine(
        activities: activities,
        store: LearningActivityStore(controller),
      ),
      onOpenActivity: (activity) async {
        final topic = controller.modules
            .expand((m) => m.topics)
            .firstWhere((t) => t.practice.id == activity.id);
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) =>
                PracticeScreen(controller: controller, topic: topic),
          ),
        );
      },
    );
  }
}

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key, required this.controller});
  final LearningController controller;
  @override
  Widget build(BuildContext context) => ScreenFrame(
    title: 'Logros',
    controller: controller,
    content: (context) {
      if (!controller.ready) return unavailableState(controller);
      final earned = Gamification.achievements
          .where((a) => controller.earnedAchievements.containsKey(a.id))
          .toList();
      return [
        heading('Cada paso deja huella'),
        caption(
          '${earned.length} de ${Gamification.achievements.length} logros obtenidos',
        ),
        if (earned.isEmpty)
          panel(key: const ValueKey('cu06.empty'), [
            const Icon(Icons.emoji_events_outlined, size: 44),
            const SizedBox(height: 12),
            // A1 de CU-06.
            heading('Aún no tienes logros'),
            const Text('Realiza actividades y completa temas para obtenerlos.'),
          ]),
        for (final a in earned)
          panel(key: ValueKey('cu06.achievement.${a.id}'), [
            Row(
              children: [
                Icon(
                  Icons.emoji_events_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    a.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Condición cumplida: ${a.condition}'),
            const SizedBox(height: 8),
            caption(_date(controller.earnedAchievements[a.id])),
          ]),
        if (earned.length < Gamification.achievements.length)
          ExpansionTile(
            title: const Text('Próximos logros'),
            children: [
              for (final a in Gamification.achievements)
                if (!controller.earnedAchievements.containsKey(a.id))
                  ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: Text(a.name),
                    subtitle: Text(a.condition),
                  ),
            ],
          ),
        const SizedBox(height: 24),
        heading('Dale tu estilo'),
        caption(
          'Los temas de color personalizan la app. Todos los contenidos están disponibles desde el inicio.',
        ),
        for (final t in Gamification.themes) _themeTile(context, t),
      ];
    },
  );

  String _date(String? raw) {
    if (raw == null) return 'Fecha no disponible';
    final d = DateTime.parse(raw).toLocal();
    return 'Obtenido el ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Widget _themeTile(BuildContext context, VisualTheme visual) {
    final available = controller.unlockedThemes.contains(visual.id);
    final selected = controller.selectedTheme == visual.id;
    final colors = academyTheme(visual.id).colorScheme;
    return panel(key: ValueKey('cu06.theme.${visual.id}'), [
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          child: Icon(
            selected
                ? Icons.check
                : available
                ? Icons.palette_outlined
                : Icons.lock_outline,
          ),
        ),
        title: Text(visual.name),
        subtitle: Text(
          selected
              ? 'En uso'
              : available
              ? 'Disponible'
              : 'Bloqueado',
        ),
      ),
      Text(visual.condition),
      if (available && !selected) ...[
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: controller.saving
              ? null
              : () => reportSave(context, controller.selectTheme(visual.id)),
          child: Text('Usar ${visual.name}'),
        ),
      ],
    ]);
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.controller});
  final LearningController controller;
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final input = TextEditingController();
  String query = '';
  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScreenFrame(
    title: 'Buscar contenidos',
    controller: widget.controller,
    content: (context) {
      final results = ContentSearch(widget.controller.modules).search(query);
      return [
        TextField(
          controller: input,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Buscar por palabra clave',
            labelText: 'Buscar contenidos',
            prefixIcon: const Icon(Icons.search),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
            suffixIcon: IconButton(
              tooltip: 'Limpiar búsqueda',
              icon: const Icon(Icons.close),
              onPressed: () {
                input.clear();
                setState(() => query = '');
              },
            ),
          ),
          onChanged: (value) => setState(() => query = value),
        ),
        const SizedBox(height: 20),
        if (widget.controller.modules.isEmpty) ...[
          // E1 de CU-09.
          panel(key: const ValueKey('cu09.error'), [
            const Text('No pudimos recuperar el catálogo local.'),
            TextButton(
              onPressed: () => setState(() {}),
              child: const Text('Reintentar'),
            ),
          ]),
        ] else if (!ContentSearch.canSearch(query)) ...[
          // A2 de CU-09.
          heading('Escribe al menos ${ContentSearch.minLength} letras'),
          panel(key: const ValueKey('cu09.short'), [
            const Icon(Icons.offline_bolt_outlined),
            const SizedBox(height: 12),
            const Text(
              'Busca en módulos, temas y subtemas, incluyendo su contenido y ejemplos. Funciona sin conexión.',
            ),
          ]),
        ] else if (results.isEmpty) ...[
          // A1 de CU-09.
          panel(key: const ValueKey('cu09.empty'), [
            const Icon(Icons.search_off, size: 48),
            const SizedBox(height: 16),
            heading('No se encontraron temas con «${query.trim()}»'),
            const Text(
              'Revisa cómo escribiste la palabra o explora los módulos para encontrar lo que buscas.',
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.grid_view),
              label: const Text('Explorar módulos'),
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
            ),
          ]),
        ] else ...[
          caption(
            '${results.length} ${results.length == 1 ? 'resultado' : 'resultados'} para «${query.trim()}»',
          ),
          for (final group in MatchField.values) ...[
            if (results.any((r) => r.field == group))
              caption(
                group == MatchField.title ? 'EN TÍTULOS' : 'EN EL CONTENIDO',
              ),
            for (final result in results.where((r) => r.field == group))
              panel(key: ValueKey('cu09.result.${result.lesson.id}'), [
                InkWell(
                  onTap: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    openScreen(
                      context,
                      LessonScreen(
                        controller: widget.controller,
                        module: result.module,
                        topic: result.topic,
                        lesson: result.lesson,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.lesson.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('${result.module.title} › ${result.topic.title}'),
                        const SizedBox(height: 12),
                        _snippet(context, result),
                        const SizedBox(height: 12),
                        StatusBadge(
                          widget.controller.lessonStatus(result.lesson),
                        ),
                        const SizedBox(height: 8),
                        const Row(
                          children: [
                            Flexible(child: Text('Abrir subtema')),
                            Icon(Icons.chevron_right),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
          ],
        ],
      ];
    },
  );

  Widget _snippet(BuildContext context, SearchResult r) => Text.rich(
    TextSpan(
      children: [
        TextSpan(text: r.snippet.substring(0, r.matchStart)),
        TextSpan(
          text: r.snippet.substring(r.matchStart, r.matchStart + r.matchLength),
          style: TextStyle(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w800,
          ),
        ),
        TextSpan(text: r.snippet.substring(r.matchStart + r.matchLength)),
      ],
    ),
  );
}
