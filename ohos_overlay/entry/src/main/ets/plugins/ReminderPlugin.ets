// Preparación de integración: NO compilado con Flutter-OH ni con el SDK OHOS.
// Verificar al generar el proyecto: exports del embedding, FlutterPluginBinding,
// MethodCall.argument<T>, MethodResult y firmas de MethodChannel.invokeMethod.
import {
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult
} from '@ohos/flutter_ohos';
import { common, Want } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { reminderAgentManager } from '@kit.BackgroundTasksKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { notificationManager } from '@kit.NotificationKit';

// API 13+ prevista: WantAgent.parameters existe desde API 12 y los ajustes desde 13.
// Referencias y límites de evidencia: docs/platforms/HARMONYOS_NEXT.md.
export default class ReminderPlugin implements FlutterPlugin, MethodCallHandler {
  private channel?: MethodChannel;
  private store?: preferences.Preferences;
  private dartReady: boolean = false;
  private pendingOpenings: number = 0;
  // Serializa operaciones incluso si llegan llamadas simultáneas del canal.
  private operations: Promise<void> = Promise.resolve();

  constructor(private context: common.UIAbilityContext) {}

  // Verificar al generar el proyecto: firmas exactas del embedding Flutter-OH.
  getUniqueClassName(): string {
    return 'PspsReminderPlugin';
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), 'mx.edu.uaz.psps/reminders');
    this.channel.setMethodCallHandler(this);
  }

  onDetachedFromEngine(_binding: FlutterPluginBinding): void {
    this.channel?.setMethodCallHandler(null);
    this.channel = undefined;
    this.dartReady = false;
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    this.operations = this.operations.then(async (): Promise<void> => {
      try {
        await this.handle(call, result);
      } catch (error) {
        const nativeError = error as BusinessError;
        // MethodResult.error se convierte en PlatformException en Dart.
        result.error(String(nativeError.code ?? 'OHOS_REMINDER_ERROR'),
          nativeError.message ?? 'No se pudo completar el recordatorio', null);
      }
    });
  }

  private async getStore(): Promise<preferences.Preferences> {
    if (this.store === undefined) {
      this.store = await preferences.getPreferences(this.context, { name: 'psps_ohos_reminders' });
    }
    return this.store;
  }

  private integerArgument(call: MethodCall, name: string, min: number, max: number): number {
    const value = call.argument<number>(name);
    if (typeof value !== 'number' || !Number.isInteger(value) || value < min || value > max) {
      throw new Error('Argumento inválido: ' + name);
    }
    return value;
  }

  private stringArgument(call: MethodCall, name: string): string {
    const value = call.argument<string>(name);
    if (typeof value !== 'string') {
      throw new Error('Argumento inválido: ' + name);
    }
    return value;
  }

  private async handle(call: MethodCall, result: MethodResult): Promise<void> {
    switch (call.method) {
      case 'initialize':
        await this.getStore();
        this.dartReady = true;
        result.success(null);
        this.deliverOpenings();
        return;
      case 'hasPermission':
        result.success(await notificationManager.isNotificationEnabled());
        return;
      case 'requestPermission':
        // Invocar desde la interfaz cargada, no desde onCreate.
        try {
          await notificationManager.requestEnableNotification(this.context);
        } catch (error) {
          if ((error as BusinessError).code !== 1600004) {
            throw error;
          }
          // Denegación documentada; consultar de nuevo el estado real.
        }
        result.success(await notificationManager.isNotificationEnabled());
        return;
      case 'scheduleDay': {
        const day = this.integerArgument(call, 'weekday', 1, 7);
        const hour = this.integerArgument(call, 'hour', 0, 23);
        const minute = this.integerArgument(call, 'minute', 0, 59);
        const title = this.stringArgument(call, 'title');
        const body = this.stringArgument(call, 'body');
        await this.scheduleDay(day, hour, minute, title, body);
        result.success(null);
        return;
      }
      case 'cancelDay':
        await this.cancelDay(this.integerArgument(call, 'weekday', 1, 7));
        result.success(null);
        return;
      case 'openNotificationSettings':
        if (!canIUse('SystemCapability.Notification.NotificationSettings')) {
          result.success(false);
          return;
        }
        await notificationManager.openNotificationSettings(this.context);
        result.success(true);
        return;
      default:
        result.notImplemented();
    }
  }

  private async cancelPublished(id: number): Promise<void> {
    try {
      await reminderAgentManager.cancelReminder(id);
    } catch (error) {
      // Un ID ya eliminado equivale a cancelación exitosa; los demás fallos
      // se propagan y conservan el mapa para permitir reintentar.
      if ((error as BusinessError).code !== 1700003) {
        throw error;
      }
    }
  }

  private async cancelDay(day: number): Promise<void> {
    const store = await this.getStore();
    const key = 'day.' + day;
    const id = await store.get(key, -1) as number;
    if (id < 0) {
      return;
    }
    await this.cancelPublished(id);
    await store.delete(key);
    await store.flush();
  }

  private async scheduleDay(day: number, hour: number, minute: number,
    title: string, body: string): Promise<void> {
    const store = await this.getStore();
    // Reemplazo semanal por día: cancelar y persistir la retirada antes de publicar.
    await this.cancelDay(day);
    const request: reminderAgentManager.ReminderRequestAlarm = {
      reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_ALARM,
      hour: hour,
      minute: minute,
      daysOfWeek: [day], // lunes=1 ... domingo=7; repetición semanal.
      title: title,
      content: body,
      notificationId: 1200 + day,
      wantAgent: {
        pkgName: this.context.abilityInfo.bundleName,
        abilityName: this.context.abilityInfo.name,
        parameters: { 'psps.reminder.opened': true }
      }
    };
    // El WantAgent anterior es reminderAgentManager.WantAgent, no el de otro kit.
    const id = await reminderAgentManager.publishReminder(request);
    try {
      await store.put('day.' + day, id);
      await store.flush();
    } catch (error) {
      // Compensación si falla la persistencia del nuevo ID. Si también falla la
      // cancelación, se propaga el fallo y se requiere reconciliación en dispositivo.
      await this.cancelPublished(id);
      await store.delete('day.' + day);
      await store.flush();
      throw error;
    }
  }

  onWant(want: Want): void {
    if (want.parameters?.['psps.reminder.opened'] === true) {
      this.pendingOpenings++;
      this.deliverOpenings();
    }
  }

  onForeground(): void {
    this.deliverOpenings();
  }

  private deliverOpenings(): void {
    if (!this.dartReady || this.channel === undefined) {
      return;
    }
    while (this.pendingOpenings > 0) {
      this.channel.invokeMethod('opened', null);
      this.pendingOpenings--;
    }
  }
}
