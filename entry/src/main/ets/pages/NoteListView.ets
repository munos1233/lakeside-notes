import { common } from '@kit.AbilityKit';
import fs from '@ohos.file.fs';
import installer from '@ohos.bundle.installer';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Theme } from '../common/Theme';
import { CardFrame } from '../components/UiParts';
import { Note } from '../model/NoteTypes';
import { NoteQuery } from '../model/NoteQuery';
import { NoteStore } from '../model/NoteStore';

const DOMAIN: number = 0x4C4E;
const CONTEXT_RETRY_LIMIT: number = 20;
const CONTEXT_RETRY_MS: number = 50;
const CONTEXT_RETRY_SLOW_MS: number = 500;
const NEW_BUTTON_HEIGHT: number = 46;
const NEW_BUTTON_MARGIN: number = 16;
const LIST_BOTTOM_GAP: number = NEW_BUTTON_HEIGHT + NEW_BUTTON_MARGIN + 16;
const UPDATE_HAP: string = 'lakeside-notes-doppel.hap';
const UPDATE_USER: number = 100;
const PHASE_LOADING: string = 'loading';
const PHASE_READY: string = 'ready';
const PHASE_FAILED: string = 'failed';

@Component
export struct NoteListView {
  @State private loaded: Note[] = [];
  @State private visible: Note[] = [];
  @State private keyword: string = '';
  @State private phase: string = PHASE_LOADING;
  @Prop @Watch('onPageShow') pageShowSeq: number = 0;
  private contextTries: number = 0;
  private retryId: number = -1;
  private loadTicket: number = 0;
  private alive: boolean = true;
  private clearWaiting: boolean = false;
  onOpen: (id: string) => void = (id: string): void => {
    hilog.info(DOMAIN, 'list', '%{public}d', id.length);
  };
  onCreate: () => void = (): void => {
  };

  aboutToAppear(): void {
    this.alive = true;
    this.contextTries = 0;
    this.reload();
  }

  aboutToDisappear(): void {
    this.alive = false;
    this.loadTicket++;
    this.cancelRetry();
  }

  onPageShow(): void {
    this.contextTries = 0;
    this.reload();
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        Row() {
          Text($r('app.string.app_name'))
            .fontSize(22)
            .fontWeight(FontWeight.Medium)
            .fontColor(Theme.text)
            .layoutWeight(1)
          Text('检查更新')
            .fontSize(14)
            .fontColor(Theme.gold)
            .margin({ right: 12 })
            .onClick(() => {
              this.askUpdate();
            })
          Text(this.resultCount())
            .fontSize(16)
            .fontColor(Theme.gold)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        Text('清空重来')
          .fontSize(14)
          .fontColor(Theme.gold)
          .margin({ top: 8 })
          .onClick(() => {
            this.askClear();
          })

        TextInput({ text: this.keyword, placeholder: '搜索' })
          .width('100%')
          .height(44)
          .margin({ top: 12 })
          .fontSize(16)
          .fontColor(Theme.text)
          .placeholderColor(Theme.muted)
          .backgroundColor(Theme.card)
          .borderRadius(10)
          .padding({ left: 12, right: 12 })
          .onChange((value: string) => {
            this.keyword = value;
            if (this.phase === PHASE_READY) {
              this.publish();
            }
          })

        if (this.phase === PHASE_FAILED) {
          this.emptyLine('没读上来')
        } else if (this.phase === PHASE_READY && this.loaded.length === 0) {
          this.emptyLine('还没有笔记')
        } else if (this.phase === PHASE_READY && this.visible.length === 0) {
          this.emptyLine('没有匹配的笔记')
        } else if (this.visible.length > 0) {
          List({ space: 0 }) {
            ForEach(this.visible, (item: Note) => {
              ListItem() {
                Column() {
                  CardFrame() {
                    Column() {
                      Row() {
                        Text(item.title)
                          .fontSize(18)
                          .fontColor(Theme.text)
                          .layoutWeight(1)
                        if (item.pinned) {
                          Text('置顶')
                            .fontSize(12)
                            .fontColor(Theme.ink)
                            .backgroundColor(Theme.gold)
                            .borderRadius(8)
                            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                        }
                      }
                      .width('100%')
                      .alignItems(VerticalAlign.Center)

                      Text(item.updatedAt)
                        .width('100%')
                        .fontSize(12)
                        .fontColor(Theme.muted)
                        .margin({ top: 6 })

                      Text(NoteQuery.summary(item.body))
                        .width('100%')
                        .fontSize(14)
                        .fontColor(Theme.muted)
                        .margin({ top: 4 })
                    }
                    .width('100%')
                    .alignItems(HorizontalAlign.Start)
                  }
                }
                .width('100%')
                .onClick(() => {
                  this.onOpen(item.id);
                })
              }
            }, (item: Note) => item.id + item.updatedAt + (item.pinned ? '1' : '0'))
          }
          .layoutWeight(1)
          .width('100%')
          .margin({ top: 12 })
          .padding({ bottom: LIST_BOTTOM_GAP })
        }
      }
      .width('100%')
      .height('100%')
      .padding({ left: 16, right: 16, top: 16 })
      .alignItems(HorizontalAlign.Start)

      Button('新建')
        .type(ButtonType.Normal)
        .height(NEW_BUTTON_HEIGHT)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(Theme.ink)
        .backgroundColor(Theme.gold)
        .borderRadius(12)
        .margin({ right: NEW_BUTTON_MARGIN, bottom: NEW_BUTTON_MARGIN })
        .onClick(() => {
          this.onCreate();
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.page)
  }

  @Builder
  emptyLine(message: string) {
    Text(message)
      .width('100%')
      .fontSize(16)
      .fontColor(Theme.muted)
      .textAlign(TextAlign.Center)
      .margin({ top: 48 })
  }

  private resultCount(): string {
    if (this.phase !== PHASE_READY) {
      return '—';
    }
    if (this.keyword.trim().length === 0) {
      return NoteStore.count(this.loaded).toString();
    }
    return this.visible.length.toString();
  }

  private publish(): void {
    this.visible = NoteQuery.sort(NoteQuery.search(this.loaded, this.keyword));
  }

  private askUpdate(): void {
    this.getUIContext().getPromptAction().showDialog({
      title: '发现新版本',
      message: '笔记 1.0.1',
      buttons: [
        { text: '取消', color: Theme.muted },
        { text: '立即更新', color: Theme.gold }
      ]
    }).then((result) => {
      if (!this.alive || result.index !== 1) {
        return;
      }
      this.startUpdate();
    }).catch((err: Object) => {
      hilog.error(DOMAIN, 'list', 'update dialog %{public}s', JSON.stringify(err));
    });
  }

  private startUpdate(): void {
    let host = this.getUIContext().getHostContext();
    if (host === undefined) {
      this.tell('无法更新');
      return;
    }
    let ctx = host as common.UIAbilityContext;
    this.copyUpdate(ctx).then((path: string): Promise<void> => {
      return installer.getBundleInstaller().then((tool: installer.BundleInstaller): Promise<void> => {
        return tool.install([path], { userId: UPDATE_USER, installFlag: 1 });
      });
    }).catch((err: Object) => {
      hilog.error(DOMAIN, 'list', 'update %{public}s', JSON.stringify(err));
      if (!this.alive) {
        return;
      }
      this.tell(updateError(err));
    });
  }

  private copyUpdate(ctx: common.UIAbilityContext): Promise<string> {
    let path = ctx.cacheDir + '/lakeside-update.hap';
    return ctx.resourceManager.getRawFileContent(UPDATE_HAP).then((raw: Uint8Array): string => {
      let buffer = new ArrayBuffer(raw.byteLength);
      let view = new Uint8Array(buffer);
      for (let i = 0; i < raw.byteLength; i++) {
        view[i] = raw[i];
      }
      let file = fs.openSync(path, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC);
      try {
        fs.writeSync(file.fd, buffer);
      } catch (err) {
        fs.closeSync(file);
        throw new Error('更新包无法写入');
      }
      fs.closeSync(file);
      return path;
    });
  }

  private tell(message: string): void {
    this.getUIContext().getPromptAction().showDialog({
      title: '更新失败',
      message: message,
      buttons: [
        { text: '知道了', color: Theme.gold }
      ]
    }).catch((err: Object) => {
      hilog.error(DOMAIN, 'list', 'fail dialog %{public}s', JSON.stringify(err));
    });
  }

  private askClear(): void {
    this.getUIContext().getPromptAction().showDialog({
      message: '清空全部笔记？',
      buttons: [
        { text: '取消', color: Theme.muted },
        { text: '清空', color: Theme.danger }
      ]
    }).then((result) => {
      if (!this.alive || result.index !== 1) {
        return;
      }
      this.clearWaiting = true;
      this.performClear();
    }).catch((err: Object) => {
      hilog.error(DOMAIN, 'list', 'dialog %{public}s', JSON.stringify(err));
    });
  }

  private performClear(): void {
    if (!this.alive || !this.clearWaiting) {
      return;
    }
    let host = this.getUIContext().getHostContext();
    if (host === undefined) {
      this.scheduleRetry();
      return;
    }
    this.cancelRetry();
    this.contextTries = 0;
    let ctx = host as common.UIAbilityContext;
    let ticket = ++this.loadTicket;
    NoteStore.clear(ctx).then((cleared: boolean) => {
      if (!this.alive || ticket !== this.loadTicket) {
        return;
      }
      this.clearWaiting = false;
      if (!cleared) {
        this.reload();
        return;
      }
      this.loaded = [];
      this.keyword = '';
      this.phase = PHASE_READY;
      this.publish();
    }).catch((err: Object) => {
      if (!this.alive || ticket !== this.loadTicket) {
        return;
      }
      hilog.error(DOMAIN, 'list', 'clear %{public}s', JSON.stringify(err));
      this.clearWaiting = false;
      this.reload();
    });
  }

  private reload(): void {
    if (!this.alive) {
      return;
    }
    if (this.clearWaiting) {
      this.performClear();
      return;
    }
    let host = this.getUIContext().getHostContext();
    if (host === undefined) {
      this.scheduleRetry();
      return;
    }
    this.cancelRetry();
    this.contextTries = 0;
    let ctx = host as common.UIAbilityContext;
    let ticket = ++this.loadTicket;
    NoteStore.load(ctx).then((loaded: Note[]) => {
      if (!this.alive || ticket !== this.loadTicket) {
        return;
      }
      this.loaded = loaded;
      this.phase = PHASE_READY;
      this.publish();
    }).catch((err: Object) => {
      if (!this.alive || ticket !== this.loadTicket) {
        return;
      }
      hilog.error(DOMAIN, 'list', 'load %{public}s', JSON.stringify(err));
      this.phase = PHASE_FAILED;
      this.visible = [];
    });
  }

  private scheduleRetry(): void {
    if (!this.alive) {
      return;
    }
    this.contextTries++;
    if (this.contextTries === CONTEXT_RETRY_LIMIT) {
      this.phase = PHASE_FAILED;
      this.visible = [];
    }
    let delay = CONTEXT_RETRY_SLOW_MS;
    if (this.contextTries < CONTEXT_RETRY_LIMIT) {
      delay = CONTEXT_RETRY_MS;
    }
    this.cancelRetry();
    this.retryId = setTimeout(() => {
      this.retryId = -1;
      this.reload();
    }, delay);
  }

  private cancelRetry(): void {
    if (this.retryId < 0) {
      return;
    }
    clearTimeout(this.retryId);
    this.retryId = -1;
  }
}

class UpdateError {
  code: number = 0;
  message: string = '';
}

function updateError(err: Object): string {
  if (err instanceof Error && err.message.length > 0) {
    return err.message;
  }
  let boxed: UpdateError = err as UpdateError;
  if (typeof boxed.message === 'string' && boxed.message.length > 0) {
    return boxed.message;
  }
  if (typeof boxed.code === 'number' && boxed.code !== 0) {
    return '更新失败 ' + boxed.code.toString();
  }
  return '更新失败';
}
