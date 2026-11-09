// FRAGMENTO para fusionar, no reemplazar EntryAbility.ets generado.
// NO compilado. Verificar al generar el proyecto: FlutterAbility, FlutterEngine,
// configureFlutterEngine, plugins.add y firmas exactas del ciclo de vida.
import { AbilityConstant, Want } from '@kit.AbilityKit';
import { FlutterAbility, FlutterEngine } from '@ohos/flutter_ohos';
import ReminderPlugin from '../plugins/ReminderPlugin';

export default class EntryAbility extends FlutterAbility {
  private reminders?: ReminderPlugin;
  private pendingReminderWant?: Want;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // Retener ANTES de super: el motor puede configurarse dentro de super.
    this.pendingReminderWant = want;
    super.onCreate(want, launchParam);
    this.forwardReminderWant();
  }

  configureFlutterEngine(flutterEngine: FlutterEngine): void {
    // Conservar el registro generado, incluido shared_preferences OHOS.
    super.configureFlutterEngine(flutterEngine);
    this.reminders = new ReminderPlugin(this.context);
    flutterEngine.getPlugins().add(this.reminders);
    this.forwardReminderWant();
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    super.onNewWant(want, launchParam);
    this.pendingReminderWant = want;
    this.forwardReminderWant();
  }

  onForeground(): void {
    super.onForeground();
    // No volver a consumir this.want: duplicaría opened en cada reanudación.
    this.reminders?.onForeground();
  }

  private forwardReminderWant(): void {
    if (this.reminders !== undefined && this.pendingReminderWant !== undefined) {
      this.reminders.onWant(this.pendingReminderWant);
      this.pendingReminderWant = undefined;
    }
  }
}
