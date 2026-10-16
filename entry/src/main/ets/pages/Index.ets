import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Theme } from '../common/Theme';
import { NoteEditView } from './NoteEditView';
import { NoteListView } from './NoteListView';
import { SelfCheckView } from './SelfCheckView';

@Entry
@Component
struct Index {
  @State private tab: number = 0;
  @State private noteId: string = '';
  @State private pageShowSeq: number = 0;
  @State private leaveSeq: number = 0;
  @State private pendingTab: number = 0;
  private tabs: string[] = ['列表', '编辑', '版本信息'];

  onPageShow(): void {
    this.pageShowSeq++;
  }

  onBackPress(): boolean {
    if (this.tab !== 1) {
      return false;
    }
    this.pendingTab = -1;
    this.leaveSeq++;
    return true;
  }

  build() {
    Column() {
      Column() {
        if (this.tab === 0) {
          NoteListView({
            pageShowSeq: this.pageShowSeq,
            onOpen: (id: string): void => {
              this.openNote(id);
            },
            onCreate: (): void => {
              this.openNote('');
            }
          })
        } else if (this.tab === 1) {
          NoteEditView({
            noteId: this.noteId,
            leaveSeq: this.leaveSeq,
            pendingTab: this.pendingTab,
            onDone: (): void => {
              this.finishEdit();
            },
            onLeave: (next: number): void => {
              this.leaveTo(next);
            }
          })
        } else {
          SelfCheckView({ pageShowSeq: this.pageShowSeq })
        }
      }
      .layoutWeight(1)
      .width('100%')

      Row() {
        ForEach(this.tabs, (name: string, index: number) => {
          Text(name)
            .fontSize(15)
            .fontWeight(this.tab === index ? FontWeight.Medium : FontWeight.Regular)
            .fontColor(this.tab === index ? Theme.ink : Theme.text)
            .textAlign(TextAlign.Center)
            .layoutWeight(1)
            .height(Theme.hitHeight)
            .borderRadius(10)
            .backgroundColor(this.tab === index ? Theme.gold : Theme.cardAlt)
            .onClick(() => {
              this.pickTab(index);
            })
        }, (name: string) => name)
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 8, bottom: 12 })
      .backgroundColor(Theme.navy)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.page)
  }

  private openNote(id: string): void {
    this.noteId = id;
    this.tab = 1;
  }

  private pickTab(index: number): void {
    if (this.tab === 1 && index !== 1) {
      this.pendingTab = index;
      this.leaveSeq++;
      return;
    }
    if (index === 0) {
      this.finishEdit();
      return;
    }
    this.tab = index;
  }

  private leaveTo(next: number): void {
    if (next < 0) {
      this.exitAbility();
      return;
    }
    if (next === 0) {
      this.finishEdit();
      return;
    }
    this.tab = next;
  }

  private exitAbility(): void {
    let host = this.getUIContext().getHostContext();
    if (host === undefined) {
      return;
    }
    let ctx = host as common.UIAbilityContext;
    ctx.terminateSelf().catch((err: Object) => {
      hilog.error(0x4C4E, 'Index', 'exit %{public}s', JSON.stringify(err));
    });
  }

  private finishEdit(): void {
    this.noteId = '';
    this.tab = 0;
  }
}
